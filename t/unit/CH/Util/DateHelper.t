use strict;
use Test::More;
use Test::Exception;
use CH::Test;
use ChGovUk::Models::Date;
use 5.10.0;
use boolean;
use ChGovUk::Models::DataAdapter;

use Readonly;
Readonly my $UTIL => 'CH::Util::DateHelper';

use_ok $UTIL;

    methods_ok $UTIL, qw(
        add_date_YMD
        as_local_string
        as_string
        is_current_date_greater
        day_month_as_string
        days_between
        from_internal
        is_date_greater
        is_valid
        is_valid_y_m_d
        isodate_as_string
        isodatetime_as_string
        isotime_as_string
        suppressed_date_to_string
        to_date_time
        to_internal
    );

    test_method_from_internal();
    test_method_to_internal();
    test_method_is_valid();
    test_method_as_string();
    test_method_as_local_string();
    test_method_is_current_date_greater();
    test_method_day_month_as_string();
    test_method_days_between();
    test_method_to_date_time();
    test_method_isodate_as_string();
    test_method_isodatetime_as_string();
    test_method_isodate_as_short_string();
    test_method_isodatetime_as_short_string();
    test_method_suppressed_date_to_string();

done_testing();
exit(0);

# ==============================================================================

sub test_method_is_valid {
    subtest "Test method - is_valid" => sub {

        my @data = (
            { day => 1,  month => 1,  year => 2000, valid => true  },
            { day => 28, month => 2,  year => 2000, valid => true  },
            { day => 29, month => 2,  year => 2000, valid => true  },
            { day => 29, month => 2,  year => 2000, hour => 5, minute => 6, second => 7, valid => true  },
            { day => 29, month => 2,  year => 2001, valid => false },
            { day => 29, month => 22, year => 2001, valid => false },
            { day => 40, month => 12, year => 2001, valid => false },
            { day => 40, month => 12, year => '',   valid => false },
        );

        subtest "Given DateTime::Tiny object" => sub {
            foreach my $test (@data) {
                my $date = DateTime::Tiny->new(
                    map { defined $test->{$_} ? ($_ => $test->{$_}) : () } ( qw/ day month year hour minute second / )
                );
                is( $UTIL->is_valid( $date ), $test->{valid},
                    "date is ".($test->{valid}?'valid':'invalid' ));
            }
        };

        subtest "Given internal format string" => sub {
            foreach my $test (@data) {
                my $date = sprintf('%4d%02d%02d', $test->{year}, $test->{month}, $test->{day});
                is( $UTIL->is_valid( $date ), $test->{valid},
                    "$date is ".($test->{valid}?'valid':'invalid' ));
            }
        };

        subtest "Given separate values" => sub {
            foreach my $test (@data) {
                is( $UTIL->is_valid_y_m_d( $test->{year}, $test->{month}, $test->{day} ), $test->{valid},
                    sprintf('%4d%02d%02d', $test->{year}, $test->{month}, $test->{day}) .
                    " is ".($test->{valid}?'valid':'invalid' ));
            }
        };

    };
}

# ------------------------------------------------------------------------------

sub test_method_from_internal {
    subtest "Test method - from_internal" => sub {

        my @data = (
            { in => '20000101',        ok => true,  day => '1',  month => '1', year => '2000' },
            { in => '20000230',        ok => true,  day => '30', month => '2', year => '2000' }, # Invalid day - accepted
            { in => '200001',          ok => false,                                           }, # Too short
            { in => '2000010121',      ok => false,                                           }, # Wrong format
            { in => '20001321',        ok => true,  day => '21', month => 13,  year => '2000' }, # Invalid date is ok
            { in => '20120220123456',  ok => true,  day => 20,   month => 2,   year => 2012   }, # Valid date-time
            { in => '200001012121611', ok => false,                                           }, # Wrong format
            { in => 'xxxxxxxx',        ok => false,                                           }, # Wrong format
        );

        foreach my $test (@data) {
            subtest "Test date '$$test{in}'" => sub {
                my $result = undef;
                if ($test->{ok}) {
                    # Expected to run ok
                    lives_ok { $result = $UTIL->from_internal( $test->{in} ) }, "executes ok";
                    my $correct_isa = isa_ok( $result, 'DateTime::Tiny', "created expected DateTime::Tiny object" );
                    SKIP: {
                        skip "incorrect object type", 3 unless $correct_isa;
                        is($result->day,   $test->{day},   "day correct ".$result->day);
                        is($result->month, $test->{month}, "month correct ".$result->month);
                        is($result->year,  $test->{year},  "year correct ".$result->year);
                    }
                }
                else {
                    # Expect throw an exception for dodgy input
                    throws_ok { $UTIL->from_internal( $test->{in} ) } "CH::Exception",
                              "throws exception with bad from_internal data: " . $test->{in};
                }
            };
        }

    };
    return;
}

