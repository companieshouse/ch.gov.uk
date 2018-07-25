package ChGovUk::Controllers::Admin::Transaction;

use Mojo::Base 'Mojolicious::Controller';
use CH::Perl;
use JSON::XS;
use List::Util qw/first/;

#-------------------------------------------------------------------------------

sub search_by_company_number {
    my ($self) = @_;
    my $company_number = $self->stash->{company_number};

    return $self->render_exception('company number missing') unless (defined($company_number) && $company_number ne '');

    $self->render_later;

    $self->stash(search => $company_number);

    $self->ch_api->private->company($company_number)->transactions->get->on(
        success => sub {
            my ($api, $tx) = @_;

            my $company_transactions = $tx->success->json;
            if (defined($company_transactions)) {

                for my $doc (@{$company_transactions->{items}}) {
                    if ( defined $doc->{closed_at} ) {
                        $doc->{closed_at_date} = CH::Util::DateHelper->isodate_as_string($doc->{closed_at});
                        $doc->{closed_at_time} = CH::Util::DateHelper->isotime_as_string($doc->{closed_at})->strftime('%l:%M%P');
                    }
                }

                $self->stash(transactions => $company_transactions->{items});
                return $self->render;
            }
            else {
                $self->render_not_found;
            }
        },
        failure => sub {
            my ($api, $tx) = @_;
            my $error_code = $tx->error->{code} // 0;
            my $error_message = $tx->error->{message};

            if (defined $error_code and $error_code == 404) {
                error 'API returned [%s] for filings lookup by company number [%s]', $error_code, $company_number [ROUTING];
                return $self->render;
            }

            my $message = sprintf 'Failure occured getting filings by company number [%s] as admin [%s]', $company_number, $error_message;
            error $message [ROUTING];
            return $self->render_exception($message);
        },
        error => sub {
            my ($api, $error) = @_;

            my $message = sprintf 'Error occured getting filings by company number [%s] as admin [%s]', $company_number, $error;
            error $message [ROUTING];
            return $self->render_exception($message);
        }
    )->execute;
}

#-------------------------------------------------------------------------------

sub filing {
    my ($self) = @_;

    $self->render_later;

    my $transaction_id = $self->stash('transaction_number');

    $self->ch_api->transactions($transaction_id)->get->on(
        success => sub {
            my ($api, $tx) = @_;

            my $transaction = $tx->success->json;
            if (defined $transaction) {
                if ( defined $transaction->{closed_at} ) {
                        $transaction->{closed_at_date} = CH::Util::DateHelper->isodate_as_string($transaction->{closed_at});
                        $transaction->{closed_at_time} = CH::Util::DateHelper->isotime_as_string($transaction->{closed_at})->strftime('%l:%M%P');
                }

                $self->stash(transaction_id => $transaction->{id});
                $self->stash(transaction => $transaction);
                return $self->render;
            }
            else {
                $self->render_not_found;
            }
        },
        failure => sub {
            my ($api, $tx) = @_;
            my $error_code = $tx->error->{code} // 0;
            my $error_message = $tx->error->{message};

            if (defined $error_code and $error_code == 404) {
                error 'API returned [%s] for transaction [%s]', $error_code, $transaction_id [ROUTING];
                return $self->render;
            }

            my $message = sprintf 'Failure occured getting transaction [%s] as admin [%s]', $transaction_id, $error_message;
            error $message [ROUTING];
            return $self->render_exception($message);
        },
        error => sub {
            my ($api, $error) = @_;

            my $message = sprintf 'Error occured getting transaction [%s] as admin [%s]', $transaction_id, $error;
            error $message [ROUTING];
            return $self->render_exception($message);
        }
    )->execute;
}

#-------------------------------------------------------------------------------

sub transaction {
    my ($self) = @_;

    $self->render_later;

    my $transaction_id = $self->stash('transaction_number');

    # confirmation message for email_post and resubmit_post actions
    $self->stash(emailed     => 1) if $self->param('emailed');
    $self->stash(resubmitted => 1) if $self->param('resubmitted');

    $self->_get_transaction($transaction_id, sub {
        my ($transaction) = @_;

        $self->stash(transaction => $transaction);
        $self->render;
    });
}

#-------------------------------------------------------------------------------

# get transaction and call callback on success, passing it the transaction

