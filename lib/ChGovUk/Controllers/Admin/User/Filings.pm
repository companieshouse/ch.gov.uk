package ChGovUk::Controllers::Admin::User::Filings;

use Mojo::Base 'Mojolicious::Controller';

use CH::Perl;
use CH::Util::Pager;
use CH::Util::DateHelper;
use POSIX qw(strftime);
use MIME::Base64 qw(encode_base64url);

#-------------------------------------------------------------------------------

sub list {
    my ($self) = @_;
    # Process the incoming parameters
    my $page             = abs(int($self->param('page') || 1));     # Which page has been requested
    my $items_per_page = $self->config->{recent_filings}->{items_per_page} || 25;

    my $pager = CH::Util::Pager->new(entries_per_page => $items_per_page, current_page => $page);

    #  Uncomment to enable paging when available
    my $query = {
      #  start_index    => $pager->first,
      #  items_per_page => $pager->entries_per_page,
        user_id        => $self->param('user_id')
    };

    $self->ch_api->user->user_transactions($query)->get->on(
        success => sub {
            my ( $api, $tx ) = @_;
            my $rf_results = $tx->success->json;

            for my $doc (@{$rf_results->{items}}) {
                if ( defined $doc->{closed_at} ) {
                    $doc->{closed_at_date} = CH::Util::DateHelper->isodate_as_string($doc->{closed_at});
                    $doc->{closed_at_time} = CH::Util::DateHelper->isotime_as_string($doc->{closed_at})->strftime("%l:%M%P");
                }
                if ($doc->{status} eq "open" && $doc->{links}->{resume}) {
                   $self->_build_resume_link($doc, $doc->{links}->{resume});
                }
            }

            # Work out the paging numbers
            $pager->total_entries( $rf_results->{total_result} // 0 );
            warn "recent filings total_count %d entries per page %d",
            $pager->total_entries, $pager->entries_per_page() [RECENT_FILINGS];

            $self->stash(current_page_number    => $pager->current_page);
            $self->stash(page_set               => $pager->pages_in_set());
            $self->stash(next_page              => $pager->next_page());
            $self->stash(previous_page          => $pager->previous_page());
            $self->stash(entries_per_page       => $pager->entries_per_page());

            $self->stash(recent_filings => $rf_results->{items});
            $self->stash(user           => $rf_results->{items}->[0]->{closed_by}->{email});
            $self->stash(filings_count  => $rf_results->{total_count});

            $self->render;
        },
        
        failure => sub {
            my ($api, $tx) = @_;
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

sub _build_resume_link {
    my ($self, $transaction, $resume_link) = @_;
    
    my $transaction_id = $transaction->{id};
    my $encoded_resume_link = encode_base64url($resume_link);
    
    $transaction->{resume_link} = "/user/transactions/" . $transaction_id . "/resume?id=" . $encoded_resume_link;
    return;
}

#-------------------------------------------------------------------------------
1;