# ------------------------------------------------------------------------------

sub test_method_to_internal {
    subtest "Test method - to_internal" => sub {

        my @data = (
            { in => '',                                                ok => false, },
            { in => undef,                                             ok => false, },
            { in => '20010412',                                        ok => false, },
            { in => DateTime::Tiny->new(year=>2000,month=>2,day=>6),   ok => true,  out => '20000206'},
            { in => DateTime::Tiny->new(year=>2012,month=>1,day=>40),  ok => true,  out => '20120140'}, # Invalid is ok
            { in => DateTime::Tiny->new(year=>2012,month=>8,day=>14,
                                        hour=>22,minute=>2,second=>3), ok => true,  out => '20120814'}, # Time is ignored
        );

        foreach my $test (@data) {
            subtest "Test date object" => sub {
                if ($test->{ok}) {
                    my $result;
                    lives_ok { $result = $UTIL->to_internal( $test->{in} ) }, "executes ok";
                    is($result, $test->{out}, "created expected date '$$test{out}'");
                }
                else {
                    throws_ok { $UTIL->to_internal( $test->{in} ) } "CH::Exception",
                              "throws exception with bad to_internal data: " . $test->{in} // 'Undef';
                }
            };
        }

    };
    return;
}

# ------------------------------------------------------------------------------

sub test_method_as_string {
    subtest "Test method - as_string" => sub {

        my $da = ChGovUk::Models::DataAdapter->new();

        my @data = (
            { in => undef,                                               ok => true,  out => ''                },
            { in => '20010x452',                                         ok => false, },
            { in => '20-21x-2012',                                       ok => false, },
            { in => '20/21-2012',                                        ok => false, },
            { in => '',                                                  ok => true,  out => '', }, # special case
            { in => '20010412',                                          ok => true,  out => '12 April 2001', },
            { in => '20010412101214',                                    ok => true,  out => '12 April 2001', },
            { in => '20/01/2012',                                        ok => true,  out => '20 January 2012' },
            { in => '20-01-2012',                                        ok => true,  out => '20 January 2012' },
            { in => '2/1/2012',                                          ok => true,  out => '2 January 2012'  },
            { in => ChGovUk::Models::Date->new(data_adapter=>$da,
                                          year=>2000,month=>2,day=>6),   ok => true,  out => '6 February 2000' },
            { in => ChGovUk::Models::Date->new(data_adapter=>$da,
                                          year=>2012,month=>8,day=>14,
                                          hour=>22,minute=>2,second=>3), ok => true,  out => '14 August 2012'  }, # Time is ignored
            { in => DateTime::Tiny->new(year=>2012,month=>9,day=>2),     ok => true,  out => '2 September 2012' }, # Tiny is ok!
        );

        foreach my $test (@data) {
            subtest "Test date object as string" => sub {
                my $result;
                if ($test->{ok}) {
                    lives_ok { $result = $UTIL->as_string( $test->{in} ) }, "executes ok";
                    is($result, $test->{out}, "created expected date string '$$test{out}'");
                    if (ref($test->{in}) =~ /Models::Date/) {
                        lives_ok { $result = $UTIL->as_string( $test->{in}->to_date ) }, "executes ok";
                        is($result, $test->{out}, "created expected date string '$$test{out}'");
                    }
                } else {
                    throws_ok { $UTIL->as_string( $test->{in} ) } "CH::Exception",
                              "throws exception with bad as_string data: " . $test->{in} // 'Undef';
                    if (ref($test->{in}) =~ /Models::Date/) {
                        throws_ok(sub { $UTIL->as_string( $test->{in}->to_date ) }, "CH::Exception",
                                "throws exception with bad as_string(to_date)");
                    }
                }
            };
        }

    };
    return;
}

