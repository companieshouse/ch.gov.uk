package ChGovUk::Controllers::Company::Registers::Secretaries;

use Mojo::Base 'Mojolicious::Controller';

use CH::Perl;
use CH::Util::Pager;

#-------------------------------------------------------------------------------

sub list {
    my ($self) = @_;

    $self->render_later;

    # Process the incoming parameters
    my $company_number    = $self->param('company_number');     # Mandatory
    my $page              = abs int($self->param('page') || 1); # Which page as been requested
    my $items_per_page    = $self->config->{officer_list}->{items_per_page} || 35;

    trace "Get register company secretaries list for %s, page %s", $company_number, $page [REGISTERS SECRETARY LIST];
    my $pager = CH::Util::Pager->new(entries_per_page => $items_per_page, current_page => $page);

    trace "Call officer list api for company %s, items_per_page %s", $company_number, $items_per_page [REGISTERS SECRETARY LIST];
    my $first_officer_number = $page eq 1 ? 0 : ($page - 1) * $items_per_page;

    # Get the officer list of active secretaries for the company from the API
    $self->ch_api->company($company_number)->officers({
        start_index    => abs int $first_officer_number,
        items_per_page => $pager->entries_per_page,
        officer_status => 'active',
        register_type  => 'secretaries',
        register_view  => 'true',
    })->get->on(
        success => sub {
            my ($api, $tx) = @_;

            my $results = $tx->success->json;

            $self->stash(secretaries => {
                items          => $results->{items},
                active_count   => $results->{active_count},
                resigned_count => $results->{resigned_count},
                total_results  => $results->{total_results},
            });

            trace "Registered secretary list for %s: %s", $company_number, d:$results [REGISTERS SECRETARY LIST];

            # Work out the paging numbers
            $pager->total_entries($results->{total_results});
            trace "Registered secretary listing total_count %d entries per page %d", $pager->total_entries, $pager->entries_per_page [REGISTERS DIRECTOR LIST];

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
                trace "Registered secretaries listing not found for company [%s]", $company_number [REGISTERS SECRETARY LIST];
                return $self->render_not_found;
            }

            error "Failed to retrieve registered secretaries list for %s: %s", $company_number, $error_message;
            return $self->render_exception("Failed to retrieve registered secretaries: $error_message");
        },
        error => sub {
            my ($api, $error) = @_;

            error "Error retrieving registered secretaries list for %s: %s", $company_number, $error;
            return $self->render_exception("Error retrieving registered secretaries: $error");
        },
    )->execute;
}

#-------------------------------------------------------------------------------

1;
