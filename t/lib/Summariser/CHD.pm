package Summariser::CHD;

use CH::Perl;
use Moose;
use Mojo::URL;
use Data::Dumper::Concise;
extends 'Summariser';

#-------------------------------------------------------------------------------------------

sub _build_url {
    my ( $self ) = @_;

    my $url = Mojo::URL->new( 'http://chd3.companieshouse.gov.uk/' ); # TODO move to config file
    # my $url = Mojo::URL->new( 'http://chdpreprod.orctel.internal/' ); # TODO move to config file
    my $tx = $self->_ua->max_redirects(3)->post( $url => form => {password => ''});
    if ( $tx->success ) {
        $url = $tx->req->url;
    }
    else {
        my $err = $tx->error;
        die 'Failed to login to CHD - ' . ( $err->{code} ? $err->{code} . ' response: ' : 'Connection error: ' ) . $err->{message};
    }

    return $url;
}

#-------------------------------------------------------------------------------

sub summary {
    my ( $self, $company_number, $delay, ) = @_;

    my $summary = $self->initial_summary;

    my $url = $self->_url->path( 'companysearch' );
    my $form = {
        cnumb => $company_number,
        live => 'on',
        dissolved => 'on',
        stype => 'A',
        cosearch => 'OK',
    };

    if ( defined $delay ) { # non-blocking
        my $end = $delay->begin(0);
        $self->_ua->post( $url => form => $form => sub {
            my ( $ua, $tx ) = @_;
            $self->_summarise_company( $company_number, $summary, $tx, $end, );
            # $self->_summarise_company( $company_number, $summary, $tx, undef, );
            # $end->( $summary );
        } );
    }
    else { # blocking
        my $tx = $self->_ua->post(
            $url => form => $form
        );
        $self->_summarise_company( $company_number, $summary, $tx, undef, );
    }

    return $summary;
}

#-------------------------------------------------------------------------------------------

# _process_XXX() = post/get + _summarise()

#-------------------------------------------------------------------------------------------
sub _process_company_profile {
    my ( $self, $company_number, $summary, $end, ) = @_;

    my $url = $self->_url->path( 'compmenu' );

    if ( defined $end ) { # non-blocking
        $self->_ua->get( $url => sub {
            my ( $ua, $tx ) = @_;
            $self->_summarise_company_profile( $company_number, $summary, $tx, $end, );
        } );
    }
    else { # blocking
        my $tx = $self->_ua->get( $url );
        $self->_summarise_company_profile( $company_number, $summary, $tx, undef, );
    }
}

#-------------------------------------------------------------------------------------------

sub _fh_form {
    my ( $self, $fields ) = @_;
    $fields //= [];
    return {
        ( map { $_->attr('name') ? ( $_->attr('name') => $_->attr('value') ) : () } @$fields ),
        morebut => 1,
    };
}

#-------------------------------------------------------------------------------------------

sub _process_filing_history {
    my ( $self, $company_number, $summary, $end, $hidden, ) = @_;

    my $url = $self->_url->path( 'fhist' );
    if ( defined $end ) { # non-blocking
        $self->_ua->post( $url => form => $self->_fh_form( $hidden ) => sub {
            my ( $ua, $tx ) = @_;
            $self->_summarise_filing_history( $company_number, $summary, $tx, $end, );
        } );
    }
    else { # blocking
        my $tx = $self->_ua->post( $url => form => $self->_fh_form( $hidden ) );
        $self->_summarise_filing_history( $company_number, $summary, $tx, undef, );
    }
}

#-------------------------------------------------------------------------------------------

sub _process_officers {
    my ( $self, $company_number, $summary, $end, ) = @_;

    my $url = $self->_url->path( 'appointments' );
    if ( defined $end ) { # non-blocking
        $self->_ua->post( $url => form => { incexc => 1, } => sub {
            my ( $ua, $tx ) = @_;
            $self->_summarise_officers( $company_number, $summary, $tx, $end, );
        } );
    }
    else { # blocking
        my $tx = $self->_ua->post( $url => form => { incexc => 1, } );
        $self->_summarise_officers( $company_number, $summary, $tx, undef, );
    }
}

