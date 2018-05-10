package ChGovUk::Controllers::RegisterOfDisqualifications;

use Mojo::Base 'Mojolicious::Controller';

use POSIX qw(ceil);

use CH::Perl;
use CH::Util::Pager;

use constant DEFAULT_ITEMS_PER_PAGE => 50;

# ------------------------------------------------------------------------------

sub list {
    my ($self) = @_;

    $self->render_later;

    my $query = $self->param('letter');

    my $page           = (abs int $self->param('page')) || 1;
    my $items_per_page = DEFAULT_ITEMS_PER_PAGE;

    trace 'Page [%s] with [%s] items per page - query term: [%s]', $page, $items_per_page, $query;

    $self->ch_api->search->disqualified_officers({
        q              => "$query*",
        items_per_page => $items_per_page,
        start_index    => ($page - 1) * $items_per_page,
    })->get->on(
        success => sub {
            my ($api, $tx) = @_;

            my $json  = $tx->res->json;
            my $pager = CH::Util::Pager->new(
                entries_per_page => $items_per_page,
                current_page     => $page,
                total_entries    => $json->{total_results},
            );

            # The division results in a float, so round up to the nearest int to cater for the remaining results
            my $total_pages = ceil($json->{total_results} / $pager->{entries_per_page});

            $self->stash(
                active_letter     => $query,
                alphabet          => [ 'A' .. 'Z' ],
                disqualifications => $json,
                pager             => {
                    current_page     => $pager->current_page,
                    entries_per_page => $pager->entries_per_page,
                    next_page        => $pager->next_page,
                    pages_in_set     => $pager->pages_in_set,
                    previous_page    => $pager->previous_page,
                    show_pager       => $total_pages > 1,
                    total_pages      => $total_pages,
                },
            );

            return $self->render;
        },
        failure => sub {
            my ($api, $tx) = @_;

            my $error_code = $tx->error->{code}       // 0;
            my $error_message = $tx->error->{message} // 0;

            error 'Failed to retrieve search results: [%s] [%s]', $error_code, $error_message;

            return $error_code == 416
                ? $self->render('error', error => 'invalid_request', description => 'You have requested a page outside of the available result set', status => 416)
                : $self->render('error', error => 'internal_error', description => 'The search service is currently unavailable', status => 500);
        },
        error => sub {
            my ($api, $error) = @_;

            my $message = "Error retrieving search results: $error";
            error '%s', $message;

            return $self->render_exception($message);
        },
    )->execute;
}

# ==============================================================================

1;

=head1 NAME

ChGovUk::Controllers::RegisterOfDisqualifications

=cut
