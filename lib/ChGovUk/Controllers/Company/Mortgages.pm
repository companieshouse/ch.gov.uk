package ChGovUk::Controllers::Company::Mortgages;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::IOLoop;
use Mojo::IOLoop::Delay;

use CH::Perl;
use CH::Util::DateHelper;
use POSIX qw/ceil/;
use Readonly;
use CH::Util::Pager;
use ChGovUk::Plugins::FilterHelper;

Readonly my $PARTICULARS_SHORT_STRING_LENGTH => 60;
Readonly my $LARGE_HEADING_MAX_LENGTH        => 140;
Readonly my $BREADCRUMB_SHORT_STRING_LENGTH  => 55;
Readonly my @ALTERATIONS_FILING_TYPES = qw( alter-charge alter-charge-limited-liability-partnership alter-floating-charge alter-floating-charge-limited-liability-partnership );

# all filters (that can be used)
# XXX temp: need decision on what categories we're going to display and where the
# canonical list should be (e.g. in here, hardwired in the template, in a YAML file,
# pulled from MongoDB &c.)
use constant AVAILABLE_FILTERS => {
    'outstanding' => 'Outstanding / part satisfied'
};

#-------------------------------------------------------------------------------

# Company mortgages page
sub view {
    my ($self) = @_;

    if (!$self->config->{feature}->{mortgage} && !$self->can_do('/admin/mortgages')) {
        warn "mortgage index feature is not available to non admin users" [MORTGAGES];
        $self->render('error', error => "page_unavailable", description => "You have requested a page that is currently unavailable.", status => 500 );

        return ;
    }

    # Process the incoming parameters
    my $company_number = $self->param('company_number');
    my $filter_val     = $self->get_filter('cha');                # List of filter to use (optional)
    my @filter_array = split ',', $filter_val;

    # Generate an arrayref containing hashrefs of fiter id's/name's, sorted by name
    my $filters = [
        sort { $a->{name} cmp $b->{name} }
        (map { {
            id   => $_,
            name => AVAILABLE_FILTERS->{$_},
        } } keys(%{AVAILABLE_FILTERS()}))
    ];

    my $selected_filter_count = 0;

    # Iterate through filters setting checked flag and keeping a count of number checked
    for my $filter (@$filters) {
        if (scalar(grep { $filter->{id} eq $_ } @filter_array)) {
            $filter->{checked} = 1;
            $selected_filter_count++;
        }
    }

    my $query = {};

    # encode the selected filters as a comma-separated list and add it as a parameter to the
    # mortgage query
    if ($selected_filter_count) {
        $query->{filter} = join(',', map { $_->{id} } grep($_->{checked}, @$filters));
    }

    my $page = abs(int($self->param('page') || 1));     # Which page has been requested
    my $items_per_page = $self->config->{mortgages}->{items_per_page} || 25;

    my $pager = CH::Util::Pager->new(entries_per_page => $items_per_page, current_page => $page);

    my $first = $pager->first;   # Get first mortgage for this page
    debug "Call mortgage api for company %s, start_index %s, items_per_page %s, filter=[%s]", $self->stash('company_number'),
        $first, $pager->entries_per_page, $filter_val [MORTGAGES];

    $query->{start_index} = $first;
    $query->{items_per_page} = $pager->entries_per_page;

    # Get the mortgage data for the company from the API
    $self->ch_api->company($self->stash('company_number'))->charges($query)->get->on(
        success => sub {
            my ( $api, $tx ) = @_;
            my $results = $tx->success->json;
            trace "mortgages for %s: %s", $self->stash('company_number'), d:$results [MORTGAGES];

            # Calculate the outstanding mortgage count
            $results->{outstanding_count} = $results->{unfiltered_count} - $results->{satisfied_count} - $results->{part_satisfied_count};

            for my $charge (@{$results->{items}}) {
                # Format date fields in the form of '01 Jan 2004'
                $self->_dates_to_strings( $charge );

                for my $transaction (@{$charge->{transactions}}) {
                   $self->_dates_to_strings( $transaction );
                }

                $self->format_charge_code( $charge );

                # get the heading to use for the mortgage particulars
                $charge->{particulars_label} = $self->get_particulars_label( $charge );

                if (defined $charge->{particulars_label}) {
                    # create particulars string to display in index, shortened to max length if required
                    my ($particulars_string, $trimmed) = $self->get_particulars_short_string( $charge );
                    if ($particulars_string) {
                        $charge->{particulars_string} = $particulars_string;
                        $charge->{particulars_string_trimmed} = $trimmed;
                    }
                }
            }

            $self->stash(filters              => $filters);
            $self->stash(selected_filter_count => $selected_filter_count);
            $self->stash(split_filter_at       => ceil(@$filters / 2));
            # Work out the paging numbers
            $pager->total_entries( $results->{total_count} // 0 );

            trace "mortgage total_count %d entries per page %d",
                $pager->total_entries, $pager->entries_per_page() [MORTGAGE];

            $self->stash(current_page_number     => $pager->current_page);
            $self->stash(page_set                => $pager->pages_in_set());
            $self->stash(next_page               => $pager->next_page());
            $self->stash(previous_page           => $pager->previous_page());
            $self->stash(entries_per_page        => $pager->entries_per_page());

            $self->stash(mortgages => $results);
            $self->stash(company_number => $company_number);

            if ($self->req->is_xhr) {
                return $self->render(template => 'company/mortgages/view_content');
            }
            else {
                return $self->render;
            }
        },
        failure => sub {
            my ( $api, $tx ) = @_;

            my ($error_code, $error_message) = (
                $tx->error->{code} // 0,
                $tx->error->{message},
            );

            if ($error_code == 404) {
                trace "Charges not found for company [%s]", $company_number [MORTGAGES];
                $self->stash(no_mortgages_found => 1);
                $self->stash(filters => $filters);

                if (!$selected_filter_count) {
                    return $self->render_not_found;
                } elsif ($self->req->is_xhr) {
                    return $self->render(template => 'company/mortgages/view_content');
                }
                else {
                    return $self->render;
                }
            }

            error "Failed to retrieve charges for %s: %s", $company_number, $error_message;
            return $self->render_exception("Failed to retrieve charges for company [$company_number]: $error_message");
        },
        error => sub {
            my ($api, $error) = @_;

            error "Error retrieving charges list for %s: %s", $company_number, $error;
            return $self->render_exception("Error retrieving company charges: $error");
        }
      )->execute;

    $self->render_later;
}

#--------------------------------------------------------------

# Company mortgage page
sub view_details {
    my ($self) = @_;

    if (!$self->config->{feature}->{mortgage} && !$self->can_do('/admin/mortgages')) {
        warn "mortgage details feature is not available to non admin users" [MORTGAGE_DETAILS];
        $self->render('error', error => "page_unavailable", description => "You have requested a page that is currently unavailable.", status => 500 );
        return ;
    }

    # Process the incoming parameters
    my $company_number = $self->param('company_number');
    my $charge_id = $self->param('charge_id');

    my $filing_delay = Mojo::IOLoop::Delay->new;
    my $result;

    # Get the insolvency data for the company from the API
    $self->ch_api->company($self->stash('company_number'))->charge_details($charge_id)->get->on(
        success => sub {
            my ( $api, $tx ) = @_;
            $result = $tx->success->json;
            trace "mortgage for %s with mortgage id %s: %s", $self->stash('company_number'), $charge_id, d:$result [MORTGAGE_DETAILS];

            # shift earliest transaction as the creation transaction
            $result->{creation_transaction} = shift @{ $result->{transactions} };

            # reverse remaining transactions (after taking the creation transaction out)
            my @reversed = reverse @{ $result->{transactions} };
            $result->{transactions} = \@reversed;

            # get the heading to use for the mortgage particulars
            $result->{particulars_label} = $self->get_particulars_label( $result );

            # Format date fields in the form of '01 Jan 2004'
            $self->_dates_to_strings( $result );

            for my $transaction (@{$result->{transactions}}) {
               $self->_dates_to_strings( $transaction );
               $result->{show_insolvency_column} = 1 if defined $transaction->{links}->{insolvency_case} && !defined $result->{show_insolvency_column};
            }

            # filter to show only historical insolvency cases (i.e. cases with no transaction id) underneath additional filings table
            $result->{insolvency_cases} = [ grep { !defined $_->{transaction_id} } @{$result->{insolvency_cases}} ];

            $self->format_charge_code( $result );

            if (!defined $result->{charge_code}) {
                my ($breadcrumb, $breadcrumb_trimmed) = $self->get_breadcrumb_short_string($result);
                $result->{breadcrumb} = $breadcrumb;
                $result->{breadcrumb_trimmed} = $breadcrumb_trimmed;

                if (length($result->{classification}->{description}) > $LARGE_HEADING_MAX_LENGTH) {
                    $result->{use_medium_heading} = 1;
                }
            }

            $result->{show_alterations_statement} = $self->should_show_alterations_statement( $result );

            $self->_get_image_location($result->{creation_transaction}, $filing_delay->begin(0) );

            # Do not merge with the loop above because it will break the delays and return garbage to
            for my $transaction (@{$result->{transactions}}) {
               if ( defined $transaction->{links}->{filing}) {
                   my $additional_transaction_delay_end = $filing_delay->begin(0);
                   $self->_get_image_location($transaction, $additional_transaction_delay_end);
               }
            }

       },
        failure => sub {
            my ( $api, $error ) = @_;

            my ($error_code, $error_message) = (
                $error->error->{code} // 0,
                $error->error->{message},
            );

            if ($error_code == 404) {
                trace "Mortgage [%s] not found for company [%s]", $charge_id, $company_number [MORTGAGE_DETAILS];
                return $self->render_not_found;
            }

            error "Error retrieving company mortgages for %s: %s",
            $self->stash('company_number'), $error [MORTGAGE_DETAILS];
            $self->render_exception("Error retrieving company: $error");
        }
      )->execute;
    $self->render_later;

    $filing_delay->on(
                 finish => sub {
                     my ($delay, $response) = @_;
                     trace "Mortgage document after transformation: %s", d:$result [MORTGAGE_DETAILS];

                     $self->stash(charge => $result );
                     $self->stash(company_number => $self->param('company_number'));
                     $self->stash(charge_id => $self->param('charge_id'));
                     $self->render;

                     },
                 error => sub {
                     my ($delay, $err) = @_;
                     error "Error getting mortgage details : %s", $err [ MORTGAGE_DETAILS ];
                     return $self->render_exception($err);
                 },
             );

}

#-------------------------------------------------------------------------------

sub _get_image_location {
     my ( $self, $mortgage_data, $callback ) = @_;

     if (defined $mortgage_data->{links}->{filing}) {

        my @parts = split( /\//, $mortgage_data->{links}->{filing} ); # FIXME Temporarily continue to use transaction_id until we can use the whole filing-history url
        $mortgage_data->{transaction_id} = $parts[4]; # splits into 4 parts because of the leading slash

        $self->ch_api->company($self->param('company_number'))->filing_history_item($mortgage_data->{transaction_id})->get->on(
               success => sub {
                   my ( $api, $tx ) = @_;
                   my $filing_doc = $tx->success->json;

                   if (defined $filing_doc->{links}->{document_metadata}) {
                       trace "Successfully returned image location";
                       $mortgage_data->{resource_url}   = $filing_doc->{links}->{document_metadata};
                       $mortgage_data->{pages} = $filing_doc->{pages};
                   } else {
                       trace "Resource does not have an image associated with transaction_id: %s", $mortgage_data->{transaction_id};
                   }

                   return $callback->($mortgage_data);
             },
               failure => sub {
                   my ( $api, $error ) = @_;

                   error "Error retrieving company filing for %s: %s", $self->stash('company_number'), $error;
                   return $callback->($mortgage_data);
               },
             )->execute;

    } else {
        return $callback->($mortgage_data);
    }
}
#-------------------------------------------------------------------------------

sub _dates_to_strings {
    my ( $self, $description_values, ) = @_;

    for my $field ( grep { /^created_on$/ | /^delivered_on$/ | /^acquired_on$/ | /^resolved_on$/ | /^covering_instrument_date$/ | /^satisfied_on$/ | /^registered_on$/ } keys %{ $description_values // {} } ) {
        $description_values->{$field} = CH::Util::DateHelper->isodate_as_string( $description_values->{$field}, "%e %B %Y" );
    }
}

#-------------------------------------------------------------------------------

# returns an array of the form ($short_string, $show_trimmed) or nothing if the mortgage has no particulars
sub get_particulars_short_string {
    my ( $self, $mortgage ) = @_;

    if (defined $mortgage->{particulars}) {
        my ($short_string, $show_trimmed);
        if (defined $mortgage->{particulars}->{description}) {
            $short_string = $mortgage->{particulars}->{description};
        }

        # loop through the flags stripped from particulars (in CHIPS) and if the short string is not yet defined use the first true flag.
        # if the short string is already defined but another flag is true make sure we treat the string as trimmed
        for my $flag (qw(contains_fixed_charge contains_floating_charge floating_charge_covers_all contains_negative_pledge chargor_acting_as_bare_trustee)) {
            if ($mortgage->{particulars}->{$flag}) {
                if (defined $short_string) {
                    $show_trimmed = 1;
                    last;
                } else {
                    $short_string = $self->md_lookup('particular-flags', $flag).'.';
                }
            }
        }

        if (defined $short_string) {
            if (length($short_string) > $PARTICULARS_SHORT_STRING_LENGTH) {
                # cut to max length. ellipsis '...' will  be added in template with '&hellip;'
                $short_string = substr( $short_string, 0, $PARTICULARS_SHORT_STRING_LENGTH );

                # find last space (and optionally preceding comma or full stop) and remove so the ellipsis can be added at the end of a word
                $short_string =~ s/[.,]?\s+\S*\z//g;

                # set show_trimmed so the ellipsis will be shown in the template
                $show_trimmed = 1;
            } elsif ($show_trimmed == 1) {
                # if the string does not exceed the char limit but we want to show trimmed anyway we need to ensure we remove the last full stop
                $short_string =~ s/[.]?\z//g;
            }
        }

        return ($short_string, $show_trimmed);
    }

    return ;
}

#-------------------------------------------------------------------------------

sub get_particulars_label {
    my ( $self, $mortgage ) = @_;

    if (defined $mortgage->{particulars} and defined $mortgage->{particulars}->{type}) {
        return $self->md_lookup('particular-description', $mortgage->{particulars}->{type});
    }

    if ($mortgage->{particulars}->{contains_fixed_charge} or $mortgage->{particulars}->{contains_floating_charge} or $mortgage->{particulars}->{floating_charge_covers_all} or $mortgage->{particulars}->{contains_negative_pledge} or $mortgage->{particulars}->{chargor_acting_as_bare_trustee}) {
        return $self->md_lookup('particular-description', 'brief-description');
    }

    return ;
}
#-------------------------------------------------------------------------------

sub format_charge_code {
    my ( $self, $mortgage ) = @_;

    if (defined $mortgage->{charge_code}) {
        # strip any spaces out, we will add them in the correct place below
        $mortgage->{charge_code} =~ s/\s//g;

        # split into space separated blocks of 4 i.e. CHAR GECO DE01
        $mortgage->{charge_code} = join ' ', ($mortgage->{charge_code} =~ m/.{1,4}/g);
    }
}

#-------------------------------------------------------------------------------

sub should_show_alterations_statement {
    my ( $self, $mortgage ) = @_;

    if (defined $mortgage->{scottish_alterations} and ($mortgage->{scottish_alterations}->{has_alterations_to_prohibitions} or $mortgage->{scottish_alterations}->{has_alterations_to_order})) {
        my $alterations_transaction_found = 0;

        if (defined $mortgage->{transactions}) {
            for my $filing (@{$mortgage->{transactions}}) {
                if ($filing->{filing_type} ~~ @ALTERATIONS_FILING_TYPES) {
                    $alterations_transaction_found = 1;
                    last;
                }
            }
        }

        # if an alterations transaction is found we do not show the alterations statement
        return !$alterations_transaction_found;
    }

    return 0;
}

#-------------------------------------------------------------------------------

# returns an array of the form ($short_string, $show_trimmed)
sub get_breadcrumb_short_string {
    my ( $self, $mortgage ) = @_;

    my $short_string = $mortgage->{classification}->{description};

    my $show_trimmed;
    if (length($short_string) > $BREADCRUMB_SHORT_STRING_LENGTH) {
        # cut to max length. ellipsis '...' will  be added in template with '&hellip;'
        $short_string = substr( $short_string, 0, $BREADCRUMB_SHORT_STRING_LENGTH );

        # find last space (and optionally preceding comma or full stop) and remove so the ellipsis can be added at the end of a word
        $short_string =~ s/[.,]?\s+\S*\z//g;

        # set show_trimmed so the ellipsis will be shown in the template
        $show_trimmed = 1;
    }

    return ($short_string, $show_trimmed);
}

# ----------------------------------------------------------------------------

1;
