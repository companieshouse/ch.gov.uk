package ChGovUk::Controllers::Company::Officers;

use Mojo::Base 'Mojolicious::Controller';

use CH::Perl;
use CH::Util::Pager;
use CH::Util::DateHelper;
use Locale::Simple;
use Time::HiRes qw(tv_interval gettimeofday);
use Scalar::Util qw(refaddr);
use Data::Dumper;

use constant AVAILABLE_CATEGORIES => {
    active => 'Current officers'
};

#-------------------------------------------------------------------------------

sub list {
    my ($self) = @_;

    $self->render_later;

    # Process the incoming parameters
    my $company_number    = $self->param('company_number');     # Mandatory
    my $page              = abs int($self->param('page') || 1); # Which page as been requested
    my $category_filter   = $self->get_filter('ol');            # List of categories to filter by (optional)
    my @filter_categories = split ',', $category_filter;

    my $items_per_page = $self->config->{officer_list}->{items_per_page} || 35;

    #trace "Get company officer list for %s, page %s", $company_number, $page [OFFICER LIST];
    $self->app->log->trace("Get company officer list for $company_number, page $page [OFFICER LIST]");
    my $pager = CH::Util::Pager->new(entries_per_page => $items_per_page, current_page => $page);

    #trace "Call officer list api for company %s, items_per_page %s", $company_number, $items_per_page [OFFICER LIST];
    $self->app->log->trace("Call officer list api for company $company_number, items_per_page " . $items_per_page . " [OFFICER LIST]");
    my $first_officer_number = $page eq 1 ? 0 : ($page - 1) * $items_per_page;

    # Generate an arrayref containing hashrefs of category id's/name's, sorted by name
    my $categories = [
        sort { $a->{name} cmp $b->{name} }
        (map { {
            id   => $_,
            name => AVAILABLE_CATEGORIES->{$_},
        } } keys(%{AVAILABLE_CATEGORIES()}))
    ];

    my $selected_category_count = 0;

    # Iterate through categories setting checked flag and keeping a count of number checked
    for my $category (@$categories) {
        if (scalar(grep { $category->{id} eq $_ } @filter_categories)) {
            $category->{checked} = 1;
            $selected_category_count++;
        }
    }

    my $filter = join(',', map { $_->{id} } grep($_->{checked}, @$categories));

    # Get the officer list for the company from the API
    my $start = [Time::HiRes::gettimeofday()];
    $self->app->log->debug("TIMING company.officers (company officers) '" . refaddr(\$start) . "'");
    $self->ch_api->company($company_number)->officers({
        start_index    => abs int $first_officer_number,
        items_per_page => $pager->entries_per_page,
        filter         => $filter,
    })->get->on(
        success => sub {
            my ($api, $tx) = @_;

            $self->app->log->debug("TIMING company.officers (company officers) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
            my $results = $tx->res->json;

            # If the filter string contains 'active' we are assuming
            # the active filter is set. If is_active_filter_set then we
            # suppress the resigned_count on template.
            my $is_active_filter_set = 0;
            if ($filter =~ /active/) {
                $self->stash(is_active_filter_set => 1);
                $is_active_filter_set = 1;
            }

            my $is_overseas_entity = 0;
            if (substr(uc $company_number,0,2) eq "OE") {
                $is_overseas_entity = 1;
            }

            $self->stash(categories => $categories);
            $self->stash(is_overseas_entity => $is_overseas_entity);
            $self->stash(officers => {
                items          => $results->{items},
                active_count   => $results->{active_count},
                inactive_count => $results->{inactive_count},
                resigned_count => $results->{resigned_count},
                total_results  => $results->{total_results},
            });
            $self->stash(company_appointments =>
                build_company_appointments($results, $is_active_filter_set, $is_overseas_entity));

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

                if ( $item->{identity_verification_details} && $item->{identity_verification_details}{anti_money_laundering_supervisory_bodies} ) {
                    $item->{identity_verification_details}{supervisory_bodies_string} = join ', ', @{ $item->{identity_verification_details}{anti_money_laundering_supervisory_bodies} // [] };
                }
            }

            #trace "Officer list for %s: %s", $company_number, d:$results [OFFICER LIST];
            $self->app->log->trace("Officer list for $company_number: " . Dumper($results) . " [OFFICER LIST]");

            # Work out the paging numbers
            $pager->total_entries($results->{total_results});
            #trace "Officer listing total_count %d entries per page %d", $pager->total_entries, $pager->entries_per_page [OFFICER LIST];
            $self->app->log->trace("Officer listing total_count " . $pager->total_entries . " entries per page " . $pager->entries_per_page . " [OFFICER LIST]");

            $self->stash(paging => {
                current_page_number => $pager->current_page,
                page_set            => $pager->pages_in_set,
                next_page           => $pager->next_page,
                previous_page       => $pager->previous_page,
                entries_per_page    => $pager->entries_per_page,
            });

            return $self->render;
        },
        failure => sub {
            my ($api, $tx) = @_;
            $self->app->log->debug("TIMING company.officers (company officers) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

            my ($error_code, $error_message) = (
                $tx->error->{code} // 0,
                $tx->error->{message},
            );

            if ($error_code == 404) {
                #trace "Officer listing not found for company [%s]", $company_number [COMPANY PROFILE];
                $self->app->log->trace("Officer listing not found for company [$company_number] [COMPANY PROFILE]");

                # render the regular list template to display message saying no officers for this company
                my $results = {
                    active_count   => 0,
                    inactive_count => 0,
                    resigned_count => 0
                };
                my $is_active_filter_set = 0;
                my $is_overseas_entity = 0;
                if ($filter =~ /active/) {
                    $self->stash(is_active_filter_set => 1);
                    $is_active_filter_set = 1;
                }
                $self->stash(company_appointments =>
                    build_company_appointments($results, $is_active_filter_set, $is_overseas_entity));
                $self->stash(categories => $categories);
                $self->stash(officers => {});
                return $self->render;
            }

            #error "Failed to retrieve company officer list for %s: %s", $company_number, $error_message;
            $self->app->log->error("Failed to retrieve company officer list for $company_number: $error_message");
            return $self->reply->exception("Failed to retrieve company officers: $error_message");
        },
        error => sub {
            my ($api, $error) = @_;
            $self->app->log->debug("TIMING company.officers (company officers) error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

            #error "Error retrieving company officer list for %s: %s", $company_number, $error;
            $self->app->log->error("Error retrieving company officer list for $company_number: $error");
            return $self->reply->exception("Error retrieving company officers: $error");
        },
    )->execute;
}

#-------------------------------------------------------------------------------

# Builds a company appointments string such as '49 officers / 42 resignations'.
sub build_company_appointments() {
    my ($results, $is_active_filter_set, $is_overseas_entity) = @_;

    my $active_count = $results->{active_count};
    my $resigned_count = $results->{resigned_count};
    my $officer_count = $active_count + $results->{inactive_count} + $resigned_count;

    if (!$is_active_filter_set) {
        if ($officer_count == 0) {
            return "There are no officer details available for this company.";
        } else {
            my $resignation_type = $is_overseas_entity ?
                ln('cessation', 'cessations', $resigned_count) :
                ln('resignation', 'resignations', $resigned_count);
            return ' ' . $officer_count . ' ' .
                ln('officer ', 'officers ', $officer_count) . '/ ' .
                $resigned_count . ' ' . $resignation_type;
        }
    } else {
        if ($active_count == 0) {
            return "There are no current officers available for this company."
        } else {
            return ' ' . $active_count . ' ' . ln('current officer ', 'current officers ', $officer_count);
        }
    }
}

1;

=cut
sub list {
    my ($self) = @_;

    my $company_profile_model = new ChGovUk::Models::CompanyProfile(
                                    _config        => $self->app->config,
                                    company_number => $self->stash('company_number'),
                                );

    $self->stash( company => $company_profile_model );

    my $page = $self->param('page') // 1;

    my $model = new ChGovUk::Models::Officers(
        config         => $self->app->config,
        page           => $page,
        company_number => $self->stash('company_number'),
    );
    $model->page_size( $self->param('page_size') ) if $self->param('page_size');

    $self->stash( officers => $model, );

    $self->render();

    return;
}
=cut
