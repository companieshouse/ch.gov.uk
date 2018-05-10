package CH::Util::CountryCodes;

use Moose;
use CH::Perl;

# Public attributes
#
has 'language'            => ( is => 'ro', isa => 'Str',      lazy => 1, builder  => '_build_language', );
has 'codes'               => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder  => '_build_codes', );
has 'code_to_country_map' => ( is => 'ro', isa => 'HashRef',  lazy => 1, builder  => '_build_code_to_country_map', );
has 'country_to_code_map' => ( is => 'ro', isa => 'HashRef',  lazy => 1, builder  => '_build_country_to_code_map', );
has 'filter'              => ( is => 'ro', isa => 'Maybe[Regexp]',   lazy => 1, builder  => '_build_filter', );
has 'list_type'           => ( is => 'ro', isa => 'Str',      lazy => 1, builder  => '_build_list_type', );

# Private attributes
#
has '_language_country_data' => ( is => 'ro', isa => 'HashRef', lazy => 1, builder  => '_build_language_country_data', );
has '_language_eea_country_data' => ( is => 'ro', isa => 'HashRef', lazy => 1, builder  => '_build_language_eea_country_data', );

# Methods
#

sub code_for_country {
    my ( $self, $country ) = @_;

    my $code = undef;
    if ( defined $country ) {
        $country = lc $country;
        $country = 'united kingdom' if $country eq 'uk';
        $country = 'y deyrnas unedig' if $country eq 'y du';
        if ( exists $self->country_to_code_map->{ $country } ) {
            $code = $self->country_to_code_map->{ $country };
        }
    }
    return $code;
}

sub country_for_code {
    my ( $self, $code ) = @_;

    my $country =
        defined $code &&
        exists $self->code_to_country_map->{ $code } ?
        $self->code_to_country_map->{ $code } : undef;
    return $country;
}

# Builder methods
#

# Expect this to be set via the constructor but provide default
# May enhance this in future to allow language to be changed
sub _build_language {
    my ( $self ) = @_;

    my $language = 'en';
    return $language;
}

# Expect this to be set via the constructor but provide default
# default to undef
sub _build_list_type {
    my ( $self ) = @_;

    my $list_type = 'DEFAULT';

    return $list_type;
}

sub _build_filter {
    my ( $self ) = @_;

    my $filter = undef;
    return $filter;
}

sub _build_code_to_country_map {
    my ( $self ) = @_;

    my $code_to_country_map = uc $self->list_type eq 'EEA'
                                  ? $self->_language_eea_country_data->{ $self->language }
                                  : $self->_language_country_data->{ $self->language };

    if ( defined $self->filter ) {
        $code_to_country_map = {
            map {
                $_ =~ $self->filter # select codes which match the filter
                    ? ( $_ => $code_to_country_map->{$_} )
                    : ()
            } keys %$code_to_country_map
        };
    }

    return $code_to_country_map;
}

# Return hash with key of lowercase country and value of code
sub _build_country_to_code_map {
    my ( $self ) = @_;

    my $country_to_code_map = {
        map {
            lc $self->code_to_country_map->{ $_ } => $_
        } keys %{ $self->code_to_country_map }
    };
    return $country_to_code_map;
}

sub _build_codes {
    my ( $self ) = @_;

    my $codes = keys %{ $self->code_to_country_map };
    return $codes;
}

sub _build_language_country_data {
    my ( $self ) = @_;

    my $language_country_data = {
          # English
          'en' => {
                    # ISO 3166-1 Alpha-3 codes
                    'AUS' => 'Australia',
                    'AUT' => 'Austria',
                    'BEL' => 'Belgium',
                    'CAN' => 'Canada',
                    'CYP' => 'Cyprus',
                    'CZE' => 'Czech Republic',
                    'DEU' => 'Germany',
                    'DNK' => 'Denmark',
                    'ESP' => 'Spain',
                    'EST' => 'Estonia',
                    'FRA' => 'France',
                    'GBR' => 'United Kingdom',
                    'GRC' => 'Greece',
                    'HRV' => 'Croatia',
                    'HUN' => 'Hungary',
                    'IRL' => 'Ireland',
                    'ITA' => 'Italy',
                    'LTU' => 'Lithuania',
                    'NLD' => 'Netherlands',
                    'NOR' => 'Norway',
                    'NZL' => 'New Zealand',
                    'POL' => 'Poland',
                    'PRT' => 'Portugal',
                    'SWE' => 'Sweden',
                    'USA' => 'USA',
                    'ZAF' => 'South Africa',
                    # ISO 3166-2:GB codes
                    'GB-ENG' => 'England',
                    'GB-NIR' => 'Northern Ireland',
                    'GB-SCT' => 'Scotland',
                    'GB-WLS' => 'Wales',
                  },
          # Welsh
          'cy' => {
                    # ISO 3166-1 Alpha-3 codes
                    'AUS' => 'Awstralia',
                    'AUT' => 'Awstria',
                    'BEL' => 'Belg',
                    'CAN' => 'Canada',
                    'CYP' => 'Cyprus',
                    'CZE' => 'Gweriniaeth y Tsieciaid',
                    'DEU' => 'Yr Almaen',
                    'DNK' => 'Denmarc',
                    'ESP' => 'Sbaen',
                    'EST' => 'Estonia',
                    'FRA' => 'Ffrainc',
                    'GBR' => 'Y Deyrnas Unedig',
                    'GRC' => 'Groeg',
                    'HRV' => 'Croatia',
                    'HUN' => 'Hwngari',
                    'IRL' => 'Iwerddon',
                    'ITA' => 'Yr Eidal',
                    'LTU' => 'Lithwania',
                    'NLD' => 'Yr Iseldiroedd',
                    'NOR' => 'Norwy',
                    'NZL' => 'Seland Newydd',
                    'POL' => 'Pwyl',
                    'PRT' => 'Portiwgal',
                    'SWE' => 'Sweden',
                    'USA' => 'UDA',
                    'ZAF' => 'De Affrica',
                    # ISO 3166-2:GB codes
                    'GB-ENG' => 'Lloegr',
                    'GB-NIR' => 'Gogledd Iwerddon',
                    'GB-SCT' => 'Yr Alban',
                    'GB-WLS' => 'Cymru',
                  },
    };

    return $language_country_data;

}