#-------------------------------------------------------------------------------------------

sub _summarise_company_selection {
    my ( $self, $company_number, $summary, $res_selection ) = @_;

    my @selection_text_span = map { defined $_ ? $_->text : '' } @{ $res_selection->res->dom('span[class="text"]') };
    @$summary{qw(company_number company_name sel_type sel_message)} = @selection_text_span;
    $summary->{incorporation_date} = '';
    my $warning = 'Company details for the selected company have been archived from the service';
    # Not strictly an error but these companies will (should) not be passed to CHS
    for ( map { defined $_ && $_->text eq $warning ? $_->text : () } @{ $res_selection->res->dom('td[class="text"]') } ) {
        $summary->{error} = $_;
        last;
    }

}

#-------------------------------------------------------------------------------------------

sub _summarise_company {
    my ( $self, $company_number, $summary, $tx_company_search, $end, ) = @_;

    if ( $tx_company_search->success ) { # POST succeeded but search may not have been successful

        # if the company menu is present there was a single match and the company was displayed
        # if the company search results frame is present there were two matches and links were displayed ( eg dissolved and recently dissolved )

        if ( @{ $tx_company_search->success->dom('frame[src="compmenu"]') } ||
             @{ $tx_company_search->success->dom('frame[src^="companysearch"]') }
        ) {
            $self->_process_company_profile( $company_number, $summary, $end, );
        }
        else {
          $summary->{error} = join( ': ',
              'Company menu not available in CHD for company ' . $company_number,
              map { defined $_ ? $_->text : '' } @{ $tx_company_search->success->dom('table > tr > td > table > tr > td > span[class="error"]') },
          );
          # say $summary->{error};
        }
    }
    else {
      my $err = $tx_company_search->error;
      $summary->{error} = 'Failed to find company in CHD - ' . ( $err->{code} ? $err->{code} . ' response: ' : 'Connection error: ' ) . $err->{message};
      # say $summary->{error};
    }
}

#-------------------------------------------------------------------------------------------

sub _summarise_company_profile {
    my ( $self, $company_number, $summary, $menu_selection_tx, $end, ) = @_;

    my %side_menu_enabled;
    @side_menu_enabled{qw(company_details filing_history appointments)} =
        map { $_->{class} eq 'sidemenu' }
        @{ $menu_selection_tx->res->dom('td[class="sidemenubg"] > a, span') }[0,1,6];
    $summary->{available} = \%side_menu_enabled;

    if ( $side_menu_enabled{company_details} ) {
        my $url = $self->_url->path( 'compdetails' );
        if ( defined $end ) {
            $self->_ua->get( $url => sub {
                my ( $ua, $tx ) = @_;
                $self->_summarise_company_details( $company_number, $summary, $tx, $end, );
                $self->_process_filing_history( $company_number, $summary, $end, );
            } );
        }
        else {
            my $tx = $self->_ua->get( $url );
            $self->_summarise_company_details( $company_number, $summary, $tx, undef, );
            $self->_process_filing_history( $company_number, $summary, undef, );
        }
    } else {
        my $url = $self->_url->path( 'cosel' );
        if ( defined $end ) {
            $self->_ua->get( $url => sub {
                my ( $ua, $tx ) = @_;
                $self->_summarise_company_selection( $company_number, $summary, $tx, $end, );
                $self->_process_filing_history( $company_number, $summary, $end, );
            } );
        }
        else {
            my $tx = $self->_ua->get( $url );
            $self->_summarise_company_selection( $company_number, $summary, $tx, undef, );
            $self->_process_filing_history( $company_number, $summary, undef, );
        }
    }
}

#-------------------------------------------------------------------------------------------

