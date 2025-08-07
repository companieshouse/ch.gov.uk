package ChGovUk::Controllers::Company::Branches;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::IOLoop;
use Mojo::IOLoop::Delay;
use Data::Dumper;

use CH::Perl;
use Time::HiRes qw(tv_interval gettimeofday);
use Scalar::Util qw(refaddr);

#-------------------------------------------------------------------------------

# Company branches page
sub view {
    my ($self) = @_;

    # Process the incoming parameters
    my $company_number = $self->param('company_number');

    # Get a list of branch companies for the requested company via the API
    my $start = [Time::HiRes::gettimeofday()];
    $self->app->log->debug("TIMING company.ukestablishments '" . refaddr(\$start) . "'");
    $self->ch_api->company($company_number)->ukestablishments()->get->on(
        success => sub {
            my ( $api, $tx ) = @_;
            $self->app->log->debug("TIMING company.ukestablishments success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
            my $results = $tx->res->json;
            #trace "related companies for %s: %s", $company_number, d:$results [company branches];
            $self->app->log->trace("related companies for $company_number: " . Dumper($results) . " [company branches]");

            # Add the number of branches to the stash
            $self->stash('number_of_branches' => scalar @{$results->{items}});
            # Add the number of branches with status 'open'
            $self->stash('number_of_branches_open' => scalar(grep { $_->{company_status} =~ /open/i } @{$results->{items}}) || 0);
            # Add the number of branches with status 'closed'
            $self->stash('number_of_branches_closed' => scalar(grep { $_->{company_status} =~ /closed/i } @{$results->{items}}) || 0);

            #trace "branches total %d open %d",
            #    $self->stash('number_of_branches'), $self->stash('number_of_branches_open') [COMPANY BRANCHES];
            $self->app->log->trace("branches total " . $self->stash('number_of_branches') . " open " . $self->stash('number_of_branches_open') . " [COMPANY BRANCHES]");

            $self->stash(branches => $results);
            $self->stash(company_number => $company_number);

            return $self->render;
        },
        failure => sub {
            my ( $api, $tx ) = @_;
            $self->app->log->debug("TIMING company.ukestablishments failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

            my ($error_code, $error_message) = (
                $tx->error->{code} // 0,
                $tx->error->{message},
            );

            #error "Failed to retrieve branches for %s: %s", $company_number, $error_message;
            $self->app->log->error("Failed to retrieve branches for $company_number: $error_message");
            return $self->render_exception("Failed to retrieve branches for company [$company_number]: $error_message");
        },
        error => sub {
            my ($api, $error) = @_;
            $self->app->log->debug("TIMING company.ukestablishments error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

            #error "Error retrieving branches list for %s: %s", $company_number, $error;
            $self->app->log->error("Error retrieving branches list for $company_number: $error");
            return $self->render_exception("Error retrieving company branches: $error");
        }
    )->execute;

    $self->render_later;
}

#--------------------------------------------------------------

1;
