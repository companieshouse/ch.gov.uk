package ChGovUk::Controllers::Company::Branches;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::IOLoop;
use Mojo::IOLoop::Delay;

use CH::Perl;

#-------------------------------------------------------------------------------

# Company branches page
sub view {
    my ($self) = @_;

    # Process the incoming parameters
    my $company_number = $self->param('company_number');

    # Get a list of branch companies for the requested company via the API
    $self->ch_api->company($company_number)->ukestablishments()->get->on(
        success => sub {
            my ( $api, $tx ) = @_;
            my $results = $tx->success->json;
            trace "related companies for %s: %s", $company_number, d:$results [COMPANY BRANCHES];

            # Add the number of branches to the stash
            $self->stash('number_of_branches' => scalar @{$results->{items}});
            # Add the number of branches with status 'open' 
            $self->stash('number_of_branches_open' => scalar(grep { $_->{company_status} =~ /open/i } @{$results->{items}}) || 0);
            # Add the number of branches with status 'closed' 
            $self->stash('number_of_branches_closed' => scalar(grep { $_->{company_status} =~ /closed/i } @{$results->{items}}) || 0);

            trace "branches total %d open %d",
                $self->stash('number_of_branches'), $self->stash('number_of_branches_open') [COMPANY BRANCHES];

            $self->stash(branches => $results);
            $self->stash(company_number => $company_number);

            return $self->render;
        },
        failure => sub {
            my ( $api, $tx ) = @_;

            my ($error_code, $error_message) = (
                $tx->error->{code} // 0,
                $tx->error->{message},
            );

            error "Failed to retrieve branches for %s: %s", $company_number, $error_message;
            return $self->render_exception("Failed to retrieve branches for company [$company_number]: $error_message");
        },
        error => sub {
            my ($api, $error) = @_;

            error "Error retrieving branches list for %s: %s", $company_number, $error;
            return $self->render_exception("Error retrieving company branches: $error");
        }
    )->execute;

    $self->render_later;
}

#--------------------------------------------------------------

1;
