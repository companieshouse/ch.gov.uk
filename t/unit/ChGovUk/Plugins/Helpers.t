use strict;
use Test::More;
use CH::Test;

use Readonly;
Readonly my $PLUGIN => 'ChGovUk::Plugins::Helpers';

use_ok $PLUGIN;
new_ok $PLUGIN;

methods_ok $PLUGIN, qw(register);

my $app = get_fake_app;
$app->plugin($PLUGIN);

test_method_register();
test_helper_piwik_goal_id();

done_testing();

# ==============================================================================

sub test_method_register {
    subtest "Test method - register" => sub {
        registers_helpers $PLUGIN, qw(
            base_url external_url_for parent_url_for piwik_goal_id url_for_lang
        );
    };
    return;
}

# ------------------------------------------------------------------------------

sub test_helper_piwik_goal_id {
    subtest "Test helper - piwik_goal_id" => sub {
        my $ctrl = $app->controller;

        $app->config({ piwik => { lp_add_general_partner_goal_id => 33 } });

        is($ctrl->piwik_goal_id('lp_add_general_partner_goal_id'), 33, 'returns goal id for a defined key');
        is($ctrl->piwik_goal_id('unknown_id_key'), undef, 'returns undef for an unknown key');
    };
    return;
}

# ==============================================================================
