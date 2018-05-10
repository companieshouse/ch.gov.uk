package ChGovUk::Bridge::Company;

use CH::Perl;
use Mojo::Base 'Mojolicious::Controller';
use DateTime::Tiny;
use CH::Util::DateHelper qw(is_current_date_greater);

#-------------------------------------------------------------------------------

# Company profile page
sub company {
    my ($self) = @_;
    # Get the company number from the URL
    my (undef, $slash_company, $company_number) = split '/', $self->tx->req->url->path;

    trace "get company profile for: [%s]", $company_number [COMPANY PROFILE];

    my $api = $self->ch_api->company($company_number)->profile;
    $api->force_api_key unless $self->authorised_company eq $company_number;

    my $disable_previous_names = $self->config->{disable_previous_names};

    $api->get->on(
    #$self->ch_api->company($company_number)->profile->get->on(
        success => sub {
            my ($api, $tx) = @_;
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
            my $message = "Error retrieving company $company_number:$error";
            error "[%s]", $message [COMPANY PROFILE];
            $self->render_exception($message);
        }
    )->execute;

    return undef;
}

# ------------------------------------------------------------------------------


1;
