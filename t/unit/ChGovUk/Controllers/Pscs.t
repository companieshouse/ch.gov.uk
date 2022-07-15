use CH::Perl;
use CH::Test;
use Test::More;
use Readonly;

Readonly my $CLASS => 'ChGovUk::Controllers::Company::Pscs';
Readonly my $PSC =>             {
    'address' => {
        'address_line_1' => 'Old Church Road',
        'locality' => 'Cardiff',
        'postal_code' => 'CF14 1AA',
        'premises' => '29',
        'region' => 'South Glamorgan'
    },
    'date_of_birth' => '1977-06-01',
    'etag' => 'fe3a190ba4f6e662796af13ae2db2aab42730185',
    'is_sanctioned' => 1,
    'kind' => 'individual-beneficial-owner',
    'links' => {
        'self' => '/company/OE000002/persons-with-significant-control/individual-beneficial-owner/DHxa-VEwiFq8gi3K_0fpcVO2tIA'
    },
    'name' => 'Jack James Sparrow',
    'name_elements' => {
        'forename' => 'Jack',
        'middle_name' => 'James',
        'surname' => 'Sparrow'
    },
    'nationality' => 'New Zealander',
    'natures_of_control' => [
        'ownership-of-shares-more-than-25-percent-as-trust-registered-overseas-entity'
    ],
    'notified_on' => '2022-06-21'
};
Readonly my $INACTIVE_STATEMENT_A =>
{
    'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012a',
    'kind' => 'persons-with-significant-control-statement',
    'links' => {
        'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
    },
    'notified_on' => '2022-06-21',
    'ceased_on' => '2022-06-22', # inactive
    'statement' => 'at-least-one-beneficial-owner-unidentified'
};
Readonly my $INACTIVE_STATEMENT_B =>
{
    'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012b',
    'kind' => 'persons-with-significant-control-statement',
    'links' => {
        'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
    },
    'notified_on' => '2022-06-21',
    'ceased_on' => '2022-06-23', # inactive
    'statement' => 'at-least-one-beneficial-owner-unidentified'
};
Readonly my $ACTIVE_STATEMENT_C =>
{
    'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012c',
    'kind' => 'persons-with-significant-control-statement',
    'links' => {
        'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
    },
    'notified_on' => '2022-06-21', # active
    'statement' => 'at-least-one-beneficial-owner-unidentified'
};
Readonly my $INACTIVE_STATEMENT_C =>
{
    'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012c',
    'kind' => 'persons-with-significant-control-statement',
    'links' => {
        'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
    },
    'notified_on' => '2022-06-21',
    'ceased_on' => '2022-06-22', # inactive
    'statement' => 'at-least-one-beneficial-owner-unidentified'
};
Readonly my $ACTIVE_STATEMENT_D =>
{
    'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012d',
    'kind' => 'persons-with-significant-control-statement',
    'links' => {
        'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
    },
    'notified_on' => '2022-06-21', # active
    'statement' => 'at-least-one-beneficial-owner-unidentified'
};
Readonly my $INACTIVE_STATEMENT_D =>
{
    'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012d',
    'kind' => 'persons-with-significant-control-statement',
    'links' => {
        'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
    },
    'notified_on' => '2022-06-21',
    'ceased_on' => '2022-06-22', # inactive
    'statement' => 'at-least-one-beneficial-owner-unidentified'
};
Readonly my $ACTIVE_STATEMENT_E =>             {
    'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012e',
    'kind' => 'persons-with-significant-control-statement',
    'links' => {
        'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
    },
    'notified_on' => '2022-06-21',
    'statement' => 'at-least-one-beneficial-owner-unidentified'
};
Readonly my $INACTIVE_STATEMENT_E => {
    'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012e',
    'kind' => 'persons-with-significant-control-statement',
    'links' => {
        'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
    },
    'notified_on' => '2022-06-21',
    'ceased_on' => '2022-06-22', # inactive
    'statement' => 'at-least-one-beneficial-owner-unidentified'
};

use_ok $CLASS;
new_ok $CLASS;
methods_ok $CLASS, qw(
    list
    move_first_active_statement_to_top_for_roe
    get_first_active_statement
    get_rest_of_items
    get_company_is_active);

test_move_first_active_statement_to_top_for_roe();
test_get_first_active_statement();
test_get_rest_of_items();

done_testing;

# ==============================================================================

