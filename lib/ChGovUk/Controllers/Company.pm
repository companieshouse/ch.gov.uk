package ChGovUk::Controllers::Company;

use Mojo::Base 'Mojolicious::Controller';
use CH::Perl;
use MIME::Base64 qw(encode_base64url decode_base64url);
use CH::Util::CompanyPrefixes;

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
    $self->stash_gci_return_url($company);

    $self->render;
}

#-------------------------------------------------------------------------------

# Authorise to file for a company
sub authorise {
    my ($self) = @_;

    my $return = $self->param('return_to') // $self->req->headers->referrer // $self->base_url;

    trace "Sign in: CPL Set state for authorize_url to: %s", $return [ACCOUNT];

    my $scope = 'https://api.companieshouse.gov.uk/company/' . $self->stash('company_number');

    if ($self->stash('company_number') =~ /^(FC|NF|SF)\d{6}$/) {
        $scope = 'https://api.companieshouse.gov.uk/oversea-company/' . $self->stash('company_number');
    }

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

sub stash_gci_return_url {
    my ($self, $company) = @_;

    my $sessRef = $self->session;

    my $signInInfo = $sessRef->{signin_info};

    if ($signInInfo && $signInInfo->{acsp_number} && isDigitalLP($company)) {
      if ($sessRef->{csrf_token}) {
          my $csrf_token = $sessRef->{csrf_token};
          $self->stash(csrf_token => $csrf_token);
      }

      my $gciReturnUrl = $self->req->url->to_abs->path->to_abs_string;

      $sessRef->{extra_data}{gci_return_url} = $gciReturnUrl;
    }
}

sub isDigitalLP {
    my ($self, $company) = @_;

    return 0 unless ($company && $company->{type} eq "limited-partnership" 
      && coIsDigitalLP($company->{subtype}));

    return 1;
}

#-------------------------------------------------------------------------------
1;
