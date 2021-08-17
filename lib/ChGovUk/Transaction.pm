package ChGovUk::Transaction;

use CH::Perl;
use Digest::SHA1 qw/ sha1_hex /;
use POSIX qw/ strftime /;
use CH::Util::CompanyPrefixes;
use Mojo::Util qw( camelize );
use Mojo::IOLoop;

use Moose;

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
    debug "Got transaction endpoint [%s]", $self->endpoint [ROUTING];

    # Get the current route (URL from map - e.g. /:char/:char2/:num/:num2)
    my $route = $self->controller->app->routes->find($self->controller->current_route)->pattern->pattern;
    $route = substr($route, 1) if substr($route, 0, 1) eq '/';
    $self->route($route);
    trace "Got transaction route [%s]", $route [ROUTING];

    # Get metadata
    $self->metadata($self->controller->get_transaction_metadata( endpoint => $self->route ));
    trace "Got transaction metadata:\n%s", d:$self->metadata [ROUTING];

    if($self->endpoint ne 'confirmation' && !$self->metadata) {
        ($route) = $route =~ /(.*)\/([^\/]+)$/;
        $self->route($route);
        trace "Got transaction endpoint [%s]", $self->endpoint [ROUTING];
        trace "Got transaction route [%s]", $route [ROUTING];

        $self->metadata($self->controller->get_transaction_metadata( endpoint => $self->route ));
    }

    if($self->has_state) {
        debug "Transaction [%s] has state:\n%s", $self->transaction_number, d:$self->controller->session->{transaction}->{$self->transaction_number} [ROUTING];
    } else {
        warn "Transaction [%s] has no state", $self->transaction_number [ROUTING];
    }
}

#-------------------------------------------------------------------------------

sub has_state {
    my ($self) = @_;

    my $has_state = exists($self->controller->session->{transaction}->{$self->transaction_number}) ? 1 : 0;
    debug "Transaction has_state [%s], state:\n%s", $has_state, d:$self->controller->session->{transaction}->{$self->transaction_number} [ROUTING];

    return $has_state;
}

#-------------------------------------------------------------------------------