sub test_move_first_active_statement_to_top_for_roe {

    subtest "non-ROE company" => sub {

        my $pscs_controller = $CLASS->new(
            stash   => {
                company => {
                    company_status => "active",
                    type => "ltd"
                },
            }
        );

        my @items = [
            $PSC,
            $ACTIVE_STATEMENT_E
        ];

        my @expected_items = [
            $PSC,
            $ACTIVE_STATEMENT_E
        ];

        $pscs_controller->move_first_active_statement_to_top_for_roe(@items);

        is_deeply (@items, @expected_items, 'correct ordering - statements after pscs');
    };

    subtest "ROE company, no active statements because only statement is ceased" => sub {

        my $pscs_controller = $CLASS->new(
            stash   => {
                company => {
                    company_status => "registered",
                    type => "registered-overseas-entity"
                },
            }
        );

        my @items = [
            $PSC,
            $INACTIVE_STATEMENT_E
        ];

        my @expected_items = [
            $PSC,
            $INACTIVE_STATEMENT_E
        ];

        $pscs_controller->move_first_active_statement_to_top_for_roe(@items);

        is_deeply (@items, @expected_items, 'correct ordering - statements after pscs');
    };

    subtest "ROE company, no moving of first active statement because company is removed" => sub {

        my $pscs_controller = $CLASS->new(
            stash   => {
                company => {
                    company_status => "removed",
                    type => "registered-overseas-entity"
                },
            }
        );

        my @items = [
            $PSC,
            $ACTIVE_STATEMENT_E
        ];

        my @expected_items = [
            $PSC,
            $ACTIVE_STATEMENT_E
        ];

        $pscs_controller->move_first_active_statement_to_top_for_roe(@items);

        is_deeply (@items, @expected_items, 'correct ordering - statements after pscs');
    };

    subtest "ROE company, 1 active statement" => sub {

        my $pscs_controller = $CLASS->new(
            stash   => {
                company => {
                    company_status => "registered",
                    type => "registered-overseas-entity"
                },
            }
        );

        my @items = [
            $PSC,
            $ACTIVE_STATEMENT_E
        ];

        my @expected_items = [
            $ACTIVE_STATEMENT_E,
            $PSC
        ];

        $pscs_controller->move_first_active_statement_to_top_for_roe(@items);

        is_deeply (@items, @expected_items, 'correct ordering - pscs after active statement');
    };

    subtest "ROE company, multiple statements" => sub {

        my $pscs_controller = $CLASS->new(
            stash   => {
                company => {
                    company_status => "registered",
                    type => "registered-overseas-entity"
                },
            }
        );

        my @items = [
            $PSC,
            $INACTIVE_STATEMENT_A,
            $INACTIVE_STATEMENT_B,
            $ACTIVE_STATEMENT_C,
            $ACTIVE_STATEMENT_D
        ];

        my @expected_items = [
            $ACTIVE_STATEMENT_C,
            $PSC,
            $INACTIVE_STATEMENT_A,
            $INACTIVE_STATEMENT_B,
            $ACTIVE_STATEMENT_D
        ];

        $pscs_controller->move_first_active_statement_to_top_for_roe(@items);

        is_deeply (@items, @expected_items, 'correct ordering - pscs after first active statement, remaining statements follow in their original order');
    };

}

sub test_get_first_active_statement {

    subtest "gets first active statement" => sub {

        my $pscs_controller = $CLASS->new();

        my @items = [
            $PSC,
            $INACTIVE_STATEMENT_A,
            $INACTIVE_STATEMENT_B,
            $ACTIVE_STATEMENT_C,
            $ACTIVE_STATEMENT_D
        ];

        my $expected_first_active_statement = $ACTIVE_STATEMENT_C;
        my $expected_first_active_statement_index = 3;

        my ($index, $first_active_statement) = $pscs_controller->get_first_active_statement(@items);

        is($index, $expected_first_active_statement_index, 'found expected first active statement');
        is_deeply($first_active_statement, $expected_first_active_statement, 'found expected first active statement');
    };

    subtest "gets no active statement from no items" => sub {

        my $pscs_controller = $CLASS->new();

        my @no_items = [];

        my $expected_first_active_statement = undef;
        my $expected_first_active_statement_index = -1;

        my ($index, $first_active_statement) = $pscs_controller->get_first_active_statement(@no_items);

        is($index, $expected_first_active_statement_index, 'found no first active statement, as expected');
        is_deeply($first_active_statement, $expected_first_active_statement, 'found no first active statement, as expected')
    };

    subtest "gets no active statement from no statements" => sub {

        my $pscs_controller = $CLASS->new();

        my @items_with_no_statements = [
            $PSC
        ];

        my $expected_first_active_statement = undef;
        my $expected_first_active_statement_index = -1;

        my ($index, $first_active_statement) = $pscs_controller->get_first_active_statement(@items_with_no_statements);

        is($index, $expected_first_active_statement_index, 'found no first active statement, as expected');
        is_deeply($first_active_statement, $expected_first_active_statement, 'found no first active statement, as expected')
    };

    subtest "gets no active statement when none of the statements are active" => sub {

        my $pscs_controller = $CLASS->new();

        my @items = [
            $PSC,
            $INACTIVE_STATEMENT_A,
            $INACTIVE_STATEMENT_B,
            $INACTIVE_STATEMENT_C,
            $INACTIVE_STATEMENT_D
        ];

        my $expected_first_active_statement = undef;
        my $expected_first_active_statement_index = -1;

        my ($index, $first_active_statement) = $pscs_controller->get_first_active_statement(@items);

        is($index, $expected_first_active_statement_index, 'found no first active statement, as expected');
        is_deeply($first_active_statement, $expected_first_active_statement, 'found no first active statement, as expected')
    };

}

