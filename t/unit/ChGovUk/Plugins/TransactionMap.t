use strict;
use Test::More;
use CH::Test;
use Test::Exception;
use CH::Util::CVConstants;

use Readonly;
Readonly my $PLUGIN => 'ChGovUk::Plugins::TransactionMap';

use ChGovUk::Plugins::TransactionMap;

use_ok $PLUGIN;

    methods_ok $PLUGIN, qw( register );

    test_method_register();

    use Mojolicious::Controller;
    my $controller = new Mojolicious::Controller;

    test_helper_get_transaction_metadata();

done_testing();

# ============================================================================== 

sub test_method_register {
    subtest "Test method - register" => sub {

        registers_helpers $PLUGIN, qw|get_transaction_metadata
                                      get_transaction_map|;
    };
    return;
}

# ------------------------------------------------------------------------------ 

sub test_helper_get_transaction_metadata {
    subtest "Test helper - get_transaction_metadata" => sub {

        my $plugin = new_inst $PLUGIN;

        subtest "Get by CV Value" => sub {
            # TODO shouldn't rely on the existance of a specific transaction type
            my $data = $plugin->_get_transaction_metadata( $controller, formtype => $CV::FORMTYPE::AD01 );
            is( ref $data, 'HASH', "Return hash ref" );
            is( $data->{endpoint}, 'change-registered-office-address', "Correct node returned" );
        };

        # -----------------

        subtest "Get by endpoint" => sub {
            # TODO shouldn't rely on the existance of a specific transaction type
            my $data = $plugin->_get_transaction_metadata( $controller, endpoint => 'change-registered-office-address' );
            is( ref $data, 'HASH', "Return hash ref" );
            is( $data->{endpoint}, 'change-registered-office-address', "Correct node returned" );
        };
    };
    return;
}

# ------------------------------------------------------------------------------ 
