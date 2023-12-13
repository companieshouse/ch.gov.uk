package ChGovUk::Controllers::Company::Pscs;

use Mojo::Base 'Mojolicious::Controller';

use CH::Perl;
use CH::Util::Pager;
use CH::Util::DateHelper;
use Mojo::IOLoop::Delay;

#-------------------------------------------------------------------------------

# List consisting of PSCs and PSC statements
sub list {
    my ($self) = @_;

    if ($self->config->{feature}->{psc} != 1) {
        warn "PSCs feature flat not set" [PSCs];
        $self->render('error', error => "page_unavailable", description => "You have requested a page that is currently unavailable.", status => 500 );

        return;
    }

    $self->render_later;

    # Process the incoming parameters
    my $company_number   = $self->param('company_number');     # Mandatory
    my $page             = abs int($self->param('page') || 1); # Which page as been requested

    my $items_per_page = 35;

    trace "Get company psc list for %s, page %s", $company_number, $page [PSC LIST];
    my $pager = CH::Util::Pager->new(entries_per_page => $items_per_page, current_page => $page);

    my $first_psc_number = $pager->first;

    trace "Call psc list api for company %s, items_per_page %s", $company_number, $items_per_page [PSC LIST];


    # As we are making 2 API calls - 1 for pscs 1 for statements, a delay is needed to make sure both of them have time to come back with API response
    my $psc_delay = Mojo::IOLoop::Delay->new;

    my $psc_delay_end = $psc_delay->begin(0); # psc listing delay
   
   #---- PSC LIST ------- 
    
    # Get the psc list for the company from the API
    $self->ch_api->company($company_number)->pscs({
        start_index    => abs int $first_psc_number,
        items_per_page => $pager->entries_per_page,
    })->get->on(
        success => sub {
            my ($api, $tx) = @_;

            my $results = $tx->success->json;

            # Decide if full DOB should be displayed
            for my $item (@{ $results->{items} }) {
                if ($item->{date_of_birth}) {
                    my $month = sprintf("%02s", $item->{date_of_birth}->{month});
                    my $year = $item->{date_of_birth}->{year};
                    if ($item->{date_of_birth}->{day}) {
                        my $day = sprintf("%02s", $item->{date_of_birth}->{day});
                        my $date = $year."-".$month."-".$day;
                        $item->{date_of_birth} = $date;
                        $item->{_authorised_dob} = 1;
                    } else {
                        my $date = $year."-".$month."-01";
                        $item->{date_of_birth} = $date;
                      }
                }
            }

            trace "Psc list for %s: %s", $company_number, d:$results [PSC LIST];

            $psc_delay_end->($results);
        },
        failure => sub {
            my ($api, $tx) = @_;

            my ($error_code, $error_message) = (
                $tx->error->{code} // 0,
                $tx->error->{message},
            );

            if ($error_code == 404) {  # There might be no psc details but statements could still be there
                trace "Psc listing not found for company [%s]", $company_number [PSC LIST];
                return $psc_delay_end->({ total_results => 0, active_count => 0, items => [] });
            }

            error "Failed to retrieve company psc list for %s: %s", $company_number, $error_message;
            return $self->render_exception("Failed to retrieve company pscs: $error_message");
        },
        error => sub {
            my ($api, $error) = @_;

            $psc_delay_end->();
            error "Error retrieving company psc list for %s: %s", $company_number, $error;
            return $self->render_exception("Error retrieving company pscs: $error");
        },
    )->execute;


   #---- PSC STATEMENTS LIST ------ 

    my $psc_statements_delay_end = $psc_delay->begin(0);

    # Get the psc statements list for the company from the API
     $self->ch_api->company($company_number)->psc_statements({
        start_index    => abs int $first_psc_number,
        items_per_page => $pager->entries_per_page,
    })->get->on(
        success => sub {
            my ($api, $tx) = @_;

            my $results = $tx->success->json;

            trace "Psc statements list for %s: %s", $company_number, d:$results [PSC STATEMENTS LIST];
            $psc_statements_delay_end->($results);
        },
        failure => sub {
            my ($api, $tx) = @_;

            my ($error_code, $error_message) = (
                $tx->error->{code} // 0,
                $tx->error->{message},
            );

            if ($error_code == 404) {  # There might be no statements but psc details could still be there
            trace "Psc statements listing not found for company [%s]", $company_number [PSC STATEMENTS LIST];
                return $psc_statements_delay_end->({ total_results => 0, active_count => 0, items => [] });
            }

            error "Failed to retrieve psc statements list for %s: %s", $company_number, $error_message;
            return $self->render_exception("Failed to retrieve pscs statements: $error_message");
        },
        error => sub {
            my ($api, $error) = @_;

            error "Error retrieving psc statements list for %s: %s", $company_number, $error;
            return $self->render_exception("Error retrieving company pscs: $error");
        },
    )->execute;


        #Once both API calls come back with responses... 

        $psc_delay->on(
                 finish => sub {
                     my ($delay, $pscs, $psc_statements) = @_;

                     my $psc_list = $self->merge_pscs_and_statements($pscs->{items}, $psc_statements->{items});
                         
                     my $total_results_combined = $psc_statements->{total_results} + $pscs->{total_results};

                     my $psc_results = $pscs->{total_results};
                     my $psc_statement_results = $psc_statements->{total_results};

                     my $total_entries = 0;

                     if ($psc_results > $psc_statement_results) {
                         $total_entries = $psc_results;
                     } else {
                         $total_entries= $psc_statement_results;
                     }

                     $pager->total_entries( $total_entries // 0 );

                     $self->stash(current_page_number     => $pager->current_page);
                     $self->stash(page_set                => $pager->pages_in_set());
                     $self->stash(next_page               => $pager->next_page());
                     $self->stash(previous_page           => $pager->previous_page());
                     $self->stash(entries_per_page        => $pager->entries_per_page());

                     # PSC listing
                     $self->stash(pscs => {
                       items                    => $psc_list,
                       active_psc_count         => $pscs->{active_count},
                       psc_count                => $pscs->{total_results},
                       active_statement_count   => $psc_statements->{active_count},
                       statement_count          => $psc_statements->{total_results},
                       total_results            => $total_results_combined,
                     });

                     $self->stash_view_pscs_event();
                     $self->stash_psc_type_heading();

                     my $exemption_delay = Mojo::IOLoop::Delay->new;
                     my $exemption_delay_end;

                     if ( ( $pscs->{links}->{exemptions} || $psc_statements->{links}->{exemptions} ) ||  $total_results_combined == 0  ) 
                     {
                        $exemption_delay_end = $exemption_delay->begin(0);
                        $self->get_exemptions_resource($exemption_delay_end);
                     } else {
                        $self->render;
                     }
                     
            $exemption_delay->on(
                      finish => sub {
                          my ($delay, $exemptions) = @_;

                                $self->stash(exemptions => $exemptions);
                    
                                $self->render;
                          },
                          error => sub {
                             my ($delay, $err) = @_;
                             error "Error getting exemptions : %s", $err [ Exemptions ];
                             $self->render;
                         }
                    );
                 },
                 error => sub {
                     my ($delay, $err) = @_;
                     error "Error getting psc listing : %s", $err [ PSC Listing ];
                     return $self->render_exception($err);
                 }
             );

}

#-------------------------------------------------------------------------------

# Merge 2 types of resources ( psc details & statements ) together, sorting them by active/ceased
sub merge_pscs_and_statements {
    my ($self, $pscs, $statements) = @_;

    my @active_items;
    my @ceased_items;

    push @{ $pscs }, @{ $statements };

    for my $item (@{ $pscs }) {
        $item->{statement_6_flag} = 1 if ( $item->{statement} eq "psc-has-failed-to-confirm-changed-details");
        if ( $item->{ceased_on} || $item->{ceased} ) {
            push @ceased_items, $item;
        } else {
            push @active_items, $item;
        }
    }
    $self->move_all_active_statements_to_top_for_roe(\@active_items);

    push @active_items, @ceased_items;

    return \@active_items;
}

#-------------------------------------------------------------------------------

sub get_exemptions_resource {
    my ($self, $callback) = @_;

    my $company_number = $self->param('company_number');

    $self->ch_api->company($self->stash('company_number'))->exemptions()->get->on(
        success => sub {
            my ( $api, $tx ) = @_;
            my $results = $tx->success->json;

            my $exemptions = $results->{exemptions};

            foreach my $key (keys %$exemptions) {
    
                # Date conversion should take place in the template however it is not possible as that date is part of description string
                $exemptions->{$key}->{items}->[0]->{exempt_from} = CH::Util::DateHelper->isodate_as_string($exemptions->{$key}->{items}->[0]->{exempt_from});
                
                # As it is PSC controller we're not interested in any other exemptions than these 4
                if ( ( $key ne "psc_exempt_as_trading_on_regulated_market" &&
                       $key ne "psc_exempt_as_shares_admitted_on_market" &&
                       $key ne "psc_exempt_as_trading_on_uk_regulated_market" &&
                       $key ne "psc_exempt_as_trading_on_eu_regulated_market" 
                    ) || $exemptions->{$key}->{items}->[0]->{exempt_to} ) {
                    delete $exemptions->{$key};
                }
            }
            
            trace "Exemptions for %s: %s", $self->stash('company_number'), d:$exemptions [EXEMPTIONS];
            if ( %$exemptions ) {
                return $callback->($exemptions);
            } 
            return $callback->();
        },
        failure => sub {
            my ( $api, $error ) = @_;

            my ($error_code, $error_message) = (
                $error->error->{code} // 0,
                $error->error->{message},
            );
            if ($error_code == 404) { 
            trace "Psc exemptions not found for company [%s]", $company_number [EXEMPTIONS];
            return $callback->();
            }

            error "Error retrieving company exemptions for %s: %s",
              $self->stash('company_number'), $error;
            $self->render_exception("Error retrieving company: $error");
        }
      )->execute;

}

#-------------------------------------------------------------------------------

sub move_all_active_statements_to_top_for_roe {
    my ($self, $items) = @_;

    my $company_type = $self->stash->{company}->{type};
    if ($company_type ne "registered-overseas-entity") {
        # Not ROE, do nothing here.
        return;
    }

    my @active_statements = $self->get_all_active_statements($items);

    if (@active_statements and $self->get_company_is_active()) {
        debug "ROE, active statements come first before the PSCs, the other items follow after.";

        # Sort the active statements by index to maintain their order
        @active_statements = sort { $a->{index} <=> $b->{index} } @active_statements;

        # Remove the active statements from their original positions
        @$items = grep { not is_active_statement($_, \@active_statements) } @$items;

        # Move the active statements to the beginning of the array
        unshift @$items, map { $_->{data} } @active_statements;
    }
}

#-------------------------------------------------------------------------------

sub get_all_active_statements {
    my ($self, $items) = @_;

    my @items = @{ $items };
    my @active_statements;

    for my $index (0 .. $#items) {
        my $current_statement = $items[$index];
        if ($current_statement->{statement} and !$current_statement->{ceased_on}) {
            push @active_statements, { index => $index, data => $current_statement };
        }
    }

    if (@active_statements) {
        debug "ACTIVE statements found.";
        return @active_statements;
    } else {
        debug "No active statements found.";
        return ();
    }
}

#-------------------------------------------------------------------------------

# Helper function to check if an item is an active statement
sub is_active_statement {
    my ($item, $active_statements) = @_;

    return $item->{statement} and !$item->{ceased_on} and any { $_->{index} == $item->{index} } @$active_statements;
}

#-------------------------------------------------------------------------------

sub get_company_is_active {
    my ($self) = @_;

    my $company_status = $self->stash->{company}->{company_status};
    if ($company_status eq 'dissolved' or $company_status eq 'converted-closed' or $company_status eq 'removed') {
        return false;
    } else {
        return true;
    }
}

#-------------------------------------------------------------------------------

sub stash_view_pscs_event {
    my ($self) = @_;

    my $company_type = $self->stash->{company}->{type};
    my $view_pscs_event = "View persons with significant control";
    $view_pscs_event = "View beneficial owners" if ($company_type eq 'registered-overseas-entity');

    $self->stash(view_pscs_event => $view_pscs_event);
}

#-------------------------------------------------------------------------------

# Provides the appropriate screen reader heading content as determined by company type.
sub stash_psc_type_heading {
    my ($self) = @_;

    my $company_type = $self->stash->{company}->{type};
    my $psc_type_heading = "Persons with significant control";
    $psc_type_heading = "Beneficial owners" if ($company_type eq 'registered-overseas-entity');

    $self->stash(psc_type_heading => $psc_type_heading);
}

    #-------------------------------------------------------------------------------

1;