sub test_get_rest_of_items {

    subtest "gets rest of items" => sub {

        my $pscs_controller = $CLASS->new();

        my @items = [
            $PSC,
            $INACTIVE_STATEMENT_A,
            $INACTIVE_STATEMENT_B,
            $ACTIVE_STATEMENT_C,
            $ACTIVE_STATEMENT_D
        ];
        my $index_of_first_active_statement = 3;

        my @expected_rest_of_items = [
            $PSC,
            $INACTIVE_STATEMENT_A,
            $INACTIVE_STATEMENT_B,
            $ACTIVE_STATEMENT_D
        ];

        my $rest_of_items = $pscs_controller->get_rest_of_items($index_of_first_active_statement, @items);

        is_deeply($rest_of_items, @expected_rest_of_items, 'gets rest of items, as expected')
    };

    subtest "gets no items where there are no no items" => sub {

        my $pscs_controller = $CLASS->new();

        my @items = [];
        my $index_of_first_active_statement = -1;

        my @expected_rest_of_items = [];

        my $rest_of_items = $pscs_controller->get_rest_of_items($index_of_first_active_statement, @items);

        is_deeply($rest_of_items, @expected_rest_of_items, 'gets no items, as expected')
    };

    subtest "gets all items where there are no statements" => sub {

        my $pscs_controller = $CLASS->new();

        my @items = [
            $PSC
        ];
        my $index_of_first_active_statement = -1;

        my @expected_rest_of_items = [
            $PSC
        ];

        my $rest_of_items = $pscs_controller->get_rest_of_items($index_of_first_active_statement, @items);

        is_deeply($rest_of_items, @expected_rest_of_items, 'gets all items, as expected')
    };

    subtest "gets all items where there are no active statements" => sub {

        my $pscs_controller = $CLASS->new();

        my @items = [
            $PSC,
            $INACTIVE_STATEMENT_A,
            $INACTIVE_STATEMENT_B,
            $INACTIVE_STATEMENT_C,
            $INACTIVE_STATEMENT_D
        ];
        my $index_of_first_active_statement = -1;

        my @expected_rest_of_items = @items;

        my $rest_of_items = $pscs_controller->get_rest_of_items($index_of_first_active_statement, @items);

        is_deeply($rest_of_items, @expected_rest_of_items, 'gets all items, as expected')
    }

}

subtest "\$view_pscs_event is 'View persons with significant control' for a non-ROE company" => sub {
    plan tests => 1;
    my $pscs_controller = $CLASS->new(
        stash => {
            company => {
                company_number => "00006400",
                type           => "ltd",
            }
        });
    $pscs_controller->stash_view_pscs_event();
    is $pscs_controller->stash->{view_pscs_event}, "View persons with significant control", "\$view_pscs_event should be 'View persons with significant control'";
};

subtest "\$view_pscs_event is 'View beneficial owners' for a ROE company" => sub {
    plan tests => 1;
    my $pscs_controller = $CLASS->new(
        stash => {
            company => {
                company_number => "OE000002",
                type           => "registered-overseas-entity",
            }
        });
    $pscs_controller->stash_view_pscs_event();
    is $pscs_controller->stash->{view_pscs_event}, "View beneficial owners", "\$view_pscs_event should be 'View beneficial owners'";
};


# ==============================================================================
