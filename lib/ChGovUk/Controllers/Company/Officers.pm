package ChGovUk::Controllers::Company::Officers;

use Mojo::Base 'Mojolicious::Controller';

use CH::Perl;
use CH::Util::Pager;
use CH::Util::DateHelper;

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

    trace "Get company officer list for %s, page %s", $company_number, $page [OFFICER LIST];
    my $pager = CH::Util::Pager->new(entries_per_page => $items_per_page, current_page => $page);

    trace "Call officer list api for company %s, items_per_page %s", $company_number, $items_per_page [OFFICER LIST];
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
    $self->ch_api->company($company_number)->officers({
        start_index    => abs int $first_officer_number,
        items_per_page => $pager->entries_per_page,
        filter         => $filter,
    })->get->on(
        success => sub {
            my ($api, $tx) = @_;

            my $results = $tx->success->json;

            # If the filter string contains 'active' we are assuming
            # the active filter is set. If is_active_filter_set then we
            # supress the resigned_count on template.
            if ($filter =~ /active/) {
                $self->stash(is_active_filter_set => 1);
            }

            my $company_prefix = substr(uc $company_number,0,2);
            my $is_overseas_entity = 0;

            if ($company_prefix eq "OE") {
                $is_overseas_entity = 1;
            }

            $self->stash(categories => $categories);
            $self->stash(is_overseas_entity => $is_overseas_entity);
            $self->stash(officers => {
                items              => $results->{items},
                active_count       => $results->{active_count},
                inactive_count     => $results->{inactive_count},
                resigned_count     => $results->{resigned_count},
                total_results      => $results->{total_results},
            });

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

            trace "Officer list for %s: %s", $company_number, d:$results [OFFICER LIST];

            # Work out the paging numbers
            $pager->total_entries($results->{total_results});
            trace "Officer listing total_count %d entries per page %d", $pager->total_entries, $pager->entries_per_page [OFFICER LIST];

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

            my ($error_code, $error_message) = (
                $tx->error->{code} // 0,
                $tx->error->{message},
            );

            if ($error_code == 404) {
                trace "Officer listing not found for company [%s]", $company_number [COMPANY PROFILE];

                # render the regular list template to display message saying no officers for this company
                if ($filter =~ /active/) {
                    $self->stash(is_active_filter_set => 1);
                }
                $self->stash(categories => $categories);
                $self->stash(officers => {});
                return $self->render;
            }

            error "Failed to retrieve company officer list for %s: %s", $company_number, $error_message;
            return $self->render_exception("Failed to retrieve company officers: $error_message");
        },
        error => sub {
            my ($api, $error) = @_;

            error "Error retrieving company officer list for %s: %s", $company_number, $error;
            return $self->render_exception("Error retrieving company officers: $error");
        },
    )->execute;
}

#-------------------------------------------------------------------------------

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