# ------------------------------------------------------------------------------

sub test_method_as_local_string {
    subtest "Test method - as_local_string" => sub {

        my @data = (
            { in => undef,              ok => true,  out => ''                     },
            { in => '',                 ok => true,  out => ''                     }, # special case
            { in => 'xx',               ok => false, },
            { in => '20010x452',        ok => false, },
            { in => '20-21x-2012',      ok => false, },
            { in => '20/21-2012',       ok => false, },
            { in => '20/01/2012',       ok => false, },
            { in => '20-01-2012',       ok => false, },
            { in => '2/1/2012',         ok => false, },
            { in => '1404210612277',    ok => true,  out => '01 Jul 2014 11:30:12' },
            { in => '1405679412277',    ok => true,  out => '18 Jul 2014 11:30:12' },
            { in => '1405686612277',    ok => true,  out => '18 Jul 2014 13:30:12' },
            { in => '1407846612277',    ok => true,  out => '12 Aug 2014 13:30:12' },
        );

        plan tests => scalar(@data);

        foreach my $test (@data) {
            subtest "Test date object as local string" => sub {
                my $result;
                if ($test->{ok}) {
                    lives_ok { $result = $UTIL->as_local_string( $test->{in} ) }, "executes ok";
                    is($result, $test->{out}, "created expected date string '$$test{out}'");
                } else {
                    throws_ok { $UTIL->as_local_string( $test->{in} ) } "CH::Exception",
                              "throws exception with bad as_local_string data: " . $test->{in} // 'Undef';
                }
            };
        }

    };
    return;
}

# ------------------------------------------------------------------------------

sub test_method_to_date_time {
    subtest "Test method - to_date_time" => sub {

        my $da = ChGovUk::Models::DataAdapter->new();

        my @data = (
            { in => undef,                                               ok => true,, out => ''                    },
            { in => '20/21-2012',                                        ok => false, },
            { in => '',                                                  ok => true,  out => ''                    },
            { in => 'xx',                                                ok => false, },
            { in => '20-21-2012',                                        ok => true,  out => '2012-21-20T00:00:00' },
            { in => DateTime::Tiny->new(year=>2012,month=>19,day=>40),   ok => true,  out => '2012-19-40T00:00:00' },
            { in => ChGovUk::Models::Date->new(data_adapter=>$da,
                                          year=>2012,month=>1,day=>40),  ok => true,  out => '2012-01-40T00:00:00' },
            { in => '20010452',                                          ok => true,  out => '2001-04-52T00:00:00' },
            { in => '20010412',                                          ok => true,  out => '2001-04-12T00:00:00' },
            { in => '20010412121314',                                    ok => true,  out => '2001-04-12T12:13:14' },
            { in => '20/01/2012',                                        ok => true,  out => '2012-01-20T00:00:00' },
            { in => '20-01-2012',                                        ok => true,  out => '2012-01-20T00:00:00' },
            { in => '2/1/2012',                                          ok => true,  out => '2012-01-02T00:00:00' },
            { in => ChGovUk::Models::Date->new(data_adapter=>$da,
                                          year=>2000,month=>2,day=>6),   ok => true,  out => '2000-02-06T00:00:00' },
            { in => ChGovUk::Models::Date->new(data_adapter=>$da,
                                          year=>2012,month=>8,day=>14,
                                          # invalid class attributes
                                          hour=>22,minute=>2,second=>3
                                         ),                              ok => true,  out => '2012-08-14T00:00:00' },
            { in => DateTime::Tiny->new(year=>2012,month=>9,day=>2,
                                          hour=>22,minute=>2,second=>3), ok => true,  out => '2012-09-02T22:02:03' },
            { in => 1404372347*1000,                                     ok => true,  out => '2014-07-03T07:25:47' },
            { in => -86401*1000,                                         ok => true,  out => '1969-12-30T23:59:59' },
        );

        foreach my $test (@data) {
            subtest "Test to_date_time method" => sub {
                my $result;
                if ($test->{ok}) {
                    lives_ok { $result = $UTIL->to_date_time( $test->{in} ) }, "executes ok";
                    is($result->as_string, $test->{out}, "created expected date string '$$test{out}'") if $test->{in};

                } else {
                    throws_ok { $UTIL->to_date_time( $test->{in} ) } "CH::Exception",
                              "throws exception with bad to_date_time data: " . $test->{in} // 'Undef';
                }
            };
        }

    };
    return;
}

