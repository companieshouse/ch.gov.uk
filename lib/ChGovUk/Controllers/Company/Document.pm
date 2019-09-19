package ChGovUk::Controllers::Company::Document;

use Mojo::Base 'Mojolicious::Controller';
use CH::Perl;
use Net::CompaniesHouse::DocumentEndpoint;
use REST::Client;
use Mojo::JSON qw(decode_json encode_json);

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

# Submits a request to the SCUD API to create a SCUD order resulting in the retrieval or scanning of
# an image for a missing document.
sub scud {
    trace "API scud() method called.";
    my ($self) = @_;

    my $psNumber = $self->stash->{filing_history_id};
    my $scud_order = { psNumber => $psNumber };
    my $body = encode_json($scud_order);
    trace "body = %s", $body;

    my %headers = ('Content-Type', 'application/json');
    trace "headers = @{[%headers]}";

    my $client = REST::Client->new();
    my $response = $client->POST($self->get_scud_orders_url(), $body, \%headers);
    $self->publish_response($response);

    return ;
}

#-------------------------------------------------------------------------------

# Stashes the HTTP response code and content to make them available to web page.
sub publish_response {
    my ($self, $response) = @_;
    my $responseCode = $response->responseCode();
    my $responseContent = $response->responseContent();
    my $isSuccess = $responseCode >= 200 && $responseCode < 300;
    trace "Response code for request to SCUD API = %s", $responseCode;
    trace "Response content = %s", $responseContent;
    $self->stash(response_code => $responseCode);
    $self->stash(response_content => $responseContent);
    $self->stash(is_success => $isSuccess);
}

#-------------------------------------------------------------------------------

# Gets the SCUD orders URL.
sub get_scud_orders_url {
    my ($self) = @_;
    my $scud_orders_url = $self->get_scud_api_url()."/scudOrders";
    trace "SCUD orders URL = %s", $scud_orders_url;
    return $scud_orders_url;
}

#-------------------------------------------------------------------------------

# Gets the configured SCUD API URL.
sub get_scud_api_url {
    my ($self) = @_;
    my $scud_api = $self->config->{scud}->{api_url};
    trace "Configured SCUD API URL = %s", $scud_api;
    return $scud_api;
}

#-------------------------------------------------------------------------------

1;