sub _summarise_company_details {
    my ( $self, $company_number, $summary, $res_profile ) = @_;

    if ( $company_number =~ /^RC/ ) { # Royal Charter
        @$summary{qw(company_number company_name status)} =
            map { defined $_ ? $_->text : '' } @{ $res_profile->res->dom('table > tr > td > table > tr > td[class="sbtext"]') };
        ( $summary->{status} ) = $summary->{status} =~ /^(.*?) Company Incorporated by Royal Charter/;
    }
    else {
        my @text_span = @{ $res_profile->res->dom('table > tr > td > table > tr > td > span[class="text"]') };
        @$summary{qw(company_name registered_office_address incorporation_date country_of_origin)} =
            map { defined $_ ? $_->text : '' } @text_span[0..3];
        $summary->{registered_office_address} =~ s{(?:c/o|PO Box) }{}g;
        $summary->{incorporation_date} =~ s/(\d+)\/(\d+)\/(\d+)/$3-$2-$1/;

        @text_span = map { defined $_ ? $_->text : '' } @{ $res_profile->res->dom('body > table > tr > td > span[class="text"],span[class="scud"]') };
        @$summary{qw(company_number status type)} = splice @text_span,0,3;
        my $last_sic_index = 0; $last_sic_index++ while $text_span[$last_sic_index] =~ /^(?:\d+ - |None Supplied|\d+$)/;
        $summary->{sic} = [ splice @text_span, 0, $last_sic_index ];
        @$summary{qw(last_accounts_to next_accounts_due last_return_to next_return_to)} = map { m|(\d+)/(\d+)/(\d+)| ? "$3-$2-$1" : $_ } @text_span[1,3,4,5];
        @$summary{qw(accounting_reference_date accounts_type charges)} = @text_span[0,2,6];
    }
    if ( $summary->{status} =~ m|^(Dissolved)\s(\d{2})/(\d{2})/(\d{4})$| ) {
        $summary->{status} = $1;
        $summary->{dissolution_date} = "$4-$3-$2";
    }
    $summary->{status} = status_map( $summary->{status} );
}

#-------------------------------------------------------------------------------------------

sub _summarise_filing_history {
    my ( $self, $company_number, $summary, $tx_filing_history, $end, ) = @_;

    # map types in CHD to those in CHS
    my $type_map = {
        'LATEST SOC' => 'SH01',
    };

    if ( $tx_filing_history->success ) {
        my $hidden = $tx_filing_history->success->dom('input[type="hidden"]');
        my $more_pages = @{ $tx_filing_history->success->dom('input[name="morebut"]') };
        my $tr_list = $tx_filing_history->success->dom('table > tr > td > table > tr[class^="resultrow"]');
        RESULT_ROW:
        for my $tr ( @$tr_list ) {
            my ( $type_td, $date_td ) = @{$tr->children('td')}[2,3];
            my $level= $type_td->text ? 'top_level' : 'subdoc';
            my $type = $type_td->text||$type_td->i->text;
            my $date = $date_td->span->text||$date_td->span->i->text;
            $type = $type_map->{$type} if exists $type_map->{$type};
            my $year_month_day = $date =~ m|(?<day>\d{2})/(?<month>\d{2})/(?<year>\d{4})| ?
                $+{year} . $+{month} . $+{day} : '00000000';
            $self->increment_summary( $summary, $level, $type, $year_month_day );
        }
        if ( $more_pages ) {
            $self->_process_filing_history( $company_number, $summary, $end, $hidden, );
        }
        else {
            $self->_process_officers( $company_number, $summary, $end, );
            # $end->() if defined $end;
        }
    }
    else {
      my $err = $tx_filing_history->error;
      $summary->{error} = 'Failed to find filing history in CHD - ' . ( $err->{code} ? $err->{code} . ' response: ' : 'Connection error: ' ) . $err->{message};
    }

}

#-------------------------------------------------------------------------------------------

