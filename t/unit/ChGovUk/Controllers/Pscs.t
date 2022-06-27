use CH::Perl;
use CH::Test;
use Test::More;
use Readonly;

Readonly my $CLASS => 'ChGovUk::Controllers::Company::Pscs';

use_ok $CLASS;
new_ok $CLASS;
methods_ok $CLASS, qw(list order_pscs_for_roe);

test_order_pscs_for_roe();

done_testing;

# ==============================================================================

sub test_order_pscs_for_roe {

    subtest "non-ROE company" => sub {

        my $pscs_controller = $CLASS->new(
            stash   => {
                company => {
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

        is_deeply (@results, @expected, 'correct ordering - statements after pscs')
    };

    subtest "ROE company, no active statements" => sub {

        my $pscs_controller = $CLASS->new(
            stash   => {
                company => {
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

        is_deeply (@results, @expected, 'correct ordering - statements after pscs')
    };

    subtest "ROE company, 1 or more active statements" => sub {

        my $pscs_controller = $CLASS->new(
            stash   => {
                company => {
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

        is_deeply (@results, @expected, 'correct ordering - pscs after statements')
    };

    return;
}

# ==============================================================================
