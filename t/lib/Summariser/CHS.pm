package Summariser::CHS;

use CH::Perl;
use CH::Test;
use DateTime;
use Mojo::URL;
use Moose;

extends 'Summariser';

#-------------------------------------------------------------------------------------------

# has '_url'            => ( is => 'rw', isa => 'Mojo::URL', lazy => 1, builder => '_build_url', );

#-------------------------------------------------------------------------------------------

sub _build_url {
    my ( $self ) = @_;

    my $url = Mojo::URL->new( $ENV{API_LOCAL_URL} )->path( 'company/' )->query( key => $ENV{CHS_API_KEY} );
    return $url;
}

#-------------------------------------------------------------------------------------------

sub summary {
    my ( $self, $company_number, $delay, ) = @_;

    my $summary = $self->initial_summary;

    # $delay = undef;
    if ( 0 && defined $delay ) {
        $self->_process_company_profile( $company_number, $summary, $delay, );
        $self->_process_filing_history( $company_number, $summary, defined $delay ? $delay->begin(0) : undef, );
        $self->_process_officers( $company_number, $summary, defined $delay ? $delay->begin(0) : undef, );
    }
    else {
        $self->_process_company_profile( $company_number, $summary, undef, );
        $self->_process_filing_history( $company_number, $summary, undef, );
        $self->_process_officers( $company_number, $summary, undef, );
        $delay->pass( $summary );
    }


    return $summary;
}

#-------------------------------------------------------------------------------------------

sub _process_company_profile {
    my ( $self, $company_number, $summary, $delay, ) = @_;

    my $profile_url = $self->_url->clone->path( $company_number );
    if ( defined $delay ) { # non-blocking
        my $end = $delay->begin(0);
        $self->_ua->get( $profile_url => sub {
            my ( $ua, $tx ) = @_;
            $self->_summarise_company_profile( $company_number, $summary, $tx, $delay, );
            $end->();
        } );
    }
    else { # blocking
        my $tx = $self->_ua->get( $profile_url );
        $self->_summarise_company_profile( $company_number, $summary, $tx, $delay, );
    }
}

#-------------------------------------------------------------------------------------------

sub _process_filing_history {
    my ( $self, $company_number, $summary, $end, $start_index, $items_per_page, $total_count, ) = @_;

    $start_index //= 0;
    $items_per_page //= 100;
    my $filing_history_url = $self->_url->clone->path( $company_number . '/filing-history' );
    $filing_history_url->query( [ start_index => $start_index, items_per_page => $items_per_page, ] );

    if ( defined $end ) { # non-blocking
        $self->_ua->get( $filing_history_url => sub {
            my ( $ua, $tx ) = @_;
            $self->_summarise_filing_history( $company_number, $summary, $tx, $end, $start_index, $items_per_page, $total_count, );
        } );
    }
    else { # blocking
        my $tx = $self->_ua->get( $filing_history_url );
        $self->_summarise_filing_history( $company_number, $summary, $tx, undef, $start_index, $items_per_page, $total_count, );
    }
}

#-------------------------------------------------------------------------------------------

sub _process_officers {
    my ( $self, $company_number, $summary, $end, $start_index, $items_per_page, $total_count, ) = @_;

    $start_index //= 0;
    $items_per_page //= 100;
    my $officer_listing_url = $self->_url->clone->path( $company_number . '/officers' );
    $officer_listing_url->query( [ start_index => $start_index, items_per_page => $items_per_page, ] );

    if ( defined $end ) { # non-blocking
        $self->_ua->get( $officer_listing_url => sub {
            my ( $ua, $tx ) = @_;
            $self->_summarise_officers( $company_number, $summary, $tx, $end, $start_index, $items_per_page, $total_count, );
        } );
    }
    else { # blocking
        my $tx = $self->_ua->get( $officer_listing_url );
        $self->_summarise_officers( $company_number, $summary, $tx, undef, $start_index, $items_per_page, $total_count, );
    }
}

#-------------------------------------------------------------------------------------------

