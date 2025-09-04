package ChGovUk::Bridge::Company;

use CH::Perl;
use Mojo::Base 'Mojolicious::Controller';
use DateTime::Tiny;
use CH::Util::DateHelper qw(is_current_date_greater);
use Time::HiRes qw(tv_interval gettimeofday);
use Scalar::Util qw(refaddr);

#-------------------------------------------------------------------------------

# Company profile page
sub company {
    my ($self) = @_;
    my $company_number = $self->stash('company_number') // '';

    trace "get company profile for: [%s]", $company_number [COMPANY PROFILE];
    if ( $company_number !~ /^[A-Z0-9]{8}$/ ) {
        error "Invalid company number format [%s] - return not found", $company_number [COMPANY PROFILE];
        $self->render_not_found;
        return undef;
    }


    my $api = $self->ch_api->company($company_number)->profile;
    $api->force_api_key unless $self->authorised_company eq $company_number;

    my $disable_previous_names = $self->config->{disable_previous_names};

    # Get the basket link for the user nav bar
    $self->get_basket_link;

    my $start = [Time::HiRes::gettimeofday()];
    debug "TIMING company.profile (company) '" . refaddr(\$start) . "'";
    $api->get->on(
        success => sub {
            my ($api, $tx) = @_;
            debug "TIMING company.profile (company) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
            trace "company profile for: [%s]: [%s]", $company_number, d:$tx->success->json [COMPANY PROFILE];
            my $results = $tx->success->json;
            $self->stash(company => $results);
            if ($results->{officer_summary}) {
                $results->{show_officer_summary} = 1;
            }
            unless ($disable_previous_names) {
                $results->{show_previous_names} = 1;
            }

            for my $item (@{ $results->{officer_summary}->{officers} }) {
                if ($item->{date_of_birth}) {
                    my $month = sprintf("%02s", $item->{date_of_birth}->{month});
                    my $year = $item->{date_of_birth}->{year};
                    if ($item->{date_of_birth}->{day}) {
                        my $day = sprintf("%02s", $item->{date_of_birth}->{day});
                        my $date = $year."-".$month."-".$day;
                        $item->{date_of_birth} = $date;
                        $item->{_authorised_dob} = 1;
                    } else {
                        my $date = $year."-".$month."-01";
                        $item->{date_of_birth} = $date;
                      }
                }
            }

            my  $file_accounts = $results->{accounts}->{next_accounts}->{period_end_on};
            if ($file_accounts) {  # just in case file_accounts is present, check it
                # TODO Once accounts has been released remove flag file_accounts_available_date
                my  $enable_file_accounts = $self->config->{file_accounts_available_date};
                if ($enable_file_accounts =~ /^\d{4}-\d{2}-\d{2}$/) {
                    # Verify if accounts are due
                    if (CH::Util::DateHelper->is_current_date_greater($enable_file_accounts) &&
                        CH::Util::DateHelper->is_current_date_greater($file_accounts)) {
                        $self->stash(file_accounts => 1);
                    }
                }
            }

            if (not $self->session->{signin_info}->{signed_in}) {
                trace 'user not signed in - not fetching monitor status';
                return $self->continue;
            }

            trace 'user signed in - fetching monitor status';

            if ( $self->config->{web_proxy}->{monitor_api} ) {
                $self->ua->proxy->http( $self->config->{web_proxy}->{monitor_api} );
                $self->ua->proxy->https( $self->config->{web_proxy}->{monitor_api} );
            }

            my $url  = sprintf '%s/following/%s', $self->config->{monitor}->{api_url}, $company_number;
            my $auth = $self->session->{signin_info}->{access_token}->{access_token};

            $self->ua->get($url => { Authorization => "Bearer $auth" } => sub {
                my ($ua, $tx) = @_;

                if ($tx->success && $tx->res->json) {
                    $self->stash(following_company => 1);
                }
                $self->continue;
            });
        },

        failure => sub {
            my ($api, $tx) = @_;
            debug "TIMING company.profile (company) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
            my $error_code = $tx->error->{code} // 0;
            my $error_message = $tx->error->{message};

            if ($error_code == 404) {
                trace "Company [%s] not found", $company_number [COMPANY PROFILE];
                # Should do more than this:
                return $self->render_not_found;
            } else {
                my $message = "Error ($error_code) retrieving company $company_number:$error_message";
                error "[%s]", $message [COMPANY PROFILE];
                return $self->render_exception($message);
            }
        },

        not_authorised => sub {
            debug "TIMING company.profile (company) not_authorised '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
            my $return_to = $self->req->url->to_string;
            # User is no longer considered authorised for ANYTHING!
            # TODO There should be a better way to nuke a users auth/identity values
            # — If we had a model of a user and a company then $user->nuke, $co->nuke.
            $self->access_token({});
            $self->user_profile({});
            $self->authorised_company('');
            trace "Company [%s] unauthorised. Redirecting to company login, with return_to: [%s]", $company_number, $return_to [COMPANY PROFILE];
            $self->redirect_to( $self->url_for('company_authorise')->query( return_to => $return_to ));
            return 0;
        },

        error => sub {
            my ($api, $error) = @_;
            debug "TIMING company.profile (company) error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
            my $message = "Error retrieving company $company_number:$error";
            error "[%s]", $message [COMPANY PROFILE];
            $self->render_exception($message);
        }
    )->execute;

    return undef;
}

