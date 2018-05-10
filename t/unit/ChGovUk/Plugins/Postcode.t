use Test::More;
use Test::Exception;
use CH::Test;

use Readonly;
Readonly my $CLASS => 'ChGovUk::Plugins::Postcode';

use_ok $CLASS;
my $obj = new_ok $CLASS;

   methods_ok $CLASS, qw( register lookup);

   test_method_register();

done_testing();

# ==============================================================================

sub test_method_register {
    subtest "Test method - register" => sub {

        registers_helpers $CLASS, qw(postcode_lookup);

    };
    return;
}

# ==============================================================================
__END__

