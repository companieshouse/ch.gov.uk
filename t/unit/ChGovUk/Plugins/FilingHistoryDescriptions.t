use Test::More;
use CH::Test;

use Readonly;
Readonly my $CLASS => 'ChGovUk::Plugins::FilingHistoryDescriptions';

use_ok $CLASS;

    methods_ok $CLASS, qw( register );

    test_method_register();

done_testing();

# ============================================================================== 

sub test_method_register {

    subtest "Test method - register" => sub {
        
        alias_method("ChGovUk::Plugins::FilingHistoryDescriptions::load_filing_history_descriptions" => sub {
            return 1;
        });

        registers_helpers $CLASS, qw( fhd_lookup format_filing_history_dates );

        pop_method_alias("ChGovUk::Plugins::FilingHistoryDescriptions::load_filing_history_descriptions");

    };
    return;
}

# ============================================================================== 
__END__

