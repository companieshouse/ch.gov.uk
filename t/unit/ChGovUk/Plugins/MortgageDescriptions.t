use Test::More;
use CH::Test;

use Readonly;
Readonly my $CLASS => 'ChGovUk::Plugins::MortgageDescriptions';

use_ok $CLASS;

    methods_ok $CLASS, qw( register );

    test_method_register();

done_testing();

# ============================================================================== 

sub test_method_register {

    subtest "Test method - register" => sub {
        
        alias_method("ChGovUk::Plugins::MortgageDescriptions::load_mortgage_descriptions" => sub {
            return 1;
        });

        registers_helpers $CLASS, qw( md_lookup );

        pop_method_alias("ChGovUk::Plugins::MortgageDescriptions::load_mortgage_descriptions");

    };
    return;
}

# ============================================================================== 
__END__

