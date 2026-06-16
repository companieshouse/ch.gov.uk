package CH::Util::CapitalContribution;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(add_formatted_capital_contribution_details);

sub add_formatted_capital_contribution_details {
    my ($item, $lookup_sub_type_description) = @_;

    # Only add the formatted fields if capital contribution data is present
    return unless $item && $item->{contribution_currency_value};

    # Format the amount to always have two decimal places and insert thousand separators to improve readability of large values
    my $amount = sprintf('%.2f', $item->{contribution_currency_value});
    1 while $amount =~ s/^(-?\d+)(\d{3})/$1,$2/;
    $item->{contribution_currency_value_formatted} = $amount;

    # Build a comma-separated list of capital contribution sub-types, from values looked up in API enumerations
    $item->{contribution_sub_types_string} = join ', ',
        map  { $lookup_sub_type_description->($_->{sub_type}) }
        @{ $item->{contribution_sub_types} // [] };

    return;
}

1;