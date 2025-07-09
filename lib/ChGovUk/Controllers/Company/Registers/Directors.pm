package ChGovUk::Controllers::Company::Registers::Directors;

use Mojo::Base 'Mojolicious::Controller';

use CH::Perl;
use CH::Util::Pager;
use Time::HiRes qw(tv_interval gettimeofday);
use Scalar::Util qw(refaddr);

#-------------------------------------------------------------------------------

sub list {
    my ($self) = @_;

    $self->render_later;

    # Process the incoming parameters
    my $company_number    = $self->param('company_number');     # Mandatory
    my $page              = abs int($self->param('page') || 1); # Which page as been requested
    my $items_per_page    = $self->config->{officer_list}->{items_per_page} || 35;

    trace "Get register company directors list for %s, page %s", $company_number, $page [REGISTERS DIRECTOR LIST];
    my $pager = CH::Util::Pager->new(entries_per_page => $items_per_page, current_page => $page);

    trace "Call officer list api for company %s, items_per_page %s", $company_number, $items_per_page [REGISTERS DIRECTOR LIST];
    my $first_officer_number = $page eq 1 ? 0 : ($page - 1) * $items_per_page;

    # Get the officer list of active directors for the company from the API
    my $start = [Time::HiRes::gettimeofday()];
    debug "TIMING company.officers (registers directors) '" . refaddr(\$start) . "'";
    $self->ch_api->company($company_number)->officers({
        start_index    => abs int $first_officer_number,
        items_per_page => $pager->entries_per_page,
        register_type  => 'directors',
        register_view  => 'true',
    })->get->on(
        success => sub {
            my ($api, $tx) = @_;
            debug "TIMING company.officers (registers directors) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);

            my $results = $tx->success->json;

            $self->stash(directors => {
                items          => $results->{items},
                active_count   => $results->{active_count},
                resigned_count => $results->{resigned_count},
                total_results  => $results->{total_results},
            });

            for my $item (@{ $results->{items} }) {
                if ($item->{date_of_birth}) {
                    $item->{date_of_birth} = sprintf("%04s-%02s-%02s",
                        $item->{date_of_birth}->{year},
                        $item->{date_of_birth}->{month},
                        $item->{date_of_birth}->{day} // '01');
                }
            }

            trace "Registered director list for %s: %s", $company_number, d:$results [REGISTERS DIRECTOR LIST];

            # Work out the paging numbers
            $pager->total_entries($results->{total_results});
            trace "Registered director listing total_count %d entries per page %d", $pager->total_entries, $pager->entries_per_page [REGISTERS DIRECTOR LIST];

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
            debug "TIMING company.officers (registers directors) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);

            my ($error_code, $error_message) = (
                $tx->error->{code} // 0,
                $tx->error->{message},
            );

            if ($error_code == 404) {
                trace "Registered directors listing not found for company [%s]", $company_number [REGISTERS DIRECTOR LIST];
                return $self->render_not_found;
            }

            error "Failed to retrieve registered directors list for %s: %s", $company_number, $error_message;
            return $self->render_exception("Failed to retrieve registered directors: $error_message");
        },
        error => sub {
            my ($api, $error) = @_;
            debug "TIMING company.officers (registers directors) error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);

            error "Error retrieving registered directors list for %s: %s", $company_number, $error;
            return $self->render_exception("Error retrieving registered directors: $error");
        },
    )->execute;
}

#-------------------------------------------------------------------------------

1;
