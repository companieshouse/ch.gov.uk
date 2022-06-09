#!/usr/bin/env perl

use strict;
use warnings;

use CH::Test;
use Test::More;

use Readonly;

Readonly my $PLUGIN => 'ChGovUk::Plugins::AddressHelper';

use_ok $PLUGIN;
new_ok $PLUGIN;

methods_ok $PLUGIN, qw(register as_string);

my $app = get_fake_app;
$app->plugin($PLUGIN);

my $api_hash = {
    premises         => 'Civic Centre',
    address_line_1   => 'Oystermouth Road',
    address_line_2   => 'The Seafront',
    locality         => 'Swansea',
    country          => 'Wales',
    region           => 'Glamorgan',
    postal_code      => 'SA1 3SN',
    po_box           => '789',
    care_of          => 'The Janitor'
};

test_method_register();
test_helper_address_as_string();
test_helper_address_as_string_with_po_box();
test_helper_address_as_string_with_care_of();
test_helper_address_as_string_with_house_number_as_premise();

done_testing();

# ==============================================================================

sub test_method_register{
    subtest "Test method - register" => sub {
        registers_helpers $PLUGIN, qw(address_as_string);
    };
}

# ------------------------------------------------------------------------------

sub test_helper_address_as_string {
    subtest "Test method - as_string without optional field care_of" => sub {
        is(
            $app->controller->address_as_string($api_hash),
            'Civic Centre, Oystermouth Road, The Seafront, Swansea, Glamorgan, Wales, SA1 3SN',
            'Get formatted address as string without care of field'
        );
    };
}

# ------------------------------------------------------------------------------

sub test_helper_address_as_string_with_po_box {
    subtest "Test method - as s_string with optional field po_box including selected PO BOX user combinations" => sub {
        my $combinations = ['-',',','.','"','`'];
        foreach my $combination ( @{ $combinations } ) {
            $api_hash->{po_box} = $combination;
            is(
                $app->controller->address_as_string($api_hash, {include_po_box => 1}),
                'Civic Centre, Oystermouth Road, The Seafront, Swansea, Glamorgan, Wales, SA1 3SN'
            );
        }
        $combinations = ['BOX 463', 'MAIL BOX 463', 'MAILBOX 463', 'P O BOX 463', 'P.O. BOX 463', 'P.O.BOX 463', 'PO 463', 'PO BOX 463', 'POB 463', 'POBOX 463', '463'];
        foreach my $combination ( @{ $combinations } ) {
            $api_hash->{po_box} = $combination;
            is(
                $app->controller->address_as_string($api_hash, {include_po_box => 1}),
                'PO Box 463, Civic Centre, Oystermouth Road, The Seafront, Swansea, Glamorgan, Wales, SA1 3SN'
            );
        }
        $api_hash->{po_box} = 'Tottenham Hotspur';
        is(
            $app->controller->address_as_string($api_hash, {include_po_box => 1}),
            'PO Box Tottenham Hotspur, Civic Centre, Oystermouth Road, The Seafront, Swansea, Glamorgan, Wales, SA1 3SN'
        );
    };
}

# ------------------------------------------------------------------------------

sub test_helper_address_as_string_with_care_of {
    subtest "Test method - as_string with optional field care_of" => sub {
        is(
            $app->controller->address_as_string($api_hash, {include_care_of => 1} ),
            'The Janitor, Civic Centre, Oystermouth Road, The Seafront, Swansea, Glamorgan, Wales, SA1 3SN',
            'Get formatted address as string with care of field'
        );
    };
}

# ------------------------------------------------------------------------------

sub test_helper_address_as_string_with_house_number_as_premise {

    $api_hash =  {
        premises         => 14,
        address_line_1   => 'Monkswell Road',
        locality         => 'Exeter',
        country          => 'England',
        region           => 'Devon',
        postal_code      => 'EX4 4NS',
    };

    subtest "Test method - as_string with house number as premise" => sub {
        is(
            $app->controller->address_as_string($api_hash),
            '14 Monkswell Road, Exeter, Devon, England, EX4 4NS',
            'Get formatted address as string with care of field'
        );
    };
}

# ==============================================================================

__END__
