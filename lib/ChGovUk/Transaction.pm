package ChGovUk::Transaction;

use CH::Perl;
use Digest::SHA1 qw/ sha1_hex /;
use POSIX qw/ strftime /;
use CH::Util::CompanyPrefixes;
use Mojo::Util qw( camelize );
use Mojo::IOLoop;

use Moose;
use Data::Dumper;

has 'controller' => ( is => 'ro', isa => 'Mojolicious::Controller', required => 1 );

# Transaction data
has 'transaction_number' => ( is => 'rw', isa => 'Str' );
has 'status' => ( is => 'rw' );
has 'date' => ( is => 'rw' );
has 'form_type' => ( is => 'rw' );

# private, exposed in status/date/etc
has 'model' => ( is => 'rw' );

# Endpoint and routing
has 'endpoint' => ( is => 'rw' );
has 'route' => ( is => 'rw' );
has 'metadata' => ( is => 'rw' );

# Other info
has 'prescreen' => ( is => 'rw' );

#-------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    $self->controller->stash(transaction => $self);

    # Create data adapter FIXME should be somewhere else
    my $data_adapter = ChGovUk::Models::DataAdapter->new( controller => $self->controller );
    $self->controller->stash(data_adapter => $data_adapter);

    # Get endpoint (URL from request - e.g. /a/b/12/5/)
    if($self->transaction_number) {
        my $tx_path     = $self->controller->url_for('transactions')->path->to_string;
        my $full_path   = $self->controller->req->url;
        my $re          = qr/$tx_path\/([^\?]*)(\?.*)?/;
        my ($endpoint)  = $full_path =~ /$re/;
        $self->endpoint($endpoint);
    } else {
        my @parts = @{$self->controller->req->url->path->parts};
        $self->endpoint(join '/', @parts[2..$#parts]);
    }
    $self->controller->app->log->debug("Got transaction endpoint [" . $self->endpoint . "] [ROUTING]");

    my $route = $self->controller->app->routes->find($self->controller->current_route)->pattern->unparsed;
    $self->controller->app->log->debug("NSDBG route: ". $route);
    $route = substr($route, 1) if substr($route, 0, 1) eq '/';
    $self->route($route);
    # Can't locate object method "any" via package "ChGovUk::Transaction" at
    # Replace deprecated Mojolicious::Routes::Route::route method calls - MR
    $self->controller->app->log->trace("Got transaction route [$route] [ROUTING]");

    # Get metadata
    $self->metadata($self->controller->get_transaction_metadata( endpoint => $self->route ));
    $self->controller->app->log->trace("Got transaction metadata:\n" . Dumper($self->metadata) . "[ROUTING]");

    if($self->endpoint ne 'confirmation' && !$self->metadata) {
        ($route) = $route =~ /(.*)\/([^\/]+)$/;
        $self->route($route);
        $self->controller->app->log->trace("Got transaction endpoint [" . $self->endpoint . "] [ROUTING]");
        $self->controller->app->log->trace("Got transaction route [$route] [ROUTING]");

        $self->metadata($self->controller->get_transaction_metadata( endpoint => $self->route ));
    }

    if($self->has_state) {
        $self->controller->app->log->debug("Transaction [" . ( $self->transaction_number // 'undef' ) . "] has state:\n" . Dumper($self->controller->session->{transaction}{$self->transaction_number}) . " [ROUTING]");
    } else {
        $self->controller->app->log->warn("Transaction [" . ( $self->transaction_number // 'undef' ) . "] has no state [ROUTING]");
    }
}

#-------------------------------------------------------------------------------

sub has_state {
    my ($self) = @_;

    my $has_state = $self->transaction_number && exists($self->controller->session->{transaction}{$self->transaction_number}) ? 1 : 0;
    $self->controller->app->log->debug("Transaction has_state [" . $has_state . "] [ROUTING]");
    $self->controller->app->log->debug("Transaction state:\n" . Dumper($self->controller->session->{transaction}{$self->transaction_number}) . " [ROUTING]") if $has_state;

    return $has_state;
}

#-------------------------------------------------------------------------------

sub create {
    my ($self, %args) = @_;

    $self->controller->app->log->debug("NSDBG create transaction".Dumper(\%args));
    if ($self->transaction_number) {
        my $message = 'Transaction has already been loaded';
        $self->controller->app->log->error("$message [ROUTING]");
        return $self->controller->reply->exception($message);
    }

    my $api = $self->controller->ch_api;

    my $company_number = $self->controller->stash('company_number');

    my $transaction_data;

    # This call fails with a 404
    $self->controller->app->log->debug("NSDBG company [$company_number] create transaction ref api ".ref($api)." api:".Dumper($api));
    $self->controller->app->log->debug("NSDBG company [$company_number] ref transactions ".ref($api->transactions)." transactions:".Dumper($api->transactions));
    $api->transactions->create({
        company_number => $company_number,
        description => $self->controller->cv_lookup('filing_type', $self->metadata->{formtype}),
    })->on(
        'success' => sub {
            my ($api, $tx) = @_;

            $self->controller->app->log->debug("Transaction created " . Dumper($tx->res->json) . " [ROUTING]");
            $transaction_data = $tx->res->json;

            # Create transaction number
            $self->transaction_number($transaction_data->{'id'});

            $self->controller->session->{transaction}->{$self->transaction_number} = {};
            $self->_prepare_form_model;
            $args{callback}->();
        },
        error => sub {
            my ($api, $error) = @_;
            my $message = "Failed to create transaction: $error";
            $self->controller->app->log->error("$message [ROUTING]");
            $self->controller->reply->exception($message);
        },
        failure => sub {
            my ($api, $tx) = @_;
            my $code = $tx->res->code // 0;

            if ( !$code or $code == 500) {
                my $message = 'Status 500. Failed to create transaction: '.$tx->error->{message};
                $self->controller->app->log->error("$message [API]");
                return $self->controller->reply->exception($message);
            }

            if ($code == 400) {
                # If validation for the TransactionCreate model fails, we get a 400 back from the API.
                # Render an exception if validation does fail, its our fault.
                my $message = 'Status 400. Failed to create transaction: '.$tx->error->{message};
                $self->controller->app->log->error("$message [ROUTING]");
                return $self->controller->reply->exception($message);
            }

            my $message = 'Status '.$code.'. Failed to create transaction. Unexpected response from API: '.$tx->error->{message};
            $self->controller->app->log->error("$message [API]");
            return $self->controller->reply->exception($message);
        },
    )->execute;

    return;
}

#-------------------------------------------------------------------------------

sub get_start_url {
    my ($self) = @_;

    my $url = $self->controller->base_url . join( '/',
        'company',
        $self->controller->stash('company_number'),
        'transactions',
        $self->transaction_number,
        $self->endpoint
    );

    return $url;
}

#-------------------------------------------------------------------------------

sub load {
    my ($self) = @_;

    unless ($self->transaction_number) {
        my $message = 'Transaction number is undefined';
        $self->controller->app->log->error("$message [ROUTING]");
        $self->controller->reply->exception($message);
        return undef;
    }

    $self->_prepare_form_model unless $self->endpoint eq 'confirmation';

    $self->controller->app->log->debug("Transaction endpoint hash is valid, continuing route to transaction [ROUTING]");

    return 1;
}

# ------------------------------------------------------------------------------

sub _prepare_form_model {
    my ($self) = @_;

    # Retrieve (or create) the model
    if(!$self->model) {
        $self->controller->app->log->debug("Preparing model [ROUTING]");

        my $type = $self->metadata->{model_class};
        eval "require $type" or CH::Exception->throw("Unable to load model $type");

        # Try and get it back from memcached
        #$self->model($self->controller->retrieve_model($self->controller->stash('data_adapter')));
        # FIXME try and get this from the API

        # If we didn't get anything back, create a new one
        if(!$self->model) {
            $self->controller->app->log->debug("Creating new instance of model [ROUTING]");
            $self->model($type->new( data_adapter => $self->controller->stash('data_adapter'),
                                      %{ $self->controller->stash('model_args') // {} } ));
            my $class = camelize($self->metadata->{controller});
            $class = "ChGovUk::Controllers::".$class;
            $class->model_preload($self->model) if $class->can('model_preload');
            $self->controller->stash( form_model_is_new => true );
            $self->controller->session( form_type_hack => $self->metadata->{formtype} );
        } else {
            $self->controller->app->log->debug("Model retrieved from memcached [ROUTING]");
        }
    }
    else {
        debug "Model exists in stash" [ROUTING];
    }
}

# ------------------------------------------------------------------------------

sub submit {
    my ($self, %args) = @_;

    #Call submit on this class if the method exists
    #Get the relevant controller class for this submission
    my $class = camelize($self->metadata->{controller});
    $class = "ChGovUk::Controllers::".$class;
    if( $class->can('submit') ){
        $class->submit($self); # TODO Check this
    }

    my $company_number = $self->controller->stash('company_number');
    my $company     = $self->controller->ch_api->company($company_number);
    my $transaction = $self->controller->ch_api->transactions( $self->controller->stash('transaction_number') );

    $self->model->update_api( $transaction )->on(
        'success' => sub {
            my ($api, $tx) = @_;

            $self->controller->app->log->debug("Transaction updated " . Dumper($tx->res->json) . " [ROUTING]");

            # TODO deal with payment
            if($self->has_state) {
                delete $self->controller->session->{transaction}->{$self->transaction_number};
            }

            # now we've updated the model, we close the transaction
            $transaction->update( { status => 'closed' } )->on(
                success => sub {
                    $self->controller->app->log->debug("Successfully closed transaction " . $transaction->transaction_number . " [ROUTING]");
                    $args{on_success}->();
                },
                error => sub {
                    my ($api, $error) = @_;
                    my $message = 'Error closing transaction '.$transaction->transaction_number.': '.$error;
                    $self->controller->app->log->error("$message [ROUTING]");
                    $self->controller->reply->exception($message);
                },
                failure => sub {
                    my ($api, $tx) = @_;
                    my $code = $tx->res->code // 0;

                    if ( !$code or $code == 500 ) {
                        $self->controller->app->log->error("Failed to close transaction number [" . $transaction->transaction_number . "]: " . $tx->error->{message} . " [API]");
                        return $self->controller->reply->exception('Failed to close transaction [%d]', $transaction->transaction_number);
                    }

                    if ($code == 404) {
                        $self->controller->app->log->warn("Failed to close transaction " . $transaction->transaction_number . ": " . $tx->error->{message} . " [ROUTING]");
                        return $self->controller->reply->not_found;
                    }

                    $self->controller->app->log->warn("Failed to update transaction " . $transaction->transaction_number . ": " . $tx->error->{message} . " [ROUTING]");
                    return $self->controller->render('error', status => $code, error => 'transaction_not_open', check_your_filings => 'true');
                },
            )->execute;
        },
        error => sub {
            my ($api, $error) = @_;
            my $message = 'Failed to update transaction '.$transaction->transaction_number.': '.$error;
            $self->controller->app->log->error("$message [ROUTING]");
            $self->controller->reply->exception($message);
        },
        'failure' => sub {
            my ($api, $tx) = @_;
            my $code = $tx->res->code // 0;

            if ( !$code or $code == 500) {
                my $message = 'Failed to update transaction '.$transaction->transaction_number.': '.$tx->error->{message};
                $self->controller->app->log->error("$message [API]");
                return $self->controller->reply->exception($message);
            }

            if ($code == 404) {
                $self->controller->app->log->warn("Failed to update transaction " . $transaction->transaction_number . ": " . $tx->error->{message} . " [ROUTING]");
                return $self->controller->reply->not_found;
            }

            if ($code == 400) {
                # Retrieve API errors and convert to a more usable form. API returns 400 (bad request) when validation fails
                my $errors = $self->controller->map_api_errors( $tx->res->json->{errors} );
                $self->controller->transform_api_errors( $errors, $self->model->get_api_map );
                $self->model->errors($errors);
                return $args{on_failure}->();
            }

            $self->controller->app->log->warn("Failed to update transaction " . $transaction->transaction_number . ": " . $tx->error->{message} . " [ROUTING]");
            return $self->controller->render('error', status => $code, error => 'transaction_not_open', check_your_filings => 'true');
        },
    )->execute;
}

# ------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;