sub _get_transaction {
    my ($self, $transaction_id, $callback) = @_;

    $self->ch_api->admin->transactions($transaction_id)->get->on(
        success => sub {
            my ($api, $tx) = @_;

            return $callback->($tx->success->json);
        },
        failure => sub {
            my ($api, $tx) = @_;
            my $error_code = $tx->error->{code} // 0;
            my $error_message = $tx->error->{message};

            if (defined $error_code and $error_code == 404) {
                error "Transaction [%s] - API returned 404: Transaction does not exist", $transaction_id [ADMIN TRANSACTION_LOOKUP];
                return $self->render_not_found;
            }

            my $message = sprintf 'Transaction [%s] - Failure occurred getting transaction as admin [%s]: [%s]', $transaction_id, $error_code, $error_message;
            error $message [ADMIN TRANSACTION_LOOKUP];
            return $self->render_exception($message);
        },
        error => sub {
            my ($api, $error) = @_;

            my $message = sprintf 'Transaction [%s] - Error occurred getting transaction as admin [%s]', $transaction_id, $error;
            error $message [ADMIN TRANSACTION_LOOKUP];
            return $self->render_exception($message);
        }
    )->execute;
}

#-------------------------------------------------------------------------------

sub _remove_barcode_from_filing {
    my ($self, $barcode, $callback) = @_;

    $self->ch_api->admin->filings($barcode)->update({
        barcode        => '',
        status         => 'in-progress'
    })->on(
        success => sub {
            my ($api, $tx) = @_;
            return $callback->();
        },
        failure => sub {
            my ($api, $tx) = @_;
            my $error_code = $tx->error->{code} // 0;
            my $error_message = $tx->error->{message};

            if (defined $error_code and $error_code == 404) {
                error "Barcode [%s] - API returned 404: Cannot update filing, barcode does not exist", $barcode [ADMIN TRANSACTION_RESUBMISSION];
                return $self->render_not_found;
            }

            my $message = sprintf 'Filing with barcode [%s] - Failure occurred getting filing as admin [%s]: [%s]', $barcode, $error_code, $error_message;
            error $message [ADMIN TRANSACTION_RESUBMISSION];
            return $self->render_exception($message);
        },
        error => sub {
            my ($api, $error) = @_;

            my $message = sprintf 'Filing with barcode [%s] - Error occurred getting filing as admin [%s]', $barcode, $error;
            error $message [ADMIN TRANSACTION_RESUBMISSION];
            return $self->render_exception($message);
        }
    )->execute;
}

#-------------------------------------------------------------------------------

sub transaction_json {
    my ($self) = @_;

    $self->render_later;

    my $transaction_id = $self->stash('transaction_number');

    my $delay = Mojo::IOLoop::Delay->new->data({ transaction_id => $transaction_id} );


    $delay->on(
           finish => sub {
               my ($delay) = @_;

               my $transaction = $delay->data('transaction');
               $self->stash(transaction_json => JSON::XS->new->pretty(1)->encode( $transaction ));
               $self->render;
           }
       );

       $delay->on(
           error => sub {
               my ( $delay ) = @_;
               $delay->data->{error}->{errcode} == 404 ? $self->render_not_found : $self->render_exception($delay->data->{error}->{errmessage});
           }
       );

    $self->_get_new_transaction($delay, $delay->begin(0));
}
#-------------------------------------------------------------------------------


sub resource_json {
    my ($self) = @_;

    $self->render_later;

    my ($transaction_id, $resource_name) = (
        $self->stash('transaction_number'),
        $self->stash('resource_name'),
    );

    $self->ch_api->admin->transactions($transaction_id)->resource($resource_name)->get->on(
        success => sub {
            my ($api, $tx) = @_;

            $self->stash(data_json => JSON::XS->new->pretty(1)->encode( $tx->success->json ));
            $self->render;
        },
        failure => sub {
            my ($api, $tx) = @_;
            my $error_code = $tx->error->{code} // 0;
            my $error_message = $tx->error->{message};

            if (defined $error_code and $error_code == 404) {
                error "Transaction [%s] - Resource [%s] not found", $transaction_id, $resource_name [ADMIN TRANSACTION_LOOKUP];
                return $self->render_not_found;
            }

            my $message = sprintf 'Transaction [%s] - Failure occurred getting resource [%s]: [%s]',
                $transaction_id, $resource_name, $error_message;
            error $message [ADMIN TRANSACTION_LOOKUP];
            return $self->render_exception($message);
        },
        error => sub {
            my ($api, $error) = @_;

            my $message = sprintf 'Transaction [%s] - Error occurred getting resource [%s]: [%s]', $transaction_id, $resource_name, $error;
            error $message [ADMIN TRANSACTION_LOOKUP];
            return $self->render_exception($message);
        }
    )->execute;

}

