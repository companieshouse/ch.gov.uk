use CH::Perl;
use CH::Test;
use Test::More;
use Readonly;
use Data::Dumper;

Readonly my $CLASS => 'ChGovUk::Controllers::Company::Pscs';

use_ok $CLASS;
new_ok $CLASS;
methods_ok $CLASS, qw(list order_pscs_for_roe);

test_order_pscs_for_roe();
test_get_first_active_statement();
test_get_rest_of_statements();

done_testing;

# ==============================================================================

sub test_order_pscs_for_roe {

    subtest "non-ROE company" => sub {

        my $pscs_controller = $CLASS->new(
            stash   => {
                company => {
                    company_status => "active",
                    type => "ltd"
                },
            }
        );

        my @pscs = [{
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
        }];

        my @statements = [
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012e',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            }
        ];

        my @expected = [
            {
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
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012e',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            }
        ];

        my @results = $pscs_controller->order_pscs_for_roe(@pscs, @statements);

        is_deeply (@results, @expected, 'correct ordering - statements after pscs');
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

        my @pscs = [{
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
        }];

        my @statements = [
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012e',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22',
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            }
        ];

        my @expected = [
            {
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
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012e',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22',
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            }
        ];

        my @results = $pscs_controller->order_pscs_for_roe(@pscs, @statements);

        is_deeply (@results, @expected, 'correct ordering - statements after pscs');
    };

    subtest "ROE company, no active statements because company is removed" => sub {

        my $pscs_controller = $CLASS->new(
            stash   => {
                company => {
                    company_status => "removed",
                    type => "registered-overseas-entity"
                },
            }
        );

        my @pscs = [{
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
        }];

        my @statements = [
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012e',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            }
        ];

        my @expected = [
            {
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
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012e',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            }
        ];

        my @results = $pscs_controller->order_pscs_for_roe(@pscs, @statements);

        is_deeply (@results, @expected, 'correct ordering - statements after pscs');
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

        my @pscs = [{
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
        }];

        my @statements = [
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012e',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            }
        ];

        my @expected = [
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012e',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
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
            }
        ];

        my @results = $pscs_controller->order_pscs_for_roe(@pscs, @statements);

        is_deeply (@results, @expected, 'correct ordering - pscs after active statement');
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

        my @pscs = [{
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
        }];

        my @statements = [
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012a',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012b',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-23', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012c',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21', # active
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012d',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21', # active
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            }
        ];

        my @expected = [
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012c',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21', # active
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
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
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012d',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21', # active
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012a',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012b',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-23', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            }
        ];

        my @results = $pscs_controller->order_pscs_for_roe(@pscs, @statements);

        # TODO ROE-847 Remove this.
        debug "\@results = %s", Dumper(@results);

        is_deeply (@results, @expected, 'correct ordering - pscs after first active statement, remaining statements follow, active before ceased');
    };

}

sub test_get_first_active_statement {

    subtest "gets first active statement" => sub {

        my $pscs_controller = $CLASS->new();

        my @statements = [
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012a',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012b',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012c',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21', # active
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012d',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21', # active
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            }
        ];

        my $expected_first_active_statement =
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012c',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21', # active
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            };
        my $expected_first_active_statement_index = 2;

        my ($index, $first_active_statement) = $pscs_controller->get_first_active_statement(@statements);

        is($index, $expected_first_active_statement_index, 'found expected first active statement');
        is_deeply($first_active_statement, $expected_first_active_statement, 'found expected first active statement');
    };

    subtest "gets no active statement from no statements" => sub {

        my $pscs_controller = $CLASS->new();

        my @no_statements = [];

        my $expected_first_active_statement = undef;
        my $expected_first_active_statement_index = -1;

        my ($index, $first_active_statement) = $pscs_controller->get_first_active_statement(@no_statements);

        is($index, $expected_first_active_statement_index, 'found no first active statement, as expected');
        is_deeply($first_active_statement, $expected_first_active_statement, 'found no first active statement, as expected')
    };

    subtest "gets no active statement when none of the statements are active" => sub {

        my $pscs_controller = $CLASS->new();

        my @statements = [
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012a',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012b',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012c',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012d',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            }
        ];

        my $expected_first_active_statement = undef;
        my $expected_first_active_statement_index = -1;

        my ($index, $first_active_statement) = $pscs_controller->get_first_active_statement(@statements);

        is($index, $expected_first_active_statement_index, 'found no first active statement, as expected');
        is_deeply($first_active_statement, $expected_first_active_statement, 'found no first active statement, as expected')
    };

}

sub test_get_rest_of_statements {

    subtest "gets rest of statements" => sub {

        my $pscs_controller = $CLASS->new();

        my @statements = [
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012a',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012b',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012c',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21', # active
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012d',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21', # active
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            }
        ];
        my $index_of_first_active_statement = 2;

        my @expected_rest_of_statements = [
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012a',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012b',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012d',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21', # active
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            }
        ];

        my $rest_of_statements = $pscs_controller->get_rest_of_statements($index_of_first_active_statement, @statements);

        is_deeply($rest_of_statements, @expected_rest_of_statements, 'gets rest of statements, as expected')
    };

    subtest "gets empty statements from empty statements" => sub {

        my $pscs_controller = $CLASS->new();

        my @statements = [];
        my $index_of_first_active_statement = -1;

        my @expected_rest_of_statements = [];

        my $rest_of_statements = $pscs_controller->get_rest_of_statements($index_of_first_active_statement, @statements);

        is_deeply($rest_of_statements, @expected_rest_of_statements, 'gets empty rest of statements, as expected')
    };

    subtest "gets all statements where there are no active statements" => sub {

        my $pscs_controller = $CLASS->new();

        my @statements = [
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012a',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012b',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012c',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            },
            {
                'etag' => 'b166d2a8a7d0983b315a290dc2a0966be280012d',
                'kind' => 'persons-with-significant-control-statement',
                'links' => {
                    'self' => '/company/OE000002/persons-with-significant-control-statements/wifoccBKENLo5y_bMmEJhE-fJSs'
                },
                'notified_on' => '2022-06-21',
                'ceased_on' => '2022-06-22', # inactive
                'statement' => 'at-least-one-beneficial-owner-unidentified'
            }
        ];
        my $index_of_first_active_statement = -1;

        my @expected_rest_of_statements = @statements;

        my $rest_of_statements = $pscs_controller->get_rest_of_statements($index_of_first_active_statement, @statements);

        is_deeply($rest_of_statements, @expected_rest_of_statements, 'gets all statements, as expected')
    }

}

# ==============================================================================
