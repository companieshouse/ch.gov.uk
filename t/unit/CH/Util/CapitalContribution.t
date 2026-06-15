use strict;
use Test::More;
use CH::Test;

use Readonly;
Readonly my $CLASS => 'CH::Util::CapitalContribution';

use_ok $CLASS;

isa_ok $CLASS, 'CH::Util::CapitalContribution';

methods_ok $CLASS, qw(
    add_formatted_capital_contribution_details
);

test_returns_early_when_item_missing();
test_returns_early_when_currency_value_missing();
test_formats_amount_and_sub_types();
test_empty_sub_types_array();

done_testing();
exit(0);

# ==============================================================================

sub test_returns_early_when_item_missing {
    subtest "Test method add_formatted_capital_contribution_details with missing item" => sub {

        my $result = CH::Util::CapitalContribution::add_formatted_capital_contribution_details(
            undef,
            sub { return 'ignored'; }
        );

        is($result, undef, 'Returns undef when item is missing');

    };
    return;
}

# ==============================================================================

sub test_returns_early_when_currency_value_missing {
    subtest "Test method add_formatted_capital_contribution_details with missing contribution_currency_value" => sub {

        my $item = {
            contribution_sub_types => [ { sub_type => 'money' } ],
        };

        my $result = CH::Util::CapitalContribution::add_formatted_capital_contribution_details(
            $item,
            sub { return 'Money'; }
        );

        is($result, undef, 'Returns undef when contribution_currency_value is missing');
        ok(!exists $item->{contribution_currency_value_formatted}, 'Does not add contribution_currency_value_formatted');
        ok(!exists $item->{contribution_sub_types_string}, 'Does not add contribution_sub_types_string');

    };
    return;
}

# ==============================================================================

sub test_formats_amount_and_sub_types {
    subtest "Test method add_formatted_capital_contribution_details formats values" => sub {

        my $item = {
            contribution_currency_value => 1234567.8,
            contribution_sub_types      => [
                { sub_type => 'money' },
                { sub_type => 'shares' },
            ],
        };

        my @seen_sub_types;
        my $lookup = sub {
            my ($sub_type) = @_;
            push @seen_sub_types, $sub_type;
            return 'Description for ' . $sub_type;
        };

        CH::Util::CapitalContribution::add_formatted_capital_contribution_details($item, $lookup);

        is($item->{contribution_currency_value_formatted}, '1,234,567.80', 'Amount is formatted with commas and two decimal places');
        is($item->{contribution_sub_types_string}, 'Description for money, Description for shares', 'Sub-types are joined as a comma-separated string');
        is_deeply(\@seen_sub_types, [ 'money', 'shares' ], 'Lookup callback called for each sub_type in order');

    };
    return;
}

# ==============================================================================

sub test_empty_sub_types_array {
    subtest "Test method add_formatted_capital_contribution_details with empty sub-types" => sub {

        my $item = {
            contribution_currency_value => 1000,
            contribution_sub_types      => [],
        };

        CH::Util::CapitalContribution::add_formatted_capital_contribution_details(
            $item,
            sub { return 'Should not be used'; }
        );

        is($item->{contribution_currency_value_formatted}, '1,000.00', 'Amount is formatted correctly');
        is($item->{contribution_sub_types_string}, '', 'Empty sub-types produces empty string');

    };
    return;
}

# ==============================================================================

__END__