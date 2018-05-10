package CH::Util::AddressFieldValidate;

use CH::Perl;
use CH::Util::CVConstants qw( :CLASS :JURISDICTION );
use CH::Util::CompanyPrefixes;

my %pclu = (
'AB' => 'Scottish',
'DD' => 'Scottish',
'EH' => 'Scottish',
'FK' => 'Scottish',
'G0' => 'Scottish',
'G1' => 'Scottish',
'G2' => 'Scottish',
'G3' => 'Scottish',
'G4' => 'Scottish',
'G5' => 'Scottish',
'G6' => 'Scottish',
'G7' => 'Scottish',
'G8' => 'Scottish',
'G9' => 'Scottish',
'HS' => 'Scottish',
'IV' => 'Scottish',
'KA' => 'Scottish',
'KW' => 'Scottish',
'KY' => 'Scottish',
'ML' => 'Scottish',
'PA' => 'Scottish',
'PH' => 'Scottish',
'ZE' => 'Scottish',
'DG' => 'ScottishEnglish',
'NE' => 'ScottishEnglish',
'CA' => 'ScottishEnglish',
'TD' => 'ScottishEnglish',
'GY' => 'ChannelIsland',
'JE' => 'ChannelIsland',
'IM' => 'IsleOfMan',
'BT' => 'NorthernIreland',
'LL' => 'Welsh',
'NP' => 'Welsh',
'LD' => 'Welsh',
'LL' => 'Welsh',
'CF' => 'Welsh',
'SA' => 'Welsh',
'CH' => 'WelshEnglish',
'SY' => 'WelshEnglish',
'HR' => 'WelshEnglish',
);

# ------------------------------------------------------------------------------

sub postcountry {
    my ( $postcode ) = @_;

    my $pc12 = uc( substr($postcode,0, 2) );
    my $postcountry = $pclu{$pc12} ? $pclu{$pc12} : undef;
    return $postcountry;
}

# ------------------------------------------------------------------------------

# Return valid UK country codes in order of increasing geographic size
# Assumes a valid UK postcode eg validated by UK postcode lookup
sub uk_country_code {
    my ( $postcode ) = @_;

    my $map = {
        Scottish        => [ 'GB-SCT', 'GB-GBN', 'GBR', ],
        Welsh           => [ 'GB-WLS', 'GB-GBN', 'GBR', ],
        NorthernIreland => [ 'GB-NIR', 'GBR', ],
        ScottishEnglish => [ 'GB-GBN', 'GBR', ],
        WelshEnglish    => [ 'GB-GBN', 'GBR', ],
        ChannelIsland   => [ undef, ],
        IsleOfMan       => [ undef, ],
    };

    my $postcountry = postcountry( $postcode ) // '';
    my $uk_country_code = exists $map->{$postcountry} ? $map->{$postcountry} : [ 'GB-ENG', 'GB-GBN', 'GBR', ];
    return $uk_country_code;
}

# ------------------------------------------------------------------------------

