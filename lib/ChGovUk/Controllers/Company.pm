package ChGovUk::Controllers::Company;

use Mojo::Base 'Mojolicious::Controller';
use CH::Perl;
use MIME::Base64 qw(encode_base64url decode_base64url);

#-------------------------------------------------------------------------------

sub view {
    my ($self) = @_;

    my $company_number = $self->stash('company_number');
    my $company        = $self->stash('company');

    trace "display company profile for: %s", $company_number [COMPANY PROFILE];

    $self->stash_view_company_event();

    if ($company_number =~ /^(IP|SP|NP|NO|RS|SR|RC|NR|IC|SI|NV|AC|SA|NA|PC)\w{6}$/) {
        return $self->render(template => "company/partial_data_available/view");
    }

    $self->render;
}

#-------------------------------------------------------------------------------

# Authorise to file for a company
sub authorise {
    my ($self) = @_;

    my $return = $self->param('return_to') // $self->req->headers->referrer // $self->base_url;

    trace "Sign in: CPL Set state for authorize_url to: %s", $return [ACCOUNT];

    my $scope = 'https://api.companieshouse.gov.uk/company/' . $self->stash('company_number');

    my $destination = $self->oauth2_get_authorize_url(
                                    provider        => 'companies_house',
                                    state           => encode_base64url($return),
                                    scope           => $scope,
                                    company_number  => $self->stash('company_number'),
                                );

    $self->redirect_to($destination);
    return;
}

#-------------------------------------------------------------------------------

sub stash_view_company_event {
    my ($self) = @_;

    my $company_type = $self->stash->{company}->{type};
    my $view_company_event = "View non-ROE company";
    $view_company_event = "View ROE company" if ($company_type eq 'registered-overseas-entity');

    $self->stash(view_company_event => $view_company_event);
}

#-------------------------------------------------------------------------------
1;
