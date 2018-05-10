use strict;
use Test::More;
use CH::Test;
use ChGovUk::Models::DataAdapter;

use Readonly;
Readonly my $CLASS => 'CH::Util::AddressFieldValidate';

use_ok $CLASS;

    isa_ok $CLASS, 'CH::Util::AddressFieldValidate';

    methods_ok $CLASS, qw(
                    postcode_country_validate
                    country_jurisdiction_validate
                );

    test_postcode_country_validate();
    test_country_jurisdiction_validate();
    test_uk_country_code();

done_testing();
exit(0);

# ==============================================================================

sub test_postcode_country_validate {
    subtest "Test method postcode_country_validate" => sub {

        # TODO: More tests to add.
    
        my $result = CH::Util::AddressFieldValidate::postcode_country_validate( 'EH3 9FF', 'GBR' );
        is($result, undef, 'Correct post code');
    
        $result = CH::Util::AddressFieldValidate::postcode_country_validate( 'EH3 ', 'GBR' );
        isnt($result, undef, 'Incorrect postcode');
        is  ($result, 'postcode_bad_uk', 'correct message tag');
    
        $result = CH::Util::AddressFieldValidate::postcode_country_validate( '%^& ', 'GBR' );
        isnt($result, undef, 'Incorrect postcode - invalid characters');
        is  ($result, 'postcode_bad_uk', 'correct message tag');
    
        $result = CH::Util::AddressFieldValidate::postcode_country_validate( 'EH3 9FF', 'GB-WLS' );
        isnt($result, undef, 'Incorrect country/postcode combination');
        is  ($result, 'postcode_country_mismatch', 'correct message tag');

    };
    return;
}

# ============================================================================== 


sub test_country_jurisdiction_validate {
    subtest "Test country_jurisdiction_validate" => sub {

        # TODO: More tests to add.
    
        use_ok('ChGovUk::Models::Address');
        my $address = new ChGovUk::Models::Address(data_adapter => new ChGovUk::Models::DataAdapter);
    
        $address->postcode('CF14 3UZ');
    
        my $result = CH::Util::AddressFieldValidate::country_jurisdiction_validate( $address, 1 );
        is($result, undef, 'Correct post code / country of jurisdiction combination');
        
        $address->postcode('EH3 9FF');
    
        my $result = CH::Util::AddressFieldValidate::country_jurisdiction_validate( $address, 2);
        is($result, 'postcode_invalid_welsh', 'Incorrect post code / country of jurisdiction combination');
    
    };
    return;
}

# ============================================================================== 


sub test_uk_country_code {
    subtest "Test uk_country_code" => sub {

        my $test_data = {
            'GY9 3TA'  => undef,       # Channel Island
            'SA1 1SA'  => 'GB-WLS',    # Welsh
            'EH3 7HW'  => 'GB-SCT',    # Scottish
            'SW1A 1AA' => 'GB-ENG',    # English
            'BT4 3XX'  => 'GB-NIR',    # Northern Irish
            'DG11 2AT' => 'GB-GBN',    # Scottish-English
            'SY11 2SS' => 'GB-GBN',    # Welsh-English
            'IM1 3PW'  => undef,       # Isle of Man
        };

        for my $postcode ( keys %$test_data ) {

            my $uk_country_code = CH::Util::AddressFieldValidate::uk_country_code( $postcode )->[0];
            is($uk_country_code, $test_data->{$postcode}, 'Correct postcode to UK country code mapping for ' . $postcode);
        }
    
    };
    return;
}

# ============================================================================== 

__END__