#-------------------------------------------------------------------------------
sub email_confirm {
    my ($self) = @_;

    $self->render_later;

    my $transaction_id = $self->stash('transaction_number');
    my $barcode        = $self->stash('barcode');

    $self->_get_transaction($transaction_id, sub {
        my ($transaction) = @_;

        my $status = $self->_get_filing_status_from_transaction($transaction, $barcode);

        if (defined $status && ($status eq 'accepted' || $status eq 'rejected')) {
            $self->stash( title => 'Resend ' . $status . ' email' );
            $self->render;
        }
        else {
            $self->render_not_found;
        }

    });
}

#-------------------------------------------------------------------------------

sub _get_filing_status_from_transaction {
    my ($self, $transaction, $barcode) = @_;

    my $filing = first { $_->{barcode} eq $barcode } @{ $transaction->{filings} };
    unless ($filing) {
        error "Transaction [%s] - No filings with barcode: [%s]", $transaction->{id}, $barcode [ADMIN TRANSACTION_LOOKUP];
        return;
    }
    return $filing->{status};
}

#-------------------------------------------------------------------------------

sub resubmit_confirm {
    my ($self) = @_;

    $self->render_later;

    my $transaction_id = $self->stash('transaction_number');
    my $barcode        = $self->stash('barcode');

    $self->_get_transaction($transaction_id, sub {
        my ($transaction) = @_;

        $self->stash('updated_at' => $transaction->{filings}->[0]->{updated_at});

        my $status = $self->_get_filing_status_from_transaction($transaction, $barcode);

        if (defined $status && $status ne 'accepted' && $status ne 'rejected') {
            $self->render;
        }
        else {
            $self->render_not_found;
        }
    });
}

#-------------------------------------------------------------------------------

sub email {
    my ($self) = @_;

    $self->render_later;

    my $transaction_id = $self->stash('transaction_number');
    my $barcode        = $self->stash('barcode');

    $self->_get_transaction($transaction_id, sub {
        my ($transaction) = @_;

        my $to             = $transaction->{creator}->{email};
        my $company_number = $transaction->{company_number};
        my $template       = $self->_get_filing_status_from_transaction($transaction, $barcode);

        if (! defined $template) {
            return $self->render_not_found;
        }

        my $subject        = 'Change of Registered Office Address ' . $template . ' for <: $company_name :>';

        $self->queue_api->email->create({
            to             => $to,
            transaction_id => $transaction_id,
            company_number => $company_number,
            subject        => $subject,
            template       => $template,
        })->on(
            success => sub {
                my ($api, $tx) = @_;

                audit "%s - %s - Requeued render email with template type: %s", $transaction_id, $barcode, $template;
                debug "Transaction [%s] - Queued [%s] email to: [%s]", $transaction_id, $template, $to [ADMIN EMAIL_RESEND];

                return $self->redirect_to( $self->url_for('admin_transaction')->query(emailed => 1) );
            },
            error => sub {
                my ($api, $tx) = @_;

                my $message = sprintf "Transaction [%s] - Error queuing [%s] email to [%s]: %s", $transaction_id, $template, $to, $tx->error->{message};
                error $message [ADMIN EMAIL_RESEND];
                return $self->render_exception($message);
            },
            failure => sub {
                my ($api, $tx) = @_;

                my $message = sprintf "Transaction [%s] - Failed to queue [%s] email to [%s]: %s", $transaction_id, $template, $to, $tx->error->{message};
                error $message [ADMIN EMAIL_RESEND];
                return $self->render_exception($message);
            },
        )->execute;
    });
}

#-------------------------------------------------------------------------------

sub resubmit {
    my ($self) = @_;

    my $transaction_id = $self->stash('transaction_number');
    my $barcode        = $self->stash('barcode');

    $self->render_later;

    if ($barcode){
        $self->_remove_barcode_from_filing($barcode, sub {
            $self->_fetch_transaction($transaction_id);
        });
    } else {
        $self->_fetch_transaction($transaction_id);
    }
}

