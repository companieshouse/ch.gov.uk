package ChGovUk::Controllers::Company::Document;

use Mojo::Base 'Mojolicious::Controller';
use CH::Perl;
use Net::CompaniesHouse::DocumentEndpoint;

#-------------------------------------------------------------------------------

sub document {
    my ($self) = @_;
    my $format = $self->param('format') // 'pdf';

    # Only allow supported formats
    unless (Net::CompaniesHouse::DocumentEndpoint->can($format)) {
        my $err = sprintf('API document() method does not support document type [%s]', $format);

        error $err [DOCUMENT];
        return $self->reply->exception($err);
    }

    my $is_download = !!$self->param('download');
    my $delay = Mojo::IOLoop->delay;

    $self->render_later;

    $delay->steps(
        sub {
            my ($delay) = @_;
            my $next = $delay->begin(0);

            $self->ch_api
            ->company($self->stash->{company_number})
            ->filing_history_item($self->stash->{filing_history_id})
            ->force_api_key(1)
            ->get->on(
                failure => sub {
                    my ($api, $tx) = @_;

                    $delay->emit('error', sprintf(
                        'Failure fetching filing history item for company_number [%s] filing_history_id [%s]',
                        $self->stash->{company_number},
                        $self->stash->{filing_history_id},
                    ));
                },
                error => sub {
                    my ($api, $err) = @_;

                    $delay->emit('error', sprintf(
                        'Error fetching filing history item for company_number [%s] filing_history_id [%s]: %s',
                        $self->stash->{company_number},
                        $self->stash->{filing_history_id},
                        $err,
                    ));
                },
                success => sub {
                    my ($api, $tx) = @_;

                    if (my $document_metadata_uri = $tx->res->json->{links}->{document_metadata}) {
                        $next->($document_metadata_uri);
                    }
                    else {
                        $delay->emit('error', 'document_metadata not found in JSON');
                    }
                },
            )->execute;
        },
        sub {
            my ($delay, $document_metadata_uri) = @_;
            my $next = $delay->begin(0);

            $self->ch_api->document($document_metadata_uri)->is_download($is_download)->$format->get->on(
                failure => sub {
                    my ($api, $tx) = @_;
                    my $code = $tx->error->{code} // 0;

                    if ($code == 404) {
                        $delay->emit('not_found', $document_metadata_uri);
                    }
                    else {
                        $delay->emit('error', sprintf(
                            'Failure fetching document for company_number [%s] filing_history_id [%s]: %d [%s]',
                            $self->stash->{company_number},
                            $self->stash->{filing_history_id},
                            $code,
                            $tx->error->{message},
                        ));
                    }
                },
                error => sub {
                    my ($api, $err) = @_;

                    $delay->emit('error', sprintf(
                        'Error fetching document for company_number [%s] filing_history_id [%s]: [%s]',
                        $self->stash->{company_number},
                        $self->stash->{filing_history_id},
                        $err,
                    ));
                },
                success => sub {
                    my ($api, $tx) = @_;

                    trace "TRANSACTION: %s", d:$tx [DOCUMENT];
                    my $location = $tx->res->headers->location;

                    if ($location) {
                        $next->($location);
                    }
                    else {
                        $delay->emit('error', sprintf(
                            'Failed to get redirect from Document API, document_metadata [%s]',
                            $document_metadata_uri,
                        ));
                    }
                }
            )->execute;
        },
    );

    $delay->on(error => sub {
        my ($delay, $err) = @_;

        error $err [DOCUMENT];
        $self->reply->exception($err);
    });

    $delay->on(not_found => sub {
        my ($delay, $uri) = @_;

        info "[%s]: not found", $uri [DOCUMENT];
        $self->reply->not_found;
    });

    $delay->on(finish => sub {
        my ($delay, $location) = @_;

        debug "Serving redirect to [%s]", $location [DOCUMENT];
        $self->redirect_to($location);
    });
}

#-------------------------------------------------------------------------------

1;