sub postcode_country_validate {

    my ( $postcode, $cntry ) = @_;

    my $result = undef;
    my $postcountry = postcountry( $postcode );
    if ( $postcode =~ /^\s*([A-Z](?:[A-Z]?\d[A-Z\d]?))\s*(\d[A-Z]{2})\s*$/ ) # "A[A]N[A|N] NAA"
    # http://www.govtalk.gov.uk/gdsc/html/frames/PostCode.htm 
    # following is a tighter definition but still not complete
    #        if ( $postcode =~ /^\s*([A-PR-UWYZ][A-HK-Y\d](?:[A-HJKSTUW\d][ABEHMNPRVWXY\d]?)?)\s*(\d[ABD-HJLNP-UW-Z]{2})\s*$/ ) # "A[A]N[A|N] NAA"
        {
            $result = "postcode_country_mismatch" if (($cntry eq 'GB-SCT') && ($postcountry !~ /Scottish/)) ;
            $result = "postcode_country_mismatch" if (($cntry eq 'GB-WLS') && ($postcountry !~ /Welsh/)) ;
            $result = "postcode_country_mismatch" if (($cntry eq 'GB-NIR') && ($postcountry !~ /NorthernIreland/)) ;
            $result = "postcode_country_mismatch" if (($cntry eq 'GB-ENG') && ($postcountry =~ /NorthernIreland/)) ;
            $result = "postcode_country_mismatch" if (($cntry eq 'GB-ENG') && ($postcountry eq 'Scottish')) ;
            $result = "postcode_country_mismatch" if (($cntry eq 'GB-ENG') && ($postcountry eq 'Welsh')) ;
            $result = "postcode_country_mismatch" if (($cntry eq 'GB-ENG') && ($postcountry eq 'ChannelIsland')) ;
            $result = "postcode_country_mismatch" if (($cntry eq 'GB-ENG') && ($postcountry eq 'IsleOfMan')) ;
            $result = "postcode_country_mismatch" if (($cntry eq 'GB-GBN') && ($postcountry =~ /NorthernIreland/)) ;
            $result = "postcode_country_mismatch" if (($cntry eq 'GB-GBN') && ($postcountry eq 'ChannelIsland')) ;
            $result = "postcode_country_mismatch" if (($cntry eq 'GB-GBN') && ($postcountry eq 'IsleOfMan')) ;
            $result = "postcode_country_mismatch" if (($cntry eq 'GBR')    && ($postcountry eq 'ChannelIsland')) ;
            $result = "postcode_country_mismatch" if (($cntry eq 'GBR')    && ($postcountry eq 'IsleOfMan')) ;
        }
    else
    {
        $result = "postcode_bad_uk";
    }
    return $result;
}

# ------------------------------------------------------------------------------

sub country_jurisdiction_validate {

    my ( $object, $jurisdiction ) = @_;

    my $result = undef;

    my $postcountry = postcountry( $object->postcode );

    if ( $postcountry ne '' ) {
        if ( $jurisdiction == $CV::JURISDICTION::SCOTLAND )
        {
            if ( $postcountry ne 'Scottish' ) {
                $result = ( $postcountry eq 'ScottishEnglish'? 'postcode_warn_scottish': 'postcode_invalid_scottish' );
            }
        }
        elsif ( $jurisdiction == $CV::JURISDICTION::NORTHERN_IRELAND )
        {
            if ( $postcountry ne 'NorthernIreland' ) {
                $result = 'postcode_invalid_northern_ireland';
            }
        }
        elsif ( $jurisdiction == $CV::JURISDICTION::ENGLAND_AND_WALES )
        {
            if ( $postcountry ne 'Welsh' && $postcountry ne 'WelshEnglish' && $postcountry ne 'English' ) { # 'English' not currently in list
                $result = ( $postcountry eq 'ScottishEnglish' || $postcountry eq ''? 'postcode_warn_welsh_english': 'postcode_invalid_welsh_english' );
            }
        }
        elsif ( $jurisdiction == $CV::JURISDICTION::WALES )
        {
            if ( $postcountry ne 'Welsh' ) {
                $result = ( $postcountry eq 'WelshEnglish'? 'postcode_warn_welsh': 'postcode_invalid_welsh' );
            }
        }
        elsif ( $jurisdiction == $CV::JURISDICTION::ENGLAND )
        {
            if ( $postcountry ne 'English' ) { # 'English' not currently in list
                $result = ( $postcountry eq 'ScottishEnglish' || $postcountry eq 'WelshEnglish' || 
                        $postcountry eq ''? 'postcode_warn_english': 'postcode_invalid_english' );
            }
        }
        elsif ( $jurisdiction == $CV::JURISDICTION::UK )
        {
            if ( $postcountry ne 'Welsh' && $postcountry ne 'WelshEnglish' && 
                    $postcountry ne 'Scottish' && $postcountry ne 'ScottishEnglish' &&
                    $postcountry ne 'NorthernIreland' && $postcountry ne 'English' ) { # 'English' not currently in list
                $result = ( $postcountry eq ''? 'postcode_warn_uk': 'postcode_invalid_uk' );
            }
        }
        elsif ( $jurisdiction == $CV::JURISDICTION::EU )
        {
        }
        elsif ( $jurisdiction == $CV::JURISDICTION::FOREIGN_NON_EU )
        {
        }
        else {
            $result = 'unknown_jurisdiction'; # probably shouldn't happen
        }
    }

    return $result;
}

# ------------------------------------------------------------------------------

1;