#-------------------------------------------------------------------------------

sub _fetch_transaction {
    my ($self, $transaction_id) = @_;

    $self->_get_transaction($transaction_id, sub {
            my ($transaction) = @_;

            my $company_number = $transaction->{company_number};

            $self->queue_api->transaction->create({
                transaction_id => $transaction_id,
                company_number => $company_number,
            })->on(
                success => sub {
                    my ($api, $tx) = @_;

                    audit "%s - Requeued submission", $transaction_id;
                    debug "Resubmitted transaction [%s] for company [%s] - Queued", $transaction_id, $company_number [ADMIN TRANSACTION_RESUBMISSION];

                    return $self->redirect_to( $self->url_for('admin_transaction')->query(resubmitted => 1) );
                },
                error => sub {
                    my ($api, $tx) = @_;

                    my $message = sprintf "Transaction [%s] - Error queuing resubmitted transaction: %s", $transaction_id, $tx->error->{message};
                    error $message [ADMIN TRANSACTION_RESUBMISSION];
                    return $self->render_exeption($message);
                },
                failure => sub {
                    my ($api, $tx) = @_;

                    my $message = sprintf "Transaction [%s] - Failed to queue resubmitted transaction: %s", $transaction_id, $tx->error->{message};
                    error $message [ADMIN TRANSACTION_RESUBMISSION];
                    return $self->render_exception($message);
                },
            )->execute;
        });
}

#-------------------------------------------------------------------------------

sub submission_json {
    my ($self) = @_;

    $self->render_later;

    # Process the incoming parameters
    my $transaction_id = $self->param('transaction_id');
    my $submission_id = $self->param('submission_id');

    my $delay = Mojo::IOLoop::Delay->new->data({ transaction_id => $transaction_id, submission_id => $submission_id } );

    $delay->on(
        finish => sub {
            my ($delay) = @_;

            $self->stash(data_json => JSON::XS->new->pretty(1)->encode( $delay->data("resource") ));
            $self->render;
        }
    );

    $delay->on(
        error => sub {
            my ( $delay ) = @_;
            $delay->data->{error}->{errcode} == 404 ? $self->render_not_found : $self->render_exception($delay->data->{error}->{errmessage});
        }
    );

    $delay->steps(
        sub {
            my ($delay) = @_;
            $self->_get_new_transaction($delay, $delay->begin(0));
        },
        sub {
            my ($delay) = @_;
            $self->_get_filing_resource($delay, $delay->begin(0));
        }
    )->wait;
}

#-------------------------------------------------------------------------------
# Get transaction from Transaction API for new 'Your Filings'/'Account-site' page
sub _get_new_transaction {
    my ($self, $delay, $next) = @_;

    my $transaction_id = $delay->data('transaction_id');
    my $resource_link = "/transactions/" . $transaction_id;

    $self->ch_api->uri($resource_link)->get->on(
        success => sub {
            my ($api, $tx) = @_;
            
            trace "Transaction with id: " . $transaction_id . " retrieved";
            $delay->data->{transaction} = $tx->success->json;
            $next->();
        },
        failure => sub {
            my ($api, $tx) = @_;
            my $error_code = $tx->error->{code} // 0;
            my $error_message = $tx->error->{message};

            if (defined $error_code and $error_code == 404) {
                #error "Transaction [%s] - API returned 404: Transaction does not exist", $transaction_id [ADMIN TRANSACTION_LOOKUP];
                #return $self->render_not_found;
                trace "Transaction [%s] - API returned 404: Transaction does not exist", $transaction_id [ADMIN TRANSACTION_LOOKUP];
                $delay->data->{error} = { status => 'not_found', errcode => $error_code };
                $delay->emit('error');
            }

            error 'Transaction [%s] - Failure occurred getting transaction as admin [%s]: [%s]', $transaction_id, $error_code, $error_message;
            $delay->data->{error} = { status => 'exception', errmessage => $error_message };
            $delay->emit('error');

            #my $message = sprintf 'Transaction [%s] - Failure occurred getting transaction as admin [%s]: [%s]', $transaction_id, $error_code, $error_message;
            #error $message [ADMIN TRANSACTION_LOOKUP];
            #return $self->render_exception($message);
        },
        error => sub {
            my ($api, $error) = @_;

            error 'Transaction [%s] - Error occurred getting transaction as admin [%s]', $transaction_id, $error;
            $delay->data->{error} = { status => 'exception', errmessage => $error };
            $delay->emit('error');
            
            #my $message = sprintf 'Transaction [%s] - Error occurred getting transaction as admin [%s]', $transaction_id, $error;
            #error $message [ADMIN TRANSACTION_LOOKUP];
            #return $self->render_exception($message);
        }
    )->execute;
}

