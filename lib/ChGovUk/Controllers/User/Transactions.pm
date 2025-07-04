package ChGovUk::Controllers::User::Transactions;

use Mojo::Base 'Mojolicious::Controller';

use CH::Perl;
use CH::Util::Pager;
use CH::Util::DateHelper;
use POSIX qw(strftime);
use Time::HiRes qw(tv_interval gettimeofday);
use Scalar::Util qw(refaddr);

#-------------------------------------------------------------------------------

sub list {
    my ($self) = @_;

    # Process the incoming parameters
    my $page             = abs(int($self->param('page') || 1));     # Which page has been requested
    my $items_per_page = $self->config->{recent_filings}->{items_per_page} || 25;

    my $pager = CH::Util::Pager->new(entries_per_page => $items_per_page, current_page => $page);

    my $query = {
        start_index    => $pager->first,
        items_per_page => $pager->entries_per_page,
        user_id        => $self->stash->{user_id}
    };

    # encode the selected categories as a comma-separated list and add it as a parameter to the
    # filing-history query

    # the selected categories as a hashref of category-name => true pairs. used from the template
    # to determine whether the corresponding category-filter checkbox should be checked
    # Get the filing history for the company from the API
    my $start = [Time::HiRes::gettimeofday()];
    debug "TIMING user.user_transactions (transactions) '" . refaddr(\$start) . "'";
    $self->ch_api->user->user_transactions($query)->get->on(
        success => sub {
            my ( $api, $tx ) = @_;
            debug "TIMING user.user_transactions (transactions) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
            my $rf_results = $tx->success->json;

            for my $doc (@{$rf_results->{items}}) {

                  $doc->{closed_at_date} = CH::Util::DateHelper->isodate_as_string($doc->{closed_at});
                  $doc->{closed_at_time} = CH::Util::DateHelper->isotime_as_string($doc->{closed_at})->strftime('%r');
            }

    # Work out the paging numbers
            $pager->total_entries( $rf_results->{total_count} // 0 );
            trace "recent filings total_count %d entries per page %d",
                $pager->total_entries, $pager->entries_per_page() [RECENT_FILINGS];

           $self->stash(current_page_number    => $pager->current_page);
           $self->stash(page_set               => $pager->pages_in_set());
           $self->stash(next_page              => $pager->next_page());
           $self->stash(previous_page          => $pager->previous_page());
           $self->stash(entries_per_page       => $pager->entries_per_page());

           $self->stash(recent_filings => $rf_results->{items});
           $self->stash(user =>  $rf_results->{items}->[0]->{creator}->{email});
           $self->stash(filings_count => $rf_results->{total_count});

           $self->render;
        },
        failure => sub {
            my ($api, $tx) = @_;
            debug "TIMING user.user_transactions (transactions) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);

            my $error_code = $tx->error->{code} // 0;
            if ($error_code == 404) {
                $self->stash(no_filings => 1);
            }
            $self->render;
        }
      )->execute;

    $self->render_later;
}

#-------------------------------------------------------------------------------

1;
