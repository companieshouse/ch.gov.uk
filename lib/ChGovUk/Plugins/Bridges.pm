package ChGovUk::Plugins::Bridges;

use CH::Perl;
use Mojo::Base 'Mojolicious::Plugin';
use Digest::SHA1 qw/ sha1_hex /;
use File::Temp qw( :POSIX );
use ChGovUk::Models::DataAdapter;
use ChGovUk::Transaction;
use ChGovUk::Models::Address;
use CH::MojoX::SignIn::Bridge::HijackProtect;
use Time::HiRes qw(tv_interval gettimeofday);
use Scalar::Util qw(refaddr);
use Data::Dumper;

has 'app';

# =============================================================================

sub register {
    my ($self, $app) = @_;

    $self->app($app);

    #trace "Setup the bridge that every request passes through" [ROUTING];
    $app->log->trace("Setup the bridge that every request passes through [ROUTING]");

    my $hijack = $app->routes->under->name('hijack_protect')->to( cb => \&CH::MojoX::SignIn::Bridge::HijackProtect::bridge );

    # Setup the bridge that every request passes through
    my $r = $hijack->under('/')->name('root')->to( cb => sub {
        my ($self) = @_;

        $self->stash( route_name => $self->current_route);

        # TODO: get session may be removed once we solve redirection loop (github issue #87)
        #trace 'session is %s', d:$self->session [ROUTING];
        $app->log->trace("Session is " . Dumper($self->session));

        if ( $self->param('postcode_hint') ){
            my @keys = grep { $_ if /^postcode_lookup\[(.*)\]$/ } @{$self->req->params};
            if ( my $key = $keys[0] ){
                # postcode_lookup[field[postcode]]
                my ($field) = $key =~ /^postcode_lookup\[([\w\[\]]+)\[postcode\]\]$/;
                my $postcode = $self->param($field .'[postcode]');
                #debug "Postcode lookup for field [%s], postcode [%s]", $field, $postcode [ROUTING];
                $app->log->debug("Postcode lookup for field [$field], postcode [$postcode] [ROUTING]");

                my $address_model = ChGovUk::Models::Address->new();
                my $maxlength = $address_model->rules->{postcode}->{maxlength};

                if (not length $postcode =~ s/\s//gr or length $postcode =~ s/\s//gr > $maxlength) {
                    #trace "Value set for postcode is more than [%s] or not set", $maxlength [ROUTING];
                    $app->log->trace("Value set for postcode is more than [$maxlength] or not set [ROUTING]");
                    $self->stash(postcode_lookup_failure => $field."[postcode]");
                    return 1;
                }

                my $start = [Time::HiRes::gettimeofday()];
                $self->app->postcode_lookup($postcode, sub {
		    $app->log->debug("TIMING After postcode lookup '" . refaddr(\$start) . "' duration: " . Time::HiRes::tv_interval($start));
                    my ($address) = @_;
                    #trace "Got result for postcode lookup:\n%s", d:$address [ROUTING];
                    $app->log->trace("Got result for postcode lookup:\n" . Dumper($address) . "[ROUTING]");

                    if ($address->{invalid_postcode}){
                        $self->stash( postcode_lookup_nomatch => $field."[postcode]" );
                    } elsif ($address->{postcode_error}){
                        $self->stash( postcode_error => $field."[postcode]" );
                    } else {
                        $self->param($field . '[postcode]' => $address->{postcode}     // 0);
                        $self->param($field . '[line_1]'   => $address->{addressLine1} // 0);
                        $self->param($field . '[line_2]'   => $address->{addressLine2} // 0);
                        $self->param($field . '[town]'     => $address->{postTown}     // 0);

                        my $country = defined $address->{country}
                            ? CH::Util::CountryCodes->new->country_for_code($address->{country})
                            : 0;

                        $self->param($field . '[country]' => $country);
                    }

                    $self->continue;
                });

                return undef;
            }

            return 1;
        }
        elsif ( $self->param('file_upload_hint') ){
            #debug "Inside file upload hint" [FILE];
            $app->log->debug("Inside file upload hint [FILE]");
            my @keys = grep { $_ if /^file_(upload|delete)\[(.*)\]$/ } @{$self->req->params};
            if ( my $key = $keys[0] ){

                my ($type, $field) = $key =~ /^file_(upload|delete)\[(.*)\]$/;
                if ( $type eq 'upload' ){
                    my $file = $self->param($field);

                    if (!($file->filename)) { #Display error message if no file selected
                        $self->stash( file_upload_required => $field );
                        $self->param($field => 0);
                        return 1;
                    }

                    my $size = $file->size;
                    my $tmp_file_name = tmpnam();
                    my $tmp_file_location = $self->app->home . $tmp_file_name;
                    #debug "file=[%s] temp-file=[%s]", $file->filename, $tmp_file_location [FILE];
                    $app->log->debug("file=[" . $file->filename . "] temp-file=[" . $tmp_file_location ."] [FILE]");

                    $file->move_to($tmp_file_location);

                    $self->session('file_upload' => []) if !$self->session('file_upload');
                    # Index needs to start from 1 because having a 0 with the file_upload
                    # param is evaluated as false instead of 0 value in formHelper.
                    my $index = scalar @{$self->session('file_upload')};
                    $index++;
                    push @{$self->session('file_upload')},  {
                        filename => $file->filename,
                        tmpfile  => $tmp_file_name,
                        filesize => $size,
                        index    => $index,
                        content_type => $file->headers->content_type,
                    };

                    # Store the index at this point because we don't have a transaction number
                    # until a later bridge ( and we might not even be in a transaction )
                    $self->stash(transient_file_upload_index => $index);
                    $self->param($field => $index);
                }
                else {
                    my $index = $self->param("file_upload");
                    my @file_index = @{$self->session('file_upload')};
                    my %file_info =  %{$file_index[$index - 1]};

                    my $tmp_file = $file_info{tmpfile};
                    my $tmp_file_location = $self->app->home . $tmp_file;
                    unlink $tmp_file_location or $app->log->error("Could not delete [$tmp_file] [FILE]");

                    $self->session->{file_upload}->[$index - 1] = undef;
                    $self->param($field => 0);
                }
            }
            return 1;
        } else {
            return 1;
        }
    } );

    # Setup user authentication bridge
    # Any routes off this bridge require a valid user session
    $r->under('/')->name('user_auth')->to( cb => sub {
        my ($self) = @_;

        if( ! $self->is_signed_in ) {
            # TODO should use named route
            my $return_to = $self->req->headers->referrer . ',' . scalar $self->req->url;
            #debug "User authentication bridge - user not logged in, redirecting to login with return_to[%s]", $return_to [ROUTING];
            $app->log->debug("User authentication bridge - user not logged in, redirecting to login with return_to[$return_to] [ROUTING]");
            $self->redirect_to( $self->url_for('user_sign_in')->query( return_to => $return_to) );
            return 0;
        }

        #trace "User authentication bridge - user logged in, continuing route" [ROUTING];
        $app->log->trace("User authentication bridge - user logged in, continuing route [ROUTING]");
        return 1;
    } );

    my $company = $r->under('/company/:company_number')->name('company')->to('bridge-company#company');

    # Setup company authentication bridge
    # Any routes off this bridge require a valid company session
    my $start = [Time::HiRes::gettimeofday()];
    my $company_auth = $company->under('/')->name('company_auth')->to( cb => sub {
        my ($self) = @_;
        $app->log->debug("TIMING After company auth bridge '" . refaddr(\$start) . "' duration: " . Time::HiRes::tv_interval($start));
        #trace 'company  authentication bridge' [ROUTING];
        $app->log->trace("company authentication bridge [ROUTING]");
        my $company_number = $self->stash('company_number');

        # If user is signing out and we've hit an "you must be authorised" company page
        # redirect to the company profile
        if( $self->flash('signing_out') )
        {
            #trace "Signing out of company $company_number, directing to company profile";
            $app->log->trace("Signing out of company $company_number, directing to company profile");
            $self->redirect_to( $self->url_for('company_profile', company_number => $company_number) );
            return 0;
        }

        if ( !$self->user_id || $company_number ne $self->authorised_company) {
            my $return_to = $self->url_for('current')->to_abs;
            #debug "Company authentication bridge - company not logged in, redirecting to login with return_to[%s]", $return_to [ROUTING];
            $app->log->debug("Company authentication bridge - company not logged in, redirecting to login with return_to[$return_to] [ROUTING]");
            $self->redirect_to( $self->url_for('company_authorise')->query( return_to => $return_to) );
            return 0;
        }

        #trace "Company authentication bridge - company logged in, continuing route" [ROUTING];
        $app->log->trace("Company authentication bridge - company logged in, continuing route [ROUTING]");
        return 1;
    } );

    # Setup transaction bridge
    # Any routes off this bridge must include a form header from transaction#create handler
    my $transaction = $company_auth->under('transactions/:transaction_number')->name('transactions')->to( cb => \&_transaction_bridge );
    return;
}

sub _transaction_bridge{
    my ($self) = @_;
    my $transaction = ChGovUk::Transaction->new( controller => $self, transaction_number => $self->stash('transaction_number') );
    $self->stash(transaction => $transaction);

    my $loaded = $transaction->load; # May throw an exception

    if (defined $loaded){

        $self->ch_api->transactions( $self->stash('transaction_number') )->get->on(
            success => sub {
                my ($api, $tx) = @_;

                my $company_number = $self->stash('company_number');
                my $transaction = $tx->res->json;

                if ($company_number ne $transaction->{company_number}){
                    #trace "Transaction bridge - authenticated for company_number : [%s], transaction for company_number : [%s]", $company_number, $transaction->{company_number};
                    $self->app->log->trace("Transaction bridge - authenticated for company_number : [$company_number], transaction for company_number : [" . $transaction->{company_number} ."]");
                    return $self->reply->not_found;
                }

                my $destination = $self->stash->{transaction}->{route};
                my $status = $transaction->{status};

                if ( $destination eq 'change-registered-office-address' && ($self->stash('company'))->{registered_office_is_in_dispute} ){
                    #TODO: An empty transaction is created before this redirect will occur. It feels as though there should be a better way to do this.
                    #trace "ROA for company: [%s] is in dispute. Redirecting to help page. ", $company_number;
                    $self->app->log->trace("ROA for company: [$company_number] is in dispute. Redirecting to help page.");
                    return $self->redirect_to( '/help/replaced-address-help.html' );
                } elsif ( $status eq 'open' && $destination eq 'change-registered-office-address'){
                    #trace "Transaction bridge - Status [%s] matches destination [%s], continuing", $status, $destination;
                    $self->app->log->trace("Transaction bridge - Status [$status] matches destination [$destination], continuing");
                    return $self->continue;
                } elsif ( $status && $destination eq 'confirmation') {
                    #trace "Transaction bridge - Status [%s] matches destination [%s], continuing", $status, $destination;
                    $self->app->log->trace("Transaction bridge - Status [$status] matches destination [$destination], continuing");
                    return $self->continue;
                }

                #error "Transaction bridge - transaction closed: [%s]", $self->stash('transaction_number');
                $self->app->log->error("Transaction bridge - transaction closed: [" . $self->stash('transaction_number') . "]");
                return $self->render( 'error', status => 403, error => 'transaction_not_open' );

            },
            error => sub {
                my ($api, $error) = @_;
                my $message = "Error finding transaction: $error";
                #error "%s", $message [ROUTING];
                $self->app->log->error($message . " [ROUTING]");
                return $self->render_exception($message);
            },
            not_authorised => sub {
                my $return_to = $self->req->url->to_string;
                #trace "Company unauthorised. Redirecting to company login, with return_to: [%s]", $return_to [ROUTING];
                $self->app->log->trace("Company unauthorised. Redirecting to company login, with return_to: [$return_to] [ROUTING]");
                return $self->redirect_to( $self->url_for('company_authorise') . '?return_to=' . $return_to );
            },
            failure => sub {
                my ($api, $tx) = @_;
                my $code = $tx->res->code // 0;

                if(!$code or $code =~ /^5\d\d/) {
                    my $message = 'Status '.$tx->res->code.'. Failed to load transaction ['.$self->stash('transaction_number').']. Unexpected response from API: '.$tx->error->{message};
                    #error "%s", $message [ROUTING];
                    $self->app->log->error($message . " [ROUTING]");
                    return $self->render_exception($message);
                }

                if ($code == 404) {
                    #error "Transaction [%s] does not exist. Continuing.", $self->stash('transaction_number');
                    $self->app->log->error("Transaction [" . $self->stash('transaction_number') . "] does not exist. Continuing.");
                    return $self->render('error', error => "transaction_not_exist", description => "This transaction does not exist for this company", status => 404 );
                }

                #error "Failure fetching transaction: [%s] . Error: [%s].", $self->stash('transaction_number'), $tx->error->{message};
                $self->app->log->error("Failure fetching transaction: [". $self->stash('transaction_number') ."] . Error: [" . $tx->error->{message} . "].");
                return $self->render( 'error', status => $code, error => 'transaction_not_exist' );
            },
        )->execute;

        return undef;
    };
}


# -----------------------------------------------------------------------------

1;

=head1 NAME

ChGovUk::Plugins::Bridges

=head1 SYNOPSIS

    sub startup {
        ...
        $self->plugin('ChGovUk::Plugins::Bridges');
        ...
    }


=head1 DESCRIPTION

Defines a set of routing bridges to be used in the application

=head1 METHODS

=head2 [void] register( $app )

Called to register the plugin with the mojolicious framework

	@param   app  [object]     mojolicious application

=cut
