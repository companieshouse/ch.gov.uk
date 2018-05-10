use Test::More;
use CH::Test;
use Mojo::UserAgent;
use Mojo::Util 'monkey_patch';
use ChGovUk::Plugins::FilingHistoryExceptions;
use Readonly;
Readonly my $CLASS => 'ChGovUk::Plugins::FilingHistoryExceptions';
monkey_patch 'ChGovUk::Plugins::FilingHistoryExceptions', load_filing_history_exceptions => sub { return 1; };

plan tests => 3;
use_ok $CLASS;

my $app = get_fake_app();

$app->plugin( $CLASS );

methods_ok $CLASS, qw( register load_filing_history_exceptions );

test_method_register();

done_testing();

# ==============================================================================

sub test_method_register {

    subtest "Test method - register" => sub {
        plan tests => 1;

        registers_helpers $CLASS, qw( fhe_lookup );

    };
    return;
}

# ==============================================================================
__END__

