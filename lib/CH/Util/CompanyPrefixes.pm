package CH::Util::CompanyPrefixes;

use CH::Perl;
use CH::Util::CVConstants;
use Time::Local;
require Exporter;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);

@EXPORT = qw( coAllowedOrder coFormatNumber coIsArchived coGetPrefix coIsIrish coIsAssurance coIsCompany coIsWebFiler mapSelectionToPrefix coIsLLP coIsNI coNItoUK coUKtoNI coIsRecordsHeldAtCH coIsLP getCompanyCategory getCompanyCategoryByJurisdiction coHasNoSic);

#
# ----------------------------------------------------------------------------

# mappable company prefixes
my %coNiMapping = (
                  # NI to UK
                  'NILP'  => 'NL',
                  'FC'    => 'NF',
                  'NE'    => 'GN',
                  'IP'    => 'NP',
                  'CU'    => 'NO',
                  'NILLP' => 'NC',
                );

# -----------------------------------------------------------------------------
# Decide if we are allowed to order documents or not (depending on prefix)
#
sub coAllowedOrder
{
  my $cnumb = shift;

  return coCheckFeature( $cnumb, 'orddoc' );
}

# -----------------------------------------------------------------------------
sub isNumber
{
  $_ = shift;
  /^\s*\d+\.*\d*\s*$/
}

# -----------------------------------------------------------------------------

sub coGetPrefix
{
  my ($cnumb) = @_;
  my $allow = 0;

  $_ = substr( $cnumb,0,2 ); # Prefix
  /\d\d/ && do {$_ = "default" };

  return $_;
}

# -----------------------------------------------------------------------------

sub coFormatNumber
{
  my $cnumb=shift;
  unless ($cnumb) {return undef};

  my ( $prefix, $digits ) = ( $cnumb =~ /^\s*([[:alpha:]]{0,2})(\d+)/ ); # generic company number format
  if ( defined $digits ) {
      $cnumb = sprintf "%s%0*d", $prefix, (8-length($prefix)), $digits;
  }

  return uc $cnumb;
}

# -----------------------------------------------------------------------------
# generic test logic for coIs<Type> tests
sub coIsType
{
    my ( $cnumb, $pattern ) = @_;
    my $result = undef;

    if ( defined $cnumb && defined $pattern )
    {
        $result = ( $cnumb =~ qr($pattern)i? 1: 0 ); # case-insensitive
    }

    return $result;
}
# -----------------------------------------------------------------------------
sub coIsScottish_LLP
{
    return coIsType( $_[0], '^SO' );
}
# -----------------------------------------------------------------------------
sub coIsNorthernIrish_LLP
{
    return coIsType( $_[0], '^NC' );
#    return coIsType( $_[0], '^NC(?!000([0-4]|5([0-4]|5[0-4])))' ); # exclude NILLP's - values less than NC000555
}
# -----------------------------------------------------------------------------
sub coIsWalesEngland_LLP
{
    return coIsType( $_[0], '^OC' );
}
# -----------------------------------------------------------------------------
sub coIsScottish
{
    return coIsType( $_[0], '^SC' );
}
# -----------------------------------------------------------------------------
sub coIsNorthernIrish
{
    ##modified NI(non LLP)  so it will not match NILLP(for LLP)
    return coIsType( $_[0], '^(NI|R)\d+' );
}
# -----------------------------------------------------------------------------
sub coIsWalesEngland
{
    return coIsType( $_[0], '^\d\d' );
}
# -----------------------------------------------------------------------------
# map the screen selection to a company prefix
# passes selection through if no mapping exists ( since most mappings are the same )
sub mapSelectionToPrefix
{
    my $selection = $_[0];

    my $map_to_prefix = { EW => '', SC => 'SC', NI => 'NI', R0 => 'R', OC => 'OC', SO => 'SO', NC => 'NC' };

    return ( exists $map_to_prefix->{$selection} ?  $map_to_prefix->{$selection}: $selection );
}
# -----------------------------------------------------------------------------
# Given a status and dissolved date, returns true if company is archived.
#
# Returns false for any status other than 'D' (dissolved)
#
sub coIsArchived
{
  my( $status, $date ) = @_;

  my $archived = 0;

  # See if company was disolved before 31-12-1995
  #
  if ($status eq "D") {
    my $now = time();
    my $dec31_1995=timelocal(0,0,0,31,12 - 1,1995);
    my($year,$month,$day)=unpack("A4A2A2",$date);
    if($day == 0 || $month == 0 ||$year == 0) {
      warn "Some sort of problem with dissolved date (%s/%s/%s), skipping dissolved date check", $day, $month, $year [VALIDATION];
    } else {
      my $ddate = timelocal(0,0,0,$day,$month-1,$year);
      $archived = ($ddate < $dec31_1995) ? 1 : 0;
    }
  }

  return $archived;
}

