package ChGovUk::Controllers::Company::Document;

use Mojo::Base 'Mojolicious::Controller';
use CH::Perl;
use Net::CompaniesHouse::DocumentEndpoint;
use Time::HiRes qw(tv_interval gettimeofday);
use Scalar::Util qw(refaddr);

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

    my $doc_start = [Time::HiRes::gettimeofday()];
    debug "TIMING document (company document) '" . refaddr(\$doc_start) . "'";
    $delay->steps(
        sub {
            my ($delay) = @_;
            my $next = $delay->begin(0);

            my $start = [Time::HiRes::gettimeofday()];
            debug "TIMING company.filing_history_item (company document) '" . refaddr(\$start) . "'";
            $self->ch_api
            ->company($self->stash->{company_number})
            ->filing_history_item($self->stash->{filing_history_id})
            ->force_api_key(1)
            ->get->on(
                failure => sub {
                    my ($api, $tx) = @_;
                    debug "TIMING company.filing_history_item (company document) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                    my $code = $tx->error->{code} // 0;

                    if ($code == 404) {
                        $delay->emit('not_found', sprintf(
                            'Filing history item was not found for company_number [%s] filing_history_id [%s]',
                            $self->stash->{company_number},
                            $self->stash->{filing_history_id}
                        ));
                    }
                    else {
                        $delay->emit('error', sprintf(
                            'Failure fetching filing history item for company_number [%s] filing_history_id [%s] - %s',
                            $self->stash->{company_number},
                            $self->stash->{filing_history_id},
                            $tx->error->{message}
                        ));
                    }
                },
                error => sub {
                    my ($api, $err) = @_;
                    debug "TIMING company.filing_history_item (company document) error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);

                    $delay->emit('error', sprintf(
                        'Error fetching filing history item for company_number [%s] filing_history_id [%s]: %s',
                        $self->stash->{company_number},
                        $self->stash->{filing_history_id},
                        $err,
                    ));
                },
                success => sub {
                    my ($api, $tx) = @_;
                    debug "TIMING company.filing_history_item (company document) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);

                    if (my $document_metadata_uri = $tx->res->json->{links}->{document_metadata}) {
                        $next->($document_metadata_uri);
                    }
                    else {
                        $delay->emit('not_found', 'document_metadata not found in JSON');
                    }
                },
            )->execute;
        },
        sub {
            my ($delay, $document_metadata_uri) = @_;
            my $next = $delay->begin(0);

            my $start = [Time::HiRes::gettimeofday()];
            debug "TIMING document (company document) '" . refaddr(\$start) . "'";
            $self->ch_api->document($document_metadata_uri)->is_download($is_download)->$format->get->on(
                failure => sub {
                    my ($api, $tx) = @_;
                    debug "TIMING document (company document) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
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
                    debug "TIMING document (company document) error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);

                    $delay->emit('error', sprintf(
                        'Error fetching document for company_number [%s] filing_history_id [%s]: [%s]',
                        $self->stash->{company_number},
                        $self->stash->{filing_history_id},
                        $err,
                    ));
                },
                success => sub {
                    my ($api, $tx) = @_;
                    debug "TIMING document (company document) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);

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
        debug "TIMING document (company document) error '" . refaddr(\$doc_start) . "' elapsed: " . Time::HiRes::tv_interval($doc_start);

        error $err [DOCUMENT];
        $self->reply->exception($err);
    });

    $delay->on(not_found => sub {
        my ($delay, $message) = @_;
        debug "TIMING document (company document) not_found '" . refaddr(\$doc_start) . "' elapsed: " . Time::HiRes::tv_interval($doc_start);

        info "[%s]: not found", $message [DOCUMENT];
        $self->reply->not_found;
    });

    $delay->on(finish => sub {
        my ($delay, $location) = @_;
        debug "TIMING document (company document) finish '" . refaddr(\$doc_start) . "' elapsed: " . Time::HiRes::tv_interval($doc_start);

        debug "Serving redirect to [%s]", $location [DOCUMENT];
        $self->redirect_to($location);
    });
}

#-------------------------------------------------------------------------------

1;
