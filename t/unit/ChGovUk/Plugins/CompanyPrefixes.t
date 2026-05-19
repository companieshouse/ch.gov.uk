use strict;
use Test::More;
use CH::Test;

use Readonly;
Readonly my $PLUGIN => 'ChGovUk::Plugins::CompanyPrefixes';

use_ok $PLUGIN;

    new_ok $PLUGIN;

    methods_ok $PLUGIN, qw|register|;

    my $app = get_fake_app;
    $app->plugin( $PLUGIN );

    test_method_register();
    test_helper_company_is_llp();
    test_helper_company_has_no_sic();
    test_helper_company_is_digital_lp();

done_testing();

# ============================================================================== 

sub test_method_register {
    subtest "Test method - register" => sub {
        registers_helpers $PLUGIN, qw( company_is_llp company_has_no_sic company_is_digital_lp );
    };
    return;
}

# ------------------------------------------------------------------------------ 

sub test_helper_company_is_llp {
    subtest "Test helper - company_is_llp" => sub {
        is($app->controller->company_is_llp('OC123912'), 1, 'Company is LLP');
        is($app->controller->company_is_llp('05018589'), 0, 'Company is not LLP');
    };
    return;
}

# ============================================================================== 

sub test_helper_company_has_no_sic {
    subtest "Test helper - company_has_no_sic" => sub {
        is($app->controller->company_has_no_sic('OC123912', ''), 1, 'Company has no SIC');
        is($app->controller->company_has_no_sic('05018589', ''), 0, 'Company has SIC');
        is($app->controller->company_has_no_sic('NI071404', 'community-interest-company'), 0, 'Company has SIC');
        is($app->controller->company_has_no_sic('LP111111', ''), 1, 'Company has no SIC'); # Filed with a paper LP5
        is($app->controller->company_has_no_sic('LP222222', 'private-fund-limited-partnership'), 1, 'Company has no SIC'); # Filed with a paper LP7
        is($app->controller->company_has_no_sic('LP333333', 'pflp'), 1, 'Company has no SIC'); # Filed with a digital LP7D
        is($app->controller->company_has_no_sic('SL444444', 'spflp'), 1, 'Company has no SIC'); # Filed with a digital LP7D (Scottish)
        is($app->controller->company_has_no_sic('LP555555', 'lp'), 0, 'Company has SIC'); # Filed with a digital LP5D
        is($app->controller->company_has_no_sic('NL555555', 'lp'), 0, 'Company has SIC'); # Filed with a digital LP5D (Northern Irish)
        is($app->controller->company_has_no_sic('SL666666', 'slp'), 0, 'Company has SIC'); # Filed with a digital LP5D (Scottish)
    };
    return;
}

# ==============================================================================

sub test_helper_company_is_digital_lp {
    subtest "Test helper - company_is_digital_lp" => sub {
        is($app->controller->company_is_digital_lp('lp'), 1, 'Company is digital LP');
        is($app->controller->company_is_digital_lp('slp'), 1, 'Company is digital LP');
        is($app->controller->company_is_digital_lp('pflp'), 1, 'Company is digital LP');
        is($app->controller->company_is_digital_lp('spflp'), 1, 'Company is digital LP');
        is($app->controller->company_is_digital_lp(''), 0, 'Company is not a digital LP'); # Either an LP but filed with a paper LP5 OR not an LP
        is($app->controller->company_is_digital_lp('community-interest-company'), 0, 'Company is not a digital LP'); # Just not an LP
        is($app->controller->company_is_digital_lp('private-fund-limited-partnership'), 0, 'Company is not a digital LP'); # An LP but filed with a paper LP7
    };
    return;
}
