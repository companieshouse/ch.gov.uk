package ChGovUk::Models::Company::Transactions::ChangeRegisteredOfficeAddress;

use CH::Perl;
use Moose;
use MooseX::Model;

# TODO not sure this should live here
our %api_field_map = (
    'address[premises]' => 'premises',
    'address[line_1]'   => 'address_line_1',
    'address[line_2]'   => 'address_line_2',
    'address[town]'     => 'locality',
    'address[county]'   => 'region',
    'address[postcode]' => 'postal_code',
    'address[country]'  => 'country',
    'address[po_box]'   => 'po_box',
    'address[etag]'     => 'reference_etag',
);

#-------------------------------------------------------------------------------

has 'address' => ( traits => ['Populate', 'Validate'], is => 'rw', isa => 'ChGovUk::Models::Address' );

#-------------------------------------------------------------------------------

sub get_api_map {
    return \%api_field_map;
}

#-------------------------------------------------------------------------------

sub update_api {
    my ( $self, $transaction, ) = @_;
    return $transaction->registered_office_address->update( $self->address->as_api_hash );
}

# ------------------------------------------------------------------------------ 

__PACKAGE__->meta->make_immutable;

=head1 NAME

ChGovUk::Models::Company::Transactions::ChangeRegisteredOfficeAddress

=cut
