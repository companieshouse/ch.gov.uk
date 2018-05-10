use Test::More;
use CH::Test;
use CH::Util::CountryCodes;

use Readonly;

Readonly my $CLASS => 'CH::Util::CountryCodes';

use_ok( $CLASS );

methods_ok(
    $CLASS,
    qw( 
        code_for_country country_for_code code_to_country_map country_to_code_map codes language
    ),
);

test_lookup_methods();

done_testing( );

#------------------------------------------------------------------------------

sub test_lookup_methods {

    subtest "Test lookup methods" => sub {

        my $test_data = {
            'en' => {
                'country_for_code' => {
                    'GBR'    => 'United Kingdom',
        			'GB-ENG' => 'England',
        	    },
                'code_for_country' => {
                    'Spain'       => 'ESP',
        			'New Zealand' => 'NZL',
        	    },
            },
            'cy' => {
                'country_for_code' => {
                    'NLD'    => 'Yr Iseldiroedd',
        			'GB-SCT' => 'Yr Alban',
        	    },
                'code_for_country' => {
                    'Gweriniaeth y Tsieciaid' => 'CZE',
        			'De Affrica'              => 'ZAF',
        	    },
            },
        };
        
        for my $language ( keys %{ $test_data } ) {
            
            my $country_codes = $CLASS->new( language => $language, );
            isa_ok( $country_codes, $CLASS );
        
        	my $method_set = $test_data->{ $language };

            for my $method ( keys %{ $method_set } ) {

        	    my $lookup_set = $method_set->{ $method };

        	    for my $lookup ( keys %{ $lookup_set } ) {
        	    	is( $country_codes->$method( $lookup ), $lookup_set->{ $lookup }, "Lookup $method '$lookup'" );
                }

            }
        
        }

    };
}