# ------------------------------------------------------------------------------

sub delta_tiny {
    my $offset_days = shift;

    my @l_time = localtime(time + 86400*$offset_days);
    return DateTime::Tiny->new(year=>$l_time[5]+1900, month=>$l_time[4]+1, day=>$l_time[3]);
}

sub test_method_days_between {
    subtest "Test method - days_between" => sub {

        my @data = (
            { in => [ '',                               ], ok => false, },
            { in => [ undef,                            ], ok => false, },
            { in => [ '20010412',                       ], ok => false, },
            { in => [ '20-21-2012',                     ], ok => false, },
            { in => [ delta_tiny(2),  '',               ], ok => false, },
            { in => [ delta_tiny(0),                    ], ok => true,  out => 0    },
            { in => [ delta_tiny(6),                    ], ok => true,  out => -6   },
            { in => [ delta_tiny(-400),                 ], ok => true,  out => 400  },
            { in => [ delta_tiny(4),    delta_tiny(4)   ], ok => true,  out => 0    },
            { in => [ delta_tiny(-4),   delta_tiny(0)   ], ok => true,  out => 4    },
            { in => [ delta_tiny(0),    delta_tiny(100) ], ok => true,  out => 100  },
            { in => [ delta_tiny(10),   delta_tiny(20)  ], ok => true,  out => 10   },
            { in => [ delta_tiny(-10),  delta_tiny(10)  ], ok => true,  out => 20   },
        );

        foreach my $test (@data) {
            subtest "Test date difference" => sub {
                my $result;
                if ($test->{ok}) {
                    lives_ok { $result = $UTIL->days_between( @{ $test->{in} } ) }, "executes ok";
                    is($result, $test->{out}, "created expected date string '$$test{out}'");
                } else {
                    throws_ok { $UTIL->days_between( @{ $test->{in} } ) } "CH::Exception",
                              "throws exception with bad days_between";
                }
            };
        }

    };
    return;
}

# ------------------------------------------------------------------------------

sub test_method_isodate_as_string {
    subtest "Test method - isodate_as_string" => sub {

        my @data = (
            { in => '20010x452',            ok => false, },
            { in => '20-21x-2012',          ok => false, },
            { in => '20/21-2012',           ok => false, },
            { in => undef,                  ok => true,  out => ''                },
            { in => '',                     ok => true,  out => ''                }, # special case
            { in => '2014-07-01T10:30:12',  ok => true,  out => '1 July 2014'     },
            { in => '2014-07-15T13:19:16',  ok => true,  out => '15 July 2014'    },
            { in => '2013-10-15T13:19:16',  ok => true,  out => '15 October 2013' },
        );

        plan tests => scalar(@data);

        foreach my $test (@data) {
            test_date_formatting($test, 'isodate_as_string', 'date string');
        }
    };

    return;
}

# ------------------------------------------------------------------------------

sub test_method_isodatetime_as_string {
    subtest "Test method - isodatetime_as_string" => sub {

        my @data = (
            { in => '20010x452',            ok => false, },
            { in => '20-21x-2012',          ok => false, },
            { in => '20/21-2012',           ok => false, },
            { in => undef,                  ok => true,  out => ''                         },
            { in => '',                     ok => true,  out => ''                         }, # special case
            { in => '2014-07-01T10:30:12',  ok => true,  out => '1 July 2014 11:30:12'     },
            { in => '2014-07-15T13:19:16',  ok => true,  out => '15 July 2014 14:19:16'    },
            { in => '2013-10-15T13:19:16',  ok => true,  out => '15 October 2013 14:19:16' },
        );

        plan tests => scalar(@data);

        foreach my $test (@data) {
            test_date_formatting($test, 'isodatetime_as_string', 'date and time string');
        }
    };

    return;
}

# ------------------------------------------------------------------------------

