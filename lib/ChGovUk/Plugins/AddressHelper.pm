package ChGovUk::Plugins::AddressHelper;

use CH::Perl;
use Mojo::Base 'Mojolicious::Plugin';

# ------------------------------------------------------------------------------.

sub register {
    my ($self, $app) = @_;

    trace "Registering %s::address_as_string helper", __PACKAGE__ [APP];

    $app->helper(address_as_string => \&as_string);

    return;
}

# ------------------------------------------------------------------------------

sub as_string {
    my ($controller, $address, $opts) = @_;

    return undef unless $address;

    my $seperator = defined $address->{premises} && $address->{premises} =~ /^\d+$/
        ? ' ' : ', ';

    my $premises_and_address_line_1 = join $seperator, grep { $_ && length $_ } (
        $address->{premises},
        $address->{address_line_1}
    );

    my $address_as_string = join ', ', grep { $_ && length $_ } (
        $premises_and_address_line_1,
        $address->{address_line_2},
        $address->{locality},
        $address->{region},
        $address->{country},
        $address->{postal_code},
    );

    if ($opts->{include_po_box} && $address->{po_box}) {
        my $po_box = $address->{po_box};
        #remove any punctuation in string
        $po_box =~ s/[[:punct:]]//g;
        $po_box =~ s/^[`".,-]$|^(?:BOX|P[\.\s]?O[\.\s]?\s?(?:B(?:OX)?)?|MAIL\s?BOX)\s?(\d+)$/$1/;
        $address_as_string = join ', ', grep { $_ && length $_ } (
            'PO Box '.$po_box,
            $address_as_string
        ) if $po_box;
    }

    my $care_of;
    if ($opts->{title_case_care_of}) {
        $care_of = join '', map { ucfirst lc } split /(\s+)/, $address->{care_of};
    } else {
        $care_of = $address->{care_of};
    }

    $address_as_string = join ', ', grep { $_ && length $_ } (
        $care_of,
        $address_as_string
    ) if $opts->{include_care_of};

    if ($opts->{include_names}) {
        my $name = "";

        if ($address->{name}) {
            $name = $address->{name};
        }

        my $full_name = join ' ', $name;

        $address_as_string = join ', ', grep { $_ && length $_ } (
            $full_name,
            $address_as_string
        ) if $full_name;
    }

    $address_as_string =~ s/,,/,/g if $opts->{suppress_double_commas};

    return $address_as_string;
}

# ------------------------------------------------------------------------------

1;

=head1 NAME

ChGovUk::Plugins::AddressHelper

=head1 SYNOPSIS

    sub startup {
        ...
        $self->plugin('ChGovUk::Plugins::AddressHelper');
        ...
    }

=head1 METHODS

=head2 register

Called by mojolicious when plugin is registered. Registers the
L</address_as_string> helper.

    @param   app    [mojo app]  mojolicious application

=head1 EXPORTED HELPERS

=head2 address_as_string

Converts an address block into an address string.

    @param    address  [hash]
    @returns  string   care_of, premises address_line_1, address_line_2, town, county, country, postcode

Care of is suppressed by default but can be included in the stringified address by passing the
C<include_care_of> option.

    $controller->address_as_string($address, include_care_of => 1);

=cut