sub _build_language_eea_country_data {
    my ( $self ) = @_;

    my $language_country_data = {
        # English
        'en' => {
            'AUT' => 'Austria',
            'BEL' => 'Belgium',
            'BGR' => 'Bulgaria',
            'CYP' => 'Cyprus',
            'CZE' => 'Czech Republic',
            'DNK' => 'Denmark',
            'ENG' => 'England',
            'EST' => 'Estonia',
            'FRA' => 'France',
            'FIN' => 'Finland',
            'DEU' => 'Germany',
            'GRC' => 'Greece',
            'HUN' => 'Hungary',
            'ISL' => 'Iceland',
            'IRL' => 'Ireland',
            'ITA' => 'Italy',
            'LVA' => 'Latvia',
            'LTU' => 'Lithuania',
            'LIE' => 'Liehtenstein',
            'LUX' => 'Luxembourg',
            'MLY' => 'Malta',
            'NLD' => 'Netherlands',
            'NIR' => 'Northern Ireland',
            'NOR' => 'Norway',
            'POL' => 'Poland',
            'PRT' => 'Portugal',
            'ROU' => 'Romania',
            'SCO' => 'Scotland',
            'SVK' => 'Slovakia',
            'SVN' => 'Slovenia',
            'ESP' => 'Spain',
            'SWE' => 'Sweden',
            'GBR' => 'United Kingdom',
            'WLS' => 'Wales',
        },
        'cy' =>{
            'AUT' => 'Awstria',
            'BEL' => 'Belg',
            'BGR' => 'Bulgaria',
            'CYP' => 'Cyprus',
            'CZE' => 'Gweriniaeth y Tsieciaid',
            'DNK' => 'Denmarc',
            'ENG' => 'Lloegr',
            'EST' => 'Estonia',
            'FRA' => 'Ffrainc',
            'FIN' => 'Finland',
            'DEU' => 'Yr Almaen',
            'GRC' => 'Groeg',
            'HUN' => 'Hwngari',
            'ISL' => 'Iceland',
            'IRL' => 'Iwerddon',
            'ITA' => 'Yr Eidal',
            'LVA' => 'Latvia',
            'LTU' => 'Lithwania',
            'LIE' => 'Liehtenstein',
            'LUX' => 'Luxembourg',
            'MLY' => 'Malta',
            'NLD' => 'Netherlands',
            'NIR' => 'Gogledd Iwerddon',
            'NOR' => 'Norwy',
            'POL' => 'Pwyl',
            'PRT' => 'Portiwgal',
            'ROU' => 'Romania',
            'SCO' => 'Yr Alban',
            'SVK' => 'Slovakia',
            'SVN' => 'Slovenia',
            'ESP' => 'Sbaen',
            'SWE' => 'Sweden',
            'GBR' => 'Y Deyrnas Unedig',
            'WLS' => 'Cymru',
        }
    };
    return $language_country_data;
}
# General methods
#
# Convenience method
# Return an array of code-country pairs
sub list {
    my ( $self, ) = @_;

    my $cctm = $self->code_to_country_map;
    my @codes = keys %{ $cctm };

    my @list = map {
        { $_ => $cctm->{$_} }
    } sort { # sort by country
        $cctm->{$a} cmp $cctm->{$b}
    } @codes;
    return @list;
}

__PACKAGE__->meta->make_immutable;

# -----------------------------------------------------------------------------

=head1 NAME

CH::Util::CountryCodes

=head1 SYNOPSIS

    use CH::Util::CountryCodes;

    my $codes = CH::Util::CountryCodes->new();

=head1 DESCRIPTION

Country codes

=head1 ATTRIBUTES

[[ATTRIBUTES]]

=head1 SEE ALSO

L<CH::Util::CountryCodes>

=cut