sub test_method_isodate_as_short_string {
    subtest "Test method - isodate_as_short_string" => sub {

        my @data = (
            { in => undef,                 ok     => true,       out => '' },
            { in => '20010x452',           ok     => false, },
            { in => '20-21x-2012',         ok     => false, },
            { in => '20/21-2012',          ok     => false, },
            { in => '',                    ok     => true,       out => '' }, # special case
            { in => '2014-07-01T10:30:12', format => '%d %b %Y', ok  => true,  out => '01 Jul 2014' },
            { in => '2014-07-15T13:19:16', format => '%d %b %Y', ok  => true,  out => '15 Jul 2014' },
            { in => '2013-10-15T13:19:16', format => '%d %b %Y', ok  => true,  out => '15 Oct 2013' },
        );

        plan tests => scalar(@data);

        foreach my $test (@data) {
            test_date_formatting($test, 'isodate_as_string', 'date string');
        }
    };

    return;
}

# ------------------------------------------------------------------------------

sub test_method_suppressed_date_to_string {
    subtest "Test method - suppressed_date_to_string" => sub {

        my @data = (
            { in => undef,                                             ok => false,                      },
            { in => { day   => '20', month => '21x', year => '1952' }, ok => false,                      },
            { in => { day   => '20', month => '10',  year => '1952' }, ok => true, out => 'October 1952' },
            { in => {                month => '04',  year => '1952' }, ok => true, out => 'April 1952'   },
        );

        plan tests => scalar(@data);

        foreach my $test (@data) {
            test_date_formatting($test, 'suppressed_date_to_string', 'date string');
        }
    };

    return;
}

# ------------------------------------------------------------------------------

sub test_method_isodatetime_as_short_string {
    subtest "Test method - isodatetime_as_short_string" => sub {

        my @data = (
            { in => undef,                 ok     => true,          out => '' },
            { in => '20010x452',           ok     => false, },
            { in => '20-21x-2012',         ok     => false, },
            { in => '20/21-2012',          ok     => false, },
            { in => '',                    ok     => true,          out => '' }, # special case
            { in => '2014-07-01T10:30:12', format => '%d %b %Y %T', ok  => true,  out => '01 Jul 2014 11:30:12' },
            { in => '2014-07-15T13:19:16', format => '%d %b %Y %T', ok  => true,  out => '15 Jul 2014 14:19:16' },
            { in => '2013-10-15T13:19:16', format => '%d %b %Y %T', ok  => true,  out => '15 Oct 2013 14:19:16' },
        );

        plan tests => scalar(@data);

        foreach my $test (@data) {
            test_date_formatting($test, 'isodatetime_as_string', 'date time string');
        }

    };
    return;
}

# ------------------------------------------------------------------------------

sub test_date_formatting {
    my ($test, $method, $message_part) = @_;

    subtest "Test $method" => sub {
        my $result;
        if ($test->{ok}) {
            lives_ok { $result = $UTIL->$method( $test->{in}, $test->{format} )
            ? $UTIL->$method( $test->{in}, $test->{format} ) : $UTIL->$method( $test->{in} ) }, "executes ok";
            is($result, $test->{out}, "created and expected $message_part '$$test{out}'");
        } else {
            throws_ok { $UTIL->$method( $test->{in} ) } "CH::Exception",
                      "throws exception with bad $method data: " . $test->{in} // 'Undef';
        }
    };

    return;
}

# ------------------------------------------------------------------------------

sub test_method_day_month_as_string {
    subtest "Test method - day_month_as_string" => sub {
        is  $UTIL->day_month_as_string(3, 6), '3 June', 'day and month';
        is  $UTIL->day_month_as_string(1, 1), '1 January', '1 January';
        is  $UTIL->day_month_as_string(31, 12), '31 December', '31 December';
        is  $UTIL->day_month_as_string(1, 0), '1 December', 'zero month';
    };

    return;
}

# ------------------------------------------------------------------------------

sub test_method_is_current_date_greater {
     subtest "Test method - is_current_date_greater" => sub {
         is $UTIL->is_current_date_greater('2017-01-01'), "1", "1 returned when todays date is after given date";
         my $today = DateTime::Tiny->now;
         is $UTIL->is_current_date_greater($today), "1", "1 returned when todays date is the given date";
         my $future_date = DateTime::Tiny->new(
             year   => $today->year + 1,
             month  => $today->month,
             day    => $today->day
             );
         is $UTIL->is_current_date_greater($future_date), "0", "0 returned when todays date is before given date";
     };

     return;
}

# ==============================================================================

__END__