sub _summarise_company_profile {
    my ( $self, $company_number, $summary, $tx, ) = @_;

    my $profile_json = $tx->res->json();
    if ( defined $profile_json ) {
        $summary->{company_name} = $profile_json->{data}->{company_name};
        $summary->{company_number} = $profile_json->{data}->{company_number};
        $summary->{status} = $profile_json->{data}->{status};
        $summary->{registered_office_address} =
            uc( join( ' ', map { $_//() } @{$profile_json->{data}->{registered_office_address}}{qw(care_of_name po_box address_line_1 address_line_2 locality region country postal_code)} ) );
        $summary->{registered_office_address} =~ s{(?:\s{2,})}{ }g;
        $summary->{incorporation_date} =
            $profile_json->{data}->{date_of_creation} ?
            substr( date_from_epoch( $profile_json->{data}->{date_of_creation} ), 0, 10 ) :
            'Unknown';
        $summary->{cessation_date} =
            $profile_json->{data}->{date_of_cessation} ?
            substr( date_from_epoch( $profile_json->{data}->{date_of_cessation} ), 0, 10 ) :
            '';
        $summary->{accounting_reference_date} = join '/', grep { $_ } @{ $profile_json->{data}->{accounts}->{accounting_reference_date} }{qw(day month)};
        @$summary{qw(last_accounts_to next_accounts_due last_return_to next_return_to)} =
            map { $_ ? substr( date_from_epoch( $_ ), 0, 10 ) : '' }
            (
                $profile_json->{data}->{accounts}->{last_accounts}->{made_up_to},
                $profile_json->{data}->{accounts}->{next_due},
                $profile_json->{data}->{annual_return}->{last_made_up_to},
                $profile_json->{data}->{annual_return}->{next_due},
            );
    }

}

#-------------------------------------------------------------------------------------------

sub _summarise_filing_history {
    my ( $self, $company_number, $summary, $tx, $end, $start_index, $items_per_page, $total_count, ) = @_;

    my $json = $tx->res->json();
    if ( defined $json ) {
        $total_count ||= $json->{total_count};
        for my $document ( @{ $json->{items} } ) {
            my $type = $document->{type} || 'unknown';
            my $date = $document->{date} || '0000-00-00';
            $date =~ s/-//g;
            if ( $type ne 'RESOLUTIONS' ) { # ignore virtual top level document
                $self->increment_summary( $summary, 'top_level', $type, $date );
            }
            for my $subdocument ( @{ $document->{associated_filings} }, @{ $document->{resolutions} }, @{ $document->{annotations} } ) {
                my $subdoctype = $subdocument->{type} || 'unknown';
                my $subdocdate = $document->{date} || '0000-00-00';
                $subdocdate =~ s/-//g;
                $self->increment_summary( $summary, 'subdoc', $subdoctype, $subdocdate );
            }
        }
        $start_index += $items_per_page;
        if ( $start_index < $total_count ) {
            $self->_process_filing_history( $company_number, $summary, $end, $start_index, $items_per_page, $total_count, );
        }
        else {
            $end->() if defined $end;
        }

    }
    else {
        say "CHS API not available for $company_number filing history tests";
        $end->() if defined $end;
    }
}

#-------------------------------------------------------------------------------------------

sub _summarise_officers {
    my ( $self, $company_number, $summary, $tx, $end, $start_index, $items_per_page, $total_count, ) = @_;

    my $json = $tx->res->json();
    if ( defined $json ) {
        for my $officer ( @{ $json->{officers} } ) {
            my $type = $officer->{kind} =~ /(MEM|SEC|DIR)/ ? $1 : 'OFF';
            my $name = uc join( ', ', $officer->{surname}, join( ' ', grep { $_ } @{$officer}{qw(forename otherforename title)} )||() );
            my $appointment_date = $officer->{appointment_date};
            $name =~ s/\s+$//g;
            $name =~ s/\s{2,}/ /g;
            $summary->{officer_total}++;
            $summary->{officers}->{$name.':'.$type.':'.$appointment_date}++;
        }
        $total_count ||= $json->{total_officers}->{count}//0;
        $start_index += $items_per_page;
        if ( $start_index < $total_count ) {
            $self->_process_officers( $company_number, $summary, $end, $start_index, $items_per_page, $total_count, );
        }
        else {
            $end->() if defined $end;
        }
    }
    else {
        say "CHS API not available for $company_number officer listing tests";
        $end->() if defined $end;
    }

}

#-------------------------------------------------------------------------------------------

sub date_from_epoch {
    my ( $epoch ) = @_;

    return DateTime->from_epoch( epoch => $epoch / 1000 )->iso8601()
}

#-------------------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;
