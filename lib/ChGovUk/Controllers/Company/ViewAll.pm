package ChGovUk::Controllers::Company::ViewAll;

use Mojo::Base 'Mojolicious::Controller';
use CH::Perl;

  my @snapshot_not_available_company_types = (
    "assurance-company",
    "industrial-and-provident-society",
    "royal-charter",
    "investment-company-with-variable-capital",
    "charitable-incorporated-organisation",
    "scottish-charitable-incorporated-organisation",
    "uk-establishment",
    "registered-society-non-jurisdictional",
    "protected-cell-company",
    "protected-cell-company",
    "further-education-or-sixth-form-college-corporation",
    "icvc-securities",
    "icvc-warrant",
    "icvc-umbrella");

  my @certificate_orders_company_types = (
    "limited-partnership",
    "llp",
    "ltd",
    "plc",
    "old-public-company",
    "private-limited-guarant-nsc",
    "private-limited-guarant-nsc-limited-exemption",
    "private-limited-shares-section-30-exemption",
    "private-unlimited",
    "private-unlimited-nsc");

  my @dissolved_certificate_orders_company_types = (
      "llp",
      "ltd",
      "plc",
      "old-public-company",
      "private-limited-guarant-nsc",
      "private-limited-guarant-nsc-limited-exemption",
      "private-limited-shares-section-30-exemption",
      "private-unlimited",
      "private-unlimited-nsc");

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
  my $show_certificate = 0;
  my $show_certified_document = 1;
  my $show_dissolved_certificate = 0;

  my %snapshot_not_orderable = map { $_ => 1 } @snapshot_not_available_company_types;
  my %certificate_orderable = map { $_ => 1 } @certificate_orders_company_types;
  my %dissolved_certificate_orderable = map {$_ => 1 } @dissolved_certificate_orders_company_types;

  $show_snapshot = 0 if exists $snapshot_not_orderable{$company_type};
  $show_certificate = 1 if (
      $self->company_is_active($company_status)
      or $self->company_is_in_liquidation($company_type, $company_status)
      or $self->company_is_in_administration($company_type, $company_status)
  ) and exists $certificate_orderable{$company_type};
  $show_certified_document = 0 if $filing_history eq "" or ($filing_history ne "" and $company_type eq "uk-establishment");
  $show_dissolved_certificate = 1 if $self->company_is_dissolved($company_status) and exists $dissolved_certificate_orderable{$company_type};

  $self->stash(show_snapshot => $show_snapshot);
  $self->stash(show_certificate => $show_certificate);
  $self->stash(show_certified_document => $show_certified_document);
  $self->stash(show_dissolved_certificate => $show_dissolved_certificate);

  $self->stash_view_snapshot_event();

  my @flags = ($show_snapshot, $show_certificate, $show_certified_document, $show_dissolved_certificate);

  if ($self->should_render_more_tab_view(@flags)) {
    return $self->render(template => 'company/view_all/view');
  } else {
    return $self->render(template => 'not_found.production');
  }
}

#-------------------------------------------------------------------------------

sub should_render_more_tab_view {
  my ($self, @flags) = @_;

  for my $flag(@flags) {
    return 1 if $flag;
  }
  return 0;
}

#-------------------------------------------------------------------------------

sub company_is_active {
  my ($self, $company_status) = @_;

  return $company_status eq 'active';
}

#-------------------------------------------------------------------------------

sub company_is_in_liquidation {
  my ($self, $company_type, $company_status) = @_;

  return ($self->config->{feature}{order_liquidation_certificate}
      and $company_type ne 'limited-partnership'
      and $company_status eq 'liquidation');
}

#-------------------------------------------------------------------------------

sub company_is_in_administration {
  my ($self, $company_type, $company_status) = @_;

  return ($self->config->{feature}{order_administration_certificate}
      and $company_type ne 'limited-partnership'
      and $company_status eq 'administration');
}

#-------------------------------------------------------------------------------

sub company_is_dissolved {
  my ($self, $company_status) = @_;

  return $company_status eq 'dissolved';
}

#-------------------------------------------------------------------------------

sub stash_view_snapshot_event {
  my ($self) = @_;

  my $company_type = $self->stash->{company}->{type};
  my $view_snapshot_event = "View non-ROE company information snapshot";
  $view_snapshot_event = "View ROE company information snapshot" if ($company_type eq 'registered-overseas-entity');

  $self->stash(view_snapshot_event => $view_snapshot_event);
}

#-------------------------------------------------------------------------------

1;