#-------------------------------------------------------------------------------

# Get resource by following link in transaction filing 
sub _get_filing_resource {
    my ($self, $delay, $next) = @_;

    my $transaction = $delay->data("transaction");
    my $submission_id = $delay->data("submission_id");
    my $resource_link;

    if (defined $transaction->{filings}) {
        $resource_link = $transaction->{filings}->{$submission_id}->{links}->{resource};
    } else {
        trace "Transaction [%s] - doesn't contain filings", $transaction [ADMIN TRANSACTION_LOOKUP];
        $delay->data->{error} = { status => 'not_found' };
        $delay->emit('error');
    }

    $self->ch_api->uri($resource_link)->get->on(
        success => sub {
            my ($api, $tx) = @_;

            my $resource = $tx->success->json;

            trace "Resource retrieved " . $resource_link;

            $delay->data->{resource} = $resource;

            my $resource_kind = $resource->{kind};
            if (defined $resource_kind and $resource_kind eq 'accounts') {
                $self->_get_accounts_submission_data($delay, $delay->begin(0));
            }

            $next->();
        },
        failure => sub {
            my ($api, $tx) = @_;

            my $error_code = $tx->error->{code} // 0;
            my $error_message = $tx->error->{message};

            if (defined $error_code and $error_code == 404) {
                error " Resource [%s] not found", $resource_link;
                $delay->data->{error} = { status => 'not_found', errcode => $error_code };
                $delay->emit('error');
            }

            error 'Failure occurred getting resource [%s]', $resource_link, $error_message;
            $delay->data->{error} = { status => 'exception', errcode => $error_code };
            $delay->emit('error');
        },
        error => sub {
            my ($api, $error) = @_;

            error 'Error occurred getting resource [%s]', $resource_link;
            $delay->data->{error} = { status => 'exception', error => $error};
            $delay->emit('error');
        }
     )->execute;
}

#-------------------------------------------------------------------------------

# Get abridged accounts document from Accounts API for new 'Your Filings'/'Account-site' page 
sub _get_accounts_submission_data {
    my ($self, $delay, $next) = @_;
    
    my $accounts = $delay->data("resource");
    my $resource_link;
    
    if ( defined $accounts->{links}->{abridged_accounts} ){
        $resource_link = $accounts->{links}->{abridged_accounts};
    } else {
       trace "Abridged accounts link missing on resource [%s]", $resource_link;
       $delay->data->{error} = { status => 'not_found', errmessage => "No abridged accounts link found"  };
       $delay->emit('error');
    }

    $self->ch_api->uri($resource_link)->get->on(
             success => sub {
                 my ($api, $tx) = @_;

                 my $abridged_accounts = $tx->success->json;

                 trace "Accounts document retrieved " . $resource_link;
             
                 $delay->data->{resource} = $abridged_accounts;
                 $next->();
                 #$self->stash(data_json => JSON::XS->new->pretty(1)->encode( $tx->success->json ));
                 #$self->render;
             },
             failure => sub {
                 my ($api, $tx) = @_;

                 my $error_code = $tx->error->{code} // 0;
                 my $error_message = $tx->error->{message};

                 if (defined $error_code and $error_code == 404) {
                    error " Resource [%s] not found", $resource_link;
                    $delay->data->{error} = { status => 'not_found', errcode => $error_code };
                    $delay->emit('error');
                 }

                 error 'Failure occurred getting resource [%s]', $resource_link, $error_message;
                 $delay->data->{error} = { status => 'exception', errcode => $error_code };
                 $delay->emit('error');
             },
             error => sub {
                 my ($api, $error) = @_;

                 error 'Error occurred getting resource [%s]', $resource_link;
                 $delay->data->{error} = { status => 'exception', error => $error};
                 $delay->emit('error');
             }
         )->execute;
}

#-------------------------------------------------------------------------------

1;
