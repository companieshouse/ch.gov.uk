package ChGovUk::Controllers::Company::Registers;

use Mojo::Base 'Mojolicious::Controller';

use CH::Perl;
use Time::HiRes qw(tv_interval gettimeofday);
use Scalar::Util qw(refaddr);
use Mojo::IOLoop::Delay;
use Data::Dumper;

# -----------------------------------------------------------------------------

sub list {
    my ($self) = @_;

    $self->render_later;

    # Process the incoming parameters
    my $company_number = $self->param('company_number');

    my $delay = Mojo::IOLoop::Delay->new->data({ company_number => $company_number } );

    my $start = [Time::HiRes::gettimeofday()];
    $self->app->log->debug("TIMING registers list '" . refaddr(\$start) . "'");
    $delay->on(
        finish => sub {
            my ($delay) = @_;
            $self->app->log->debug("TIMING registers list finish '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

            $self->populate_stash($delay->data->{company_registers}, $delay->data->{members_pdf});
            $self->render( );
        }
    );

    $delay->on(
        error => sub {
            my ( $delay ) = @_;
            $self->app->log->debug("TIMING registers list error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
            $delay->data->{error}->{errcode} == 404 ? $self->reply->not_found : $self->render_exception($delay->data->{error}->{errmessage});
        }
    );

    $delay->steps(
        sub {
            my ($delay) = @_;
            $self->_get_company_registers($delay, $delay->begin(0));
        },
        sub {
            my ($delay) = @_;
            $self->_get_image_locations($delay, $delay->begin(0));
        },
        sub {
            my ($delay) = @_;
            $self->has_metadata($delay, $delay->begin(0));
        }
    )->wait;
}

# ------------------------------------------------------------------------------

sub _get_company_registers {
    my ($self, $delay, $next) = @_;

    my $company_number = $delay->data('company_number');

    my $start = [Time::HiRes::gettimeofday()];
    $self->app->log->debug("TIMING company.registers '" . refaddr(\$start) . "'");
    $self->ch_api->company($company_number)->registers->get->on(
        success => sub {
            my ($api, $tx) = @_;
            $self->app->log->debug("TIMING registers success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

            $delay->data->{company_registers} = $tx->res->json;
            $next->();
        },
        failure => sub {
          my ($api, $tx) = @_;
          $self->app->log->debug("TIMING company.registers failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

          my ($error_code, $error_message) = ($tx->error->{code} // 0, $tx->error->{message});

          if ($error_code == 404) {
              #trace "Register listing not found for company [%s]", $company_number [COMPANY REGISTER];
              $self->app->log->trace("Register listing not found for company [$company_number] [COMPANY REGISTER]");
              $delay->data->{error} = { status => 'not_found', errcode => $error_code };
          }
          else {
              #error "Failed to retrieve company register list for [%s]: [%s]", $company_number, $error_message [COMPANY REGISTER];
              $self->app->log->error("Failed to retrieve company register list for [$company_number]: [$error_message] [COMPANY REGISTER]");
              $delay->data->{error} = { status => 'exception', errcode => $error_code, errmessage => $error_message };
          }
          $delay->emit('error');
       },
       error => sub {
           my ($api, $error) = @_;
           $self->app->log->debug("TIMING company.registers error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

           #error "Error retrieving company register list for [%s]: [%s]", $company_number, $error [COMPANY REGISTER];
           $self->app->log->error("Error retrieving company register list for [$company_number]: [$error] [COMPANY REGISTER]");
           $delay->data->{error} = { status => 'exception', errmessage => $error };
           $delay->emit('error');
       }
    )->execute;
}

# ------------------------------------------------------------------------------

sub _get_image_locations {
    my ($self, $delay, $next) = @_;

    my $company_number = $delay->data('company_number');
    my $registers      = $delay->data('company_registers');

    # Each $register represents a register type
    for my $register ( keys %{ $registers->{registers} } ) {
        for my $item ( @{ $registers->{registers}->{$register}->{items} } ) {
            next if !exists $item->{links} or !defined $item->{links}->{filing};
            $self->_get_image_location($item, $delay, $delay->begin(0));
        }
    }

    $next->();
}

# ------------------------------------------------------------------------------

sub _get_image_location {
     my ( $self, $item, $delay, $next ) = @_;

     my $company_number = $delay->data('company_number');

     # FIXME Temporarily continue to use transaction_id until we can use the whole filing-history url
     my @parts = split( /\//, $item->{links}->{filing} );
     $item->{transaction_id} = $parts[4]; # splits into 4 parts because of the leading slash

     #trace "find transaction: [%s] for company [%s]", $item->{transaction_id}, $company_number [COMPANY REGISTER FILING];
     $self->app->log->trace("find transaction: [" . $item->{transaction_id} . "] for company [$company_number] [COMPANY REGISTER FILING]");

    my $start = [Time::HiRes::gettimeofday()];
    $self->app->log->debug("TIMING company.filing_history_item (image) '" . refaddr(\$start) . "'");
     $self->ch_api->company($company_number)->filing_history_item($item->{transaction_id})->get->on(
         success => sub {
             my ( $api, $tx ) = @_;
             $self->app->log->debug("TIMING company.filing_history_item (image) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
             my $filing_doc = $tx->res->json;

             if (defined $filing_doc->{links}->{document_metadata}) {
                 #trace "Successfully returned image location";
                 $self->app->log->trace("Successfully returned image location");
                 $item->{resource_url}   = $filing_doc->{links}->{document_metadata};
                 $item->{pages}          = $filing_doc->{pages};
             } else {
                 #warn "Resource does not have an image associated with transaction_id: [%s]", $item->{transaction_id} [COMPANY REGISTER FILING];
                 $self->app->log->warn("Resource does not have an image associated with transaction_id: [" . $item->{transaction_id} . "] [COMPANY REGISTER FILING]");
             }
             $next->();
          },
          failure => sub {
              my ( $api, $tx ) = @_;
              $self->app->log->debug("TIMING company.filing_history_item (image) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

              my ($error_code, $error_message) = ($tx->error->{code} // 0, $tx->error->{message});
              if ($error_code == 404) {
                  #warn "Filing history item not found for id [%s]", $item->{transaction_id} [COMPANY REGISTER FILING];
                  $self->app->log->warn("Filing history item not found for id [" . $item->{transaction_id} . "] [COMPANY REGISTER FILING]");
                  $next->();
              }
              else {
                  #error "Error retrieving company filing for [%s]: [%s]", $self->stash('company_number'), $error_message [COMPANY REGISTER FILING];
                  $self->app->log->error("Error retrieving company filing for [" . $self->stash('company_number') . "]: [$error_message] [COMPANY REGISTER FILING]");
                  $delay->data->{error} = { status => 'exception', errcode => $error_code, errmessage => $error_message };
                  $delay->emit('error');
              }
          },
          error => sub {
              my ($api, $error) = @_;
              $self->app->log->debug("TIMING company.filing_history_item (image) error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

              #error "Error retrieving company register list for [%s]: [%s]", $company_number, $error [COMPANY REGISTER];
              $self->app->log->error("Error retrieving company register list for [$company_number]: [$error] [COMPANY REGISTER]");
              $delay->data->{error} = { status => 'exception', errmessage => $error };
              $delay->emit('error');
          }
     )->execute;
}

# ==============================================================================

sub has_metadata {
    my ($self, $delay, $next) = @_;

    my $results = $delay->data->{company_registers};
    my $company_number = $delay->data('company_number');

    if (defined $results->{registers}->{members} && $results->{registers}->{members}->{items}[0]->{register_moved_to} eq 'public-register' && defined $results->{registers}->{members}->{items}[0]->{links}) {
        my @parts = split( /\//, $results->{registers}->{members}->{items}[0]->{links}->{filing} );
        my $transaction_id = $parts[4];

        my $start = [Time::HiRes::gettimeofday()];
        $self->app->log->debug("TIMING company.filing_history_item (metadata) '" . refaddr(\$start) . "'");
        $self->ch_api->company($company_number)->filing_history_item($transaction_id)->get->on(
            success => sub {
                my ( $api, $tx ) = @_;
                $self->app->log->debug("TIMING company.filing_history_item (metadata) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
                my $filing_doc = $tx->res->json;

                if (defined $filing_doc->{links}->{document_metadata}) {
                    #trace "Metadata exists for transaction_id: [%s]", $transaction_id;
                    $self->app->log->trace("Metadata exists for transaction_id: [$transaction_id]");

                    $delay->data->{members_pdf} = 1;
                    $next->();
                } else {
                    #trace "Metadata does not exist for transaction_id: [%s]", $transaction_id;
                    $self->app->log->trace("Metadata does not exist for transaction_id: [$transaction_id]");
                    $next->();
                }
             },
             failure => sub {
                 my ( $api, $tx ) = @_;
                 $self->app->log->debug("TIMING company.filing_history_item (metadata) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

                 #warn "Failure finding transaction_id: [%s], error [%s]", $transaction_id, d:$tx->error->{message};
                 $self->app->log->warn("Failure finding transaction_id: [$transaction_id], error [" . Dumper($tx->error->{message}) . "]");
                 $next->()
             },
             error => sub {
                 my ($api, $error) = @_;
                 $self->app->log->debug("TIMING company.filing_history_item (metadata) error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

                 #warn "Error finding transaction_id: [%s], [%s]", $transaction_id, d:$error;
                 $self->app->log->warn("Error finding transaction_id: [$transaction_id], [$error]");
                 $next->();
             }
        )->execute;
    } else {
        $next->();
    }
}

# ------------------------------------------------------------------------------

sub populate_stash {
    my ( $self, $results, $members_pdf ) = @_;

    for my $key ( keys %{ $results->{registers} } ) {

        # If register type is members and is currently stored at the public register, we want to display the filing image
        # as part of the members link.
        if (defined $members_pdf && $key eq 'members') {
            $self->stash($key => {
                register_type    => $results->{registers}->{$key}->{register_type},
                members_pdf      => $results->{registers}->{$key}->{items}[0],
                items            => $results->{registers}->{$key}->{items},
                register_link    => $results->{registers}->{$key}->{links}->{"${key}_register"},
                current_location => $results->{registers}->{$key}->{items}[0]->{register_moved_to},
                last_move        => $results->{registers}->{$key}->{items}[0]->{moved_on},
            });
        } else {
            $self->stash($key => {
                register_type    => $results->{registers}->{$key}->{register_type},
                items            => $results->{registers}->{$key}->{items},
                register_link    => $results->{registers}->{$key}->{links}->{"${key}_register"},
                current_location => $results->{registers}->{$key}->{items}[0]->{register_moved_to},
                last_move        => $results->{registers}->{$key}->{items}[0]->{moved_on},
            });
        }
    }
}

1;