sub create {
    my ($self, %args) = @_;

    if ($self->transaction_number) {
        my $message = 'Transaction has already been loaded';
        error "%s", $message [ROUTING];
        return $self->controller->render_exception($message);
    }

    my $api = $self->controller->ch_api;

    my $company_number = $self->controller->stash('company_number');

    my $transaction_data;

    $api->transactions->create({
        company_number => $company_number,
        description => $self->controller->cv_lookup('filing_type', $self->metadata->{formtype}),
    })->on(
        'success' => sub {
            my ($api, $tx) = @_;
            
            debug "Transaction created %s", d:$tx->res->json [ROUTING];
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
            error "%s", $message [ROUTING];
            $self->controller->render_exception($message);
        },
        failure => sub {
            my ($api, $tx) = @_;
            my $code = $tx->res->code // 0;

            if ( !$code or $code == 500) {
                my $message = 'Status 500. Failed to create transaction: '.$tx->error->{message};
                error "%s", $message [API];
                return $self->controller->render_exception($message);
            }

            if ($code == 400) {
                # If validation for the TransactionCreate model fails, we get a 400 back from the API.
                # Render an exception if validation does fail, its our fault.
                my $message = 'Status 400. Failed to create transaction: '.$tx->error->{message};
                error "%s", $message [ROUTING];
                return $self->controller->render_exception($message);
            }

            my $message = 'Status '.$code.'. Failed to create transaction. Unexpected response from API: '.$tx->error->{message};
            error "%s", $message [API];
            return $self->controller->render_exception($message);
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
        error "%s", $message [ROUTING];
        $self->controller->render_exception($message);
        return undef;
    }

    $self->_prepare_form_model unless $self->endpoint eq 'confirmation';

    debug "Transaction endpoint hash is valid, continuing route to transaction" [ROUTING];

    return 1;
}

# ------------------------------------------------------------------------------

sub _prepare_form_model {
    my ($self) = @_;

    # Retrieve (or create) the model
    if(!$self->model) {
        debug "Preparing model" [ROUTING];

        my $type = $self->metadata->{model_class};
        eval "require $type" or CH::Exception->throw("Unable to load model $type");

        # Try and get it back from memcached
        #$self->model($self->controller->retrieve_model($self->controller->stash('data_adapter')));
        # FIXME try and get this from the API

        # If we didn't get anything back, create a new one
        if(!$self->model) {
            debug "Creating new instance of model" [ROUTING];
            $self->model($type->new( data_adapter => $self->controller->stash('data_adapter'),
                                      %{ $self->controller->stash('model_args') // {} } )); 
            my $class = camelize($self->metadata->{controller});
            $class = "ChGovUk::Controllers::".$class;
            $class->model_preload($self->model) if $class->can('model_preload');
            $self->controller->stash( form_model_is_new => true );
            $self->controller->session( form_type_hack => $self->metadata->{formtype} );
        } else {
            debug "Model retrieved from memcached" [ROUTING];
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

            debug "Transaction updated %s", d:$tx->res->json [ROUTING];

            # TODO deal with payment
            if($self->has_state) {
                delete $self->controller->session->{transaction}->{$self->transaction_number};
            }

            # now we've updated the model, we close the transaction
            $transaction->update( { status => 'closed' } )->on(
                success => sub {
                    debug "Successfully closed transaction %s", $transaction->transaction_number [ROUTING];
                    $args{on_success}->();
                },
                error => sub {
                    my ($api, $error) = @_;
                    my $message = 'Error closing transaction '.$transaction->transaction_number.': '.$error;
                    error "%s", $message [ROUTING];
                    $self->controller->render_exception($message);
                },
                failure => sub {
                    my ($api, $tx) = @_;
                    my $code = $tx->res->code // 0;

                    if ( !$code or $code == 500 ) {
                        error "Failed to close transaction number [%s]:  %s", $transaction->transaction_number, $tx->error->{message} [API];
                        return $self->controller->render_exception('Failed to close transaction [%d]', $transaction->transaction_number);
                    }

                    if ($code == 404) {
                        warn "Failed to close transaction %s: %s", $transaction->transaction_number, $tx->error->{message} [ROUTING];
                        return $self->controller->render_not_found;
                    }

                    warn "Failed to update transaction %s: %s", $transaction->transaction_number, $tx->error->{message} [ROUTING];
                    return $self->controller->render('error', status => $code, error => 'transaction_not_open', description => "This transaction is no longer open", check_your_filings => 'true');
                },
            )->execute;
        },
        error => sub {
            my ($api, $error) = @_;
            my $message = 'Failed to update transaction '.$transaction->transaction_number.': '.$error;
            error "%s", $message [ROUTING];
            $self->controller->render_exception($message);
        },
        'failure' => sub {
            my ($api, $tx) = @_;
            my $code = $tx->res->code // 0;

            if ( !$code or $code == 500) {
                my $message = 'Failed to update transaction '.$transaction->transaction_number.': '.$tx->error->{message};
                error "%s", $message [API];
                return $self->controller->render_exception($message);
            }

            if ($code == 404) {
                warn "Failed to update transaction %s: %s", $transaction->transaction_number, $tx->error->{message} [ROUTING];
                return $self->controller->render_not_found;
            }

            if ($code == 400) {
                # Retrieve API errors and convert to a more usable form. API returns 400 (bad request) when validation fails
                my $errors = $self->controller->map_api_errors( $tx->res->json->{errors} );
                $self->controller->transform_api_errors( $errors, $self->model->get_api_map );
                $self->model->errors($errors);
                return $args{on_failure}->();
            }

            warn "Failed to update transaction %s: %s", $transaction->transaction_number, $tx->error->{message} [ROUTING];
            return $self->controller->render('error', status => $code, error => 'transaction_not_open', description => "This transaction is no longer open", check_your_filings => 'true');
        },
    )->execute;
}

# ------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;