sub get_basket_link {
    my ( $self ) = @_;
        if ($self->is_signed_in) {
        my $start = [Time::HiRes::gettimeofday()];
        debug "TIMING basket (company) '" . refaddr(\$start) . "'";
        $self->ch_api->basket->get->on(
            success        => sub {
                my ($api, $tx) = @_;
                debug "TIMING basket (company) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                my $json = $tx->success->json;
                my $show_basket_link = $json->{data}{enrolled} || undef;
                my $items = scalar @{$json->{data}{items} || []};
                if ($show_basket_link) {
                    debug "User [%s] enrolled for multi-item basket; displaying basket link", $self->user_id, [COMPANY_BRIDGE];
                }
                else {
                    debug "User [%s] not enrolled for multi-item basket; not displaying basket link", $self->user_id, [COMPANY_BRIDGE];
                }
                $self->stash_basket_link($show_basket_link, $items);
            },
            not_authorised => sub {
                my ($api, $tx) = @_;
                debug "TIMING basket (company) not_authorised '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                warn "User not authenticated; not displaying basket link", [COMPANY_BRIDGE];
                $self->stash_basket_link(undef, 0);
            },
            failure        => sub {
                my ($api, $tx) = @_;
                debug "TIMING basket (company) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                log_error($tx, "failure");
                $self->stash_basket_link(undef, 0);
            },
            error          => sub {
                my ($api, $tx) = @_;
                debug "TIMING basket (company) error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                log_error($tx, "error");
                $self->stash_basket_link(undef, 0);
            }
        )->execute;
    } else {
        $self->stash_basket_link(undef, 0);
    }
}

sub stash_basket_link {
    my ( $self, $show_basket_link, $basket_items ) = @_;

    $self->stash(
        show_basket_link => $show_basket_link,
        basket_items     => $basket_items
    );
}

sub log_error {
    my($tx, $error_type) = @_;

    my $error_code = $tx->error->{code} // 0;
    my $error_message = $tx->error->{message} // 0;
    my $error = (defined $error_code ? "[$error_code] " : '').$error_message;
    return if uc($error_type) eq 'FAILURE' && $error_code eq '404'; # don't log empty basket
    error "%s returned by getBasketLinks endpoint: '%s'. Not displaying basket link.", uc $error_type, $error, [COMPANY_BRIDGE];
}

# ------------------------------------------------------------------------------


1;