sub _summarise_officers {
    my ( $self, $company_number, $summary, $tx_officer_listing, $end, ) = @_;

    if ( $tx_officer_listing->success ) {
        my $more_pages = @{ $tx_officer_listing->success->dom('a[href="appointments?morebut=1"]') };
        my $tr_list = $tx_officer_listing->success->dom->find('table[width="100%"] > tr:first-of-type');
        for my $tr ( splice( @$tr_list, 3 ) ) {
            my ( $name_td, $type_td ) = @{$tr->children('td')}[0,2];
            if ( $name_td->{width} eq '60%' ) {
                 my $name = $name_td->a->text;
                 my $type = $type_td->span->text =~ /(MEM|SEC|DIR)/ ? $1 : 'OFF';
                 my $appointment_td = $tr->next->children('td')->[2];
                 my $appointment_date = $appointment_td->span->[1]->text;
                 $appointment_date =~ s/.*?(\d+)\/(\d+)\/(\d+).*/$3-$2-$1/;
                 $summary->{officer_total}++;
                 $summary->{officers}->{$name.':'.$type.':'.$appointment_date}++;
            }
        }
        if ( $more_pages ) {
            $self->_process_officers( $company_number, $summary, $end, );
        }
        else {
            $end->( $summary ) if defined $end;
        }
    }
    else {
      my $err = $tx_officer_listing->error;
      $summary->{error} = 'Failed to find officer listing in CHD - ' . ( $err->{code} ? $err->{code} . ' response: ' : 'Connection error: ' ) . $err->{message};
      # say $summary->{error};
    }

}

#-------------------------------------------------------------------------------------------

sub status_map {
    my ( $status ) = @_;

    my $status_map = {
        'Active'  => "active",
        'Dissolved'  => "dissolved",
        'Liquidation'  => "liquidation",
        'Receivership'  => "receivership",
        'Converted / Closed'  => "converted-closed",
        'TRANSFERRED FROM UK'  => "transferred-from-gb",
        'Live  (proposed transfer from GB)'  => "live-propopsed-transfer-from-gb",
        'RECEIVERSHIP'  => "receivership",
        'VOLUNTARY ARRANGEMENT'  => "voluntary-arrangement",
        'VOLUNTARY ARRANGEMENT / RECEIVERSHIP'  => "voluntary-arrangement-receivership",
        'ADMINISTRATION ORDER'  => "administration-order",
        'ADMINISTRATION ORDER / RECEIVERSHIP'  => "administration-order-or-receivership",
        'Live but Receiver Manager on at least one charge'  => "live-receiver-manager-on-at-least-one-charge",
        'ADMINISTRATIVE RECEIVER'  => "administrative-receiver",
        'RECEIVER MANAGER / ADMINISTRATIVE RECEIVER'  => "receiver-manager-or-administrative-receiver",
        'Voluntary Arrangement'  => "voluntary-arrangement",
        'VOLUNTARY ARRANGEMENT / RECEIVER MANAGER'  => "voluntary-arrangement-or-receiver-manager",
        'VOLUNTARY ARRANGEMENT / ADMINISTRATIVE RECEIVER'  => "voluntary-arrangement-or-administrative-receiver",
        'VOLUNTARY ARRANGEMENT / ADMINISTRATIVE RECEIVER / RECEIVER MANAGER'  => "voluntary-arrangement-or-administrative-receiver-or-receiver-manager",
        'ADMINISTRATION ORDER'  => "administration-order",
        'ADMINISTRATION ORDER / RECEIVER MANAGER'  => "administration-order-or-receiver-manager",
        'ADMINISTRATION ORDER / ADMINISTRATIVE RECEIVER'  => "administration-order-or-administrative-receiver",
        'ADMINISTRATION ORDER / RECEIVER MANAGER'  => "administration-order-or-receiver-manager",
        'Active - Proposal to Strike off'  => "active-proposal-to-strike-off",
        'Petition to Restore - Dissolved'  => "petition-to-restore-dissolved",
        'In Administration/Receivership'  => "in-administration-or-receivership",
        'In Administration'  => "in-administration",
        'In Administration/Receiver Manager'  => "in-administration-or-receiver-manager",
        'In Administration/Administrative Receiver'  => "in-administration-or-administrative-receiver",
        'In Administration/Receiver Manager/Administrative Receiver'  => "in-administration-or-receiver-manager-or-administrative-receiver",
        'Transformed to SE'  => "transformed-to-se",
        'Live (Proposed conversion to SE)'  => "live-proposed-conversion-to-se",
        'Converted to PLC'  => "converted-to-plc",
    };

    return $status_map->{$status} // $status // 'Unknown';
}

#-------------------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;
