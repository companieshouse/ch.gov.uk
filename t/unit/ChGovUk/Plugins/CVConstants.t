use Test::More;
use CH::Test;

use Readonly;
Readonly my $CLASS => 'ChGovUk::Plugins::CVConstants';

use_ok $CLASS;

    methods_ok $CLASS, qw( register );

    test_method_register();

done_testing();

# ============================================================================== 

sub test_method_register {

    subtest "Test method - register" => sub {
        
        alias_method("ChGovUk::Plugins::CVConstants::load_cvconstants" => sub {
            return 1;
        });

        registers_helpers $CLASS, qw( cv cv_lookup );

        pop_method_alias("ChGovUk::Plugins::CVConstants::load_cvconstants");

    };
    return;
}

# ============================================================================== 
__END__

