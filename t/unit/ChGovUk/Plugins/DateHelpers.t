use strict;
use Test::More;
use CH::Test;

use Readonly;
Readonly my $PLUGIN => 'ChGovUk::Plugins::DateHelpers';

use_ok $PLUGIN;
    use_ok $PLUGIN;

    new_ok $PLUGIN;

    methods_ok $PLUGIN, qw|register|;

    my $app = get_fake_app;
    $app->plugin( $PLUGIN );

    test_method_register();
    test_helper_date_as_string();
    test_helper_datetime_as_local_string();
    test_helper_suppressed_date_as_string();
    test_helper_day_month_as_string();

done_testing();

# ==============================================================================

sub test_method_register {
    subtest "Test method - register" => sub {
        registers_helpers $PLUGIN, qw(
            date_as_string datetime_as_local_string isodatetime_as_string
            isodate_as_string isodate_as_short_string isodatetime_as_short_string
            suppressed_date_as_string day_month_as_string
        );
    };
    return;
}

# ------------------------------------------------------------------------------

sub test_helper_date_as_string {
    subtest "Test helper - date_as_string" => sub {
        is($app->controller->date_as_string('01/12/2013'), '1 December 2013', 'dd/mm/yyyy');
        is($app->controller->date_as_string('01-12-2013'), '1 December 2013', 'dd-mm-yyyy');
        is($app->controller->date_as_string( '1/01/2013'), '1 January 2013',   'd-mm-yyyy');
        is($app->controller->date_as_string( '1-01-2013'), '1 January 2013',   'd-mm-yyyy');
        is($app->controller->date_as_string( '1/1/2013'),  '1 January 2013',   'd/m/yyyy' );
        is($app->controller->date_as_string( '1-1-2013'),  '1 January 2013',   'd-m-yyyy' );

        my $date = DateTime::Tiny->new( day   => 31,
                                        month => 12,
                                        year  => 2013
                                      );
        is($app->controller->date_as_string($date), '31 December 2013', 'DateTime::Tiny');

    };
    return;
}

# ------------------------------------------------------------------------------

sub test_helper_datetime_as_local_string {
    subtest "Test helper - datetime_as_local_string" => sub {
        is($app->controller->datetime_as_local_string('1405679412277'), '18 Jul 2014 11:30:12', 'epoch time in milliseconds');
        is($app->controller->datetime_as_local_string('1404210612277'), '01 Jul 2014 11:30:12', 'epoch time in milliseconds');
        is($app->controller->datetime_as_local_string('1405686612277'), '18 Jul 2014 13:30:12', 'epoch time in milliseconds');
        is($app->controller->datetime_as_local_string('1407846612277'), '12 Aug 2014 13:30:12', 'epoch time in milliseconds');

    };
    return;
}

# ------------------------------------------------------------------------------

sub test_helper_suppressed_date_as_string {
    subtest "Test helper - suppressed_date_as_string" => sub {
        is($app->controller->suppressed_date_as_string({ month => 7, year => 1973, }), 'July 1973',
            'suppressed date returned as a string');
        is($app->controller->suppressed_date_as_string({ day => 12, month => 7, year => 1973, }), 'July 1973',
            'suppressed date returned as a string');
    };
}

# ------------------------------------------------------------------------------

sub test_helper_day_month_as_string {
    subtest "Test helper - day_month_as_string" => sub {
        is($app->controller->day_month_as_string(5, 8), '5 August', '5 August');
        is($app->controller->day_month_as_string(19, 0), '19 December', '19 December');
    };
}

# ==============================================================================
