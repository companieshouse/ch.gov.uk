package ChGovUk::Controllers::Company::ViewAll;

use Mojo::Base 'Mojolicious::Controller';
use CH::Perl;

  my @snapshot_company_types = (
    "assurance-company",
    "industrial-and-provident-society",
    "royal-charter",
    "investment-company-with-variable-capital",
    "charitable-incorporated-organisation",
    "scottish-charitable-incorporated-organisation",
    "uk-establishment",
    "registered-society-non-jurisdictional",
    "protected-cell-company",
    "eeig",
    "protected-cell-company",
    "further-education-or-sixth-form-college-corporation",
    "icvc-securities",
    "icvc-warrant",
    "icvc-umbrella");

  my @orders_company_types = (
    "limited-partnership",
    "llp",
    "ltd",
    "plc",
    "old-public-company",
    "private-limited-guarant-nsc",
    "private-limited-guarant-nsc-limited-exemption",
    "private-limited-shares-section-30-exemption",
    "private-unlimited",
    "private-unlimited-nsc",
    "scottish-partnership");

  my @certified_orders_company_types = (
    "industrial-and-provident-society",
    "registered-society-non-jurisdictional",
    "industrial-and-provident-society",
    "royal-charter",
    "icvc-umbrella",
    "uk-establishment",
    "scottish-charitable-incorporated-organisation",
    "protected-cell-company",
    "charitable-incorporated-organisation");

#-------------------------------------------------------------------------------

# View All Tab
sub view {
  my ($self) = @_;

  my $company = $self->stash->{company};
  my $company_type = $company->{type};
  my $company_status = $company->{company_status};
  my $links = $company->{links};
  my $filing_history = $links->{filing_history};
  my $show_snapshot = 1;
  my $show_orders = 0;
  my $show_certified_document = 1;

  for (my $i=0; $i < @snapshot_company_types; $i++) {
    if ($company_type eq $snapshot_company_types[$i]) {
      $show_snapshot = 0;
    }
  }

  if ($company_status eq 'active') {
    for (my $j=0; $j < @orders_company_types; $j++) {
      if ($company_type eq $orders_company_types[$j]) {
        $show_orders = 1;
      }
    } 
  }

  for (my $j=0; $j< @certified_orders_company_types; $j++) {
    if ($company_type eq $certified_orders_company_types[$j] || $filing_history eq "") {
        $show_certified_document = 0;
    }
  }

  $self->stash(show_snapshot => $show_snapshot);
  $self->stash(show_orders => $show_orders);
  $self->stash(show_certified_document => $show_certified_document);

  if ($show_snapshot || $show_orders || $show_certified_document) {
    return $self->render(template => 'company/view_all/view');
  } else {
    return $self->render(template => 'not_found.production');
  }
}

#-------------------------------------------------------------------------------

1;