#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::Exception;
use Test::More;

use ChGovUk::Models::DataAdapter;
use CH::MojoX::Plugin::Config;
use CH::Test;

my $CLASS = 'ChGovUk::Models::Address';

use_ok $CLASS;

methods_ok $CLASS => qw( as_api_hash from_api_hash as_string get_country_list get_country_name_list );

my $app = get_fake_app(); # Fake::Mojolicious::App

$app->plugin('CH::MojoX::Plugin::Config');

my $controller = $app->controller;

$controller->stash(company_number => '00000001');

has_roles $CLASS => qw(
    MooseX::Model::Role::Validate
    MooseX::Model::Role::Populate
);

test_method_get_country_list();
test_method_as_api_hash();
test_method_from_api_hash();

done_testing();

# ==============================================================================

sub test_method_from_api_hash {
    subtest "Test method - from_api_hash" => sub {
        my $api_hash = {
            etag             => 'cbff69a7a36ffd48acc4196b242d055ead5e2853',
            premises         => 'Civic Centre',
            address_line_1   => 'Oystermouth Road',
            address_line_2   => 'The Seafront',
            locality         => 'Swansea',
            country          => 'Wales',
            region           => 'Glamorgan',
            postal_code      => 'SA1 3SN',
            po_box           => '789',
            care_of          => 'The Janitor',
        };

        my $address = $CLASS->new(
            data_adapter => ChGovUk::Models::DataAdapter->new(
                controller => $controller
            )
        );

        $address->from_api_hash( $api_hash );

        is( $address->etag    , $api_hash->{etag}, 'cbff69a7a36ffd48acc4196b242d055ead5e2853' );
        is( $address->premises, $api_hash->{premises}, 'Premises' );
        is( $address->line_1  , $api_hash->{address_line_1}, 'Line 1' );
        is( $address->line_2  , $api_hash->{address_line_2}, 'Line 2' );
        is( $address->county  , $api_hash->{region}, 'County' );
        is( $address->country , $api_hash->{country}, 'Country' );
        is( $address->postcode, $api_hash->{postal_code}, 'Postcode' );
        is( $address->town    , $api_hash->{locality}, 'Town' );
        is( $address->po_box  , $api_hash->{po_box}, 'PO Box' );
        is( $address->care_of , $api_hash->{care_of}, 'Care of' );
        is( $address->as_string, 'Civic Centre, Oystermouth Road, The Seafront, Swansea, Glamorgan, Wales, SA1 3SN',
            'Get formatted address');
    };
}

# ==============================================================================

sub test_method_as_api_hash {
    subtest "Test method - as_api_hash" => sub {
        my $address = $CLASS->new(
            data_adapter => ChGovUk::Models::DataAdapter->new(
                controller => $controller
            )
        );

        subtest "Null values" => sub {
            my $result = $address->as_api_hash;
            is_deeply(
                $result,
                {

                }, 'undef values' );
            is($address->as_string, '', 'Get formatted address - null details');
        };

        subtest "Populated" => sub {
            $address->etag      ( 'cbff69a7a36ffd48acc4196b242d055ead5e2853'  );
            $address->premises  ( '21 The Cottage'  );
            $address->line_1    ( 'Fake Street'     );
            $address->line_2    ( 'The cul-de-sac'  );
            $address->town      ( 'Cardiff'         );
            $address->county    ( 'Glamorgan'       );
            $address->country   ( 'Wales'          );
            $address->postcode  ( 'CF12 AB'         );
            $address->po_box    ( '123'             );
            $address->care_of   ( 'Mr Trustworthy'  );

            my $result = $address->as_api_hash;
            is_deeply(
                $result,
                {   reference_etag   => 'cbff69a7a36ffd48acc4196b242d055ead5e2853',
                    premises         => '21 The Cottage',
                    address_line_1   => 'Fake Street',
                    address_line_2   => 'The cul-de-sac',
                    locality         => 'Cardiff',
                    country          => 'Wales',
                    region           => 'Glamorgan',
                    postal_code      => 'CF12 AB',
                    po_box           => '123',
                    care_of          => 'Mr Trustworthy',
                }, 'correct values' );

            is (
                $address->as_string,
                '21 The Cottage, Fake Street, The cul-de-sac, Cardiff, Glamorgan, Wales, CF12 AB',
                'Get formatted address - alphanumeric premises'
            );

            $address->premises( '21' );
            is (
                $address->as_string,
                '21 Fake Street, The cul-de-sac, Cardiff, Glamorgan, Wales, CF12 AB',
                'Get formatted address - numeric premises'
            );

            $address->premises( 'The Cottage' );
            is (
                $address->as_string,
                'The Cottage, Fake Street, The cul-de-sac, Cardiff, Glamorgan, Wales, CF12 AB',
                'Get formatted address - alphabetic premises'
            );
        };
    };
}

# ==============================================================================

sub test_method_get_country_list {
    # these are basic sanity-checks (no structural tests), so the same tests
    # can be used for the legacy/obsolete method (get_country_list) and
    # the current method (get_country_name_list)

    for my $get_country_list (qw(get_country_list get_country_name_list)) {
        subtest "Test method $get_country_list" => sub {
            my $address = ChGovUk::Models::Address->new(data_adapter => ChGovUk::Models::DataAdapter->new);

            subtest 'Full list' => sub {
                my $full_country_list = $address->$get_country_list(list_type => 'full');
                isa_ok $full_country_list, 'ARRAY';
                is (scalar(@$full_country_list), 31, '31 items returned (list + OTHER)');
            };

            subtest 'Restricted list - no list type' => sub {
                my $restricted_country_list = $address->$get_country_list();
                isa_ok $restricted_country_list, 'ARRAY';
                is (scalar(@$restricted_country_list), 6, '6 items returned (list + OTHER)');
            };

            subtest 'Restricted list - unknown list type' => sub {
                my $restricted_country_list = $address->$get_country_list(list_type => 'cats');
                isa_ok $restricted_country_list, 'ARRAY';
                is (scalar(@$restricted_country_list), 6, '6 items returned (list + OTHER)');
            };

            subtest 'EEA list - EEA list type' => sub {
                my $eea_country_list = $address->$get_country_list(list_type => 'EEA');
                isa_ok $eea_country_list, 'ARRAY';
                is (scalar(@$eea_country_list), 35, '35 items returned (list + OTHER)');
            };
        };
    }
}

1;