# -----------------------------------------------------------------------------
sub coIsAssurance
{
  my $cnumb=shift;
  unless ($cnumb) { return undef };
  my $prefix = substr(uc $cnumb,0,2);
  return (($prefix eq 'AC' || $prefix eq 'SA' || $prefix eq 'NA') ? 1 : 0);
}
# -----------------------------------------------------------------------------
sub coIsIrish
{
  my $cnumb=shift;
  unless ($cnumb) { return undef };
  my $prefix = substr(uc $cnumb,0,2);
  return (($prefix eq 'R0' || $prefix eq 'NI' || $prefix eq 'NF' || $prefix eq 'NC'  || $prefix eq 'NZ'|| $prefix eq 'NP'|| $prefix eq 'NO' ) ? 1 : 0);
}

# -----------------------------------------------------------------------------
# Test for WebFiling companies
sub coIsCompany
{
    my $cnumb=shift;
    return ( coIsWalesEngland( $cnumb ) || coIsScottish( $cnumb ) || coIsNorthernIrish( $cnumb ) );
}

# -----------------------------------------------------------------------------
# Test for WebFiling LLPs
sub coIsLLP
{
    my $cnumb=shift;
    return ( coIsWalesEngland_LLP( $cnumb ) || coIsScottish_LLP( $cnumb ) || coIsNorthernIrish_LLP( $cnumb ) );
}

# -----------------------------------------------------------------------------
# Test for WebFiling companies and LLPs
sub coIsWebFiler
{
    my $cnumb=shift;
    return ( coIsCompany( $cnumb ) || coIsLLP( $cnumb ) );
}

# -----------------------------------------------------------------------------
sub coIsLP
{
  my $cnumb=shift;
  unless ($cnumb) { return undef };
  my $prefix = substr(uc $cnumb,0,2);
  return (($prefix eq 'LP' || $prefix eq 'NL' || $prefix eq 'SL' ) ? 1 : 0);
}

#-----------------------------------------------------------------------------

sub coHasNoSic
{
  my $cnumb=shift;
  unless ($cnumb) { return undef };
  my $prefix = substr(uc $cnumb,0,2);
  return (($prefix eq 'BR' || $prefix eq 'FC' || $prefix eq 'GS' || $prefix eq 'SF' || $prefix eq 'NF' || $prefix eq 'IC' || $prefix eq 'IP' || $prefix eq 'LP' || $prefix eq 'SF' || $prefix eq 'NF' || $prefix eq 'AC' || $prefix eq 'RC' || $prefix eq 'LP' || $prefix eq 'OC' || $prefix eq 'SP' || $prefix eq 'SA' || $prefix eq 'SR' || $prefix eq 'SL' || $prefix eq 'SI' || $prefix eq 'SO' || $prefix eq 'NO' || $prefix eq 'NA' || $prefix eq 'GE' || $prefix eq 'NR' || $prefix eq 'NF' || $prefix eq 'GN' || $prefix eq 'NV' || $prefix eq 'NL' || $prefix eq 'NC' || $prefix eq 'RO' || $prefix eq 'SG' || $prefix eq 'PC' || $prefix eq 'CE' || $prefix eq 'CS') ? 1 : 0);
}
#   -----------------------------------------------------------------------------

sub coIsNI
{
  my $cnumb=shift;
  unless ($cnumb) { return undef };
  my $prefix = substr(uc $cnumb,0,5);
  $prefix =~ s/\d+//g;
  return exists( $coNiMapping{$prefix} ) ? 1 : 0;
}

# -----------------------------------------------------------------------------
#  Return the mapped UK company number for the supplied Northern Ireland company number
#  or undef if company number not mapped

