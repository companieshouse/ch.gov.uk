use Test::More;
use CH::Test;

use Readonly;
Readonly my $CLASS => 'CH::Util::ChargeNumber';

use_ok( $CLASS );

test_formatting();

done_testing();

exit(0);

# ==============================================================================

sub test_formatting {
    subtest "Test formatting" => sub {
        
        my @test_charge_numbers = (
            { unformatted => '123',          formatted => '',               is_formattable => 0, },
            { unformatted => '1234',         formatted => '',               is_formattable => 0, },
            { unformatted => '123456789012', formatted => '1234 5678 9012', is_formattable => 1, },
        );

        for my $test_charge_number (@test_charge_numbers) {

            my $charge_number = $CLASS->new( charge_number => $test_charge_number->{unformatted} );

            is( $charge_number->is_formattable, $test_charge_number->{is_formattable}, 
                q|Is charge number '| . $test_charge_number->{unformatted} . q|' formattable as a charge code| );

            is( $charge_number->formatted, $test_charge_number->{formatted}, 
                q|Correctly formatted charge code for charge number '| . $test_charge_number->{unformatted} . q|'| );

            is( "$charge_number", ( $test_charge_number->{formatted} || $test_charge_number->{unformatted} ), 
                q|Correctly stringified charge code for charge number '| . $test_charge_number->{unformatted} . q|'| );
        }

    };
    return;
}