sub coNItoUK
{
  my $cnumb=shift;
  unless ($cnumb) { return undef };
  my $s_co = uc $cnumb;
  my $co = $s_co;

  $co =~ s/^(\D+)\d+\D*/$1/;
  return undef if !$co;

  if ( exists($coNiMapping{$co}) ) {
      $s_co =~ s/$co/$coNiMapping{$co}/e;
      return $s_co ? $s_co : undef;
  }

  return undef;
}

# -----------------------------------------------------------------------------
#  Return the mapped Northern Ireland company number for the supplied UK company number
#  or undef if company number not mapped

sub coUKtoNI
{
  my $cnumb=shift;
  unless ($cnumb) { return undef };
  my $coMap;
  my $s_co = uc $cnumb;
  my $co = $s_co;

  $co =~ s/^(\D+)\d+\D*/$1/;
  return undef if !$co;

  while ( my($key,$value) = each %coNiMapping ) {
      $coMap = $key if $co eq $value;
      last if $coMap;
  }
  if ( $coMap ) {
      $s_co =~ s/$co/$coMap/e;
      return $s_co ? $s_co : undef;
  }

  return undef;
}

# -----------------------------------------------------------------------------
#  Returns 1 if the company number is NI mappable, 0 if not

sub coIsMappable
{
  my $cnumb=shift;
  unless ($cnumb) { return undef };
  my $prefix2 = uc substr $cnumb, 0, 2;
  my $prefix3 = uc substr $cnumb, 0, 3;
  my $prefix4 = uc substr $cnumb, 0, 4;
  my $prefix5 = uc substr $cnumb, 0, 5;
  my $coMap;

  while ( my($key,$value) = each %coNiMapping ) {
      $coMap = $value if $prefix2 eq $key;
      $coMap = $key   if $prefix2 eq $value;
      $coMap = $value if $prefix3 eq $key;
      $coMap = $key   if $prefix3 eq $value;
      $coMap = $value if $prefix4 eq $key;
      $coMap = $key   if $prefix4 eq $value;
      $coMap = $value if $prefix5 eq $key;
      $coMap = $key   if $prefix5 eq $value;
      return 1 if $coMap;
  }

  return 0;
}

# -----------------------------------------------------------------------------
#  Returns 1 if the company, are held at Companies House, 0 if not

sub coIsRecordsHeldAtCH
{
  my $cnumb=shift;
  unless ($cnumb) { return undef };
  my $prefix = coGetPrefix( $cnumb );
  return 0 if $prefix eq 'NO';
  return 0 if $prefix eq 'NW';
  return 0 if $prefix eq 'SI';
  return 0 if $prefix eq 'RO';
  return 0 if $prefix eq 'NP';
  return 0 if $prefix eq 'SP';
  return 0 if $prefix eq 'IP';
  return 0 if $prefix eq 'FC';
  return 0 if $prefix eq 'RC';
  return 0 if $prefix eq 'IC';
  return 0 if $prefix eq 'PC';

  return 1;
}

# -----------------------------------------------------------------------------

sub getCompanyCategory
{
  my $cnumb = shift;
  unless ($cnumb) { return undef };
#  my $prefix = coGetPrefix( $cnumb );
  my $category;
  $category = $CV::COMPANYCAT::ENGLAND_WALES if coIsWalesEngland ( $cnumb );
  $category = $CV::COMPANYCAT::SCOTLAND      if coIsScottish     ( $cnumb );
  $category = $CV::COMPANYCAT::IRELAND       if coIsNorthernIrish( $cnumb );
  $category = $CV::COMPANYCAT::OTHER unless $category;
  return $category;
}

# -----------------------------------------------------------------------------

sub getCompanyCategoryByJurisdiction
{
  my $jurisdictionCV = shift;
  unless ($jurisdictionCV) { return undef };

  return $CV::COMPANYCAT::ENGLAND_WALES if ( $jurisdictionCV == $CV::JURISDICTION::ENGLAND_AND_WALES );
  return $CV::COMPANYCAT::ENGLAND_WALES if ( $jurisdictionCV == $CV::JURISDICTION::WALES );
  return $CV::COMPANYCAT::SCOTLAND      if ( $jurisdictionCV == $CV::JURISDICTION::SCOTLAND );
  return $CV::COMPANYCAT::IRELAND       if ( $jurisdictionCV == $CV::JURISDICTION::NORTHERN_IRELAND );
  return $CV::COMPANYCAT::OTHER;
}
# -----------------------------------------------------------------------------

1;
# end
