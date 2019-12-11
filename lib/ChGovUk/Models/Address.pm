package ChGovUk::Models::Address;

use CH::Perl;
use CH::Util::CountryCodes;

use Moose;
use MooseX::Model;

#-------------------------------------------------------------------------------

my $country_codes = {
    # TODO pass language value (defaults to English)
    restricted => {
        mapped   => undef,
        unmapped => [
            CH::Util::CountryCodes->new(filter => qr/^GB/)->list,
            { 'NOTSPECIFIED' => 'Not specified' },
        ],
    },
    eea => {
        mapped   => undef,
        unmapped => [
            CH::Util::CountryCodes->new(list_type => 'EEA')->list,
            { 'OTHER' => 'Other' },
        ],
    },
    full => {
        mapped   => undef,
        unmapped => [
            CH::Util::CountryCodes->new(list_type => 'full')->list,
            { 'OTHER' => 'Other' },
        ],
    },
};

#-------------------------------------------------------------------------------

has 'etag'          => ( traits => ['Populate'],            is => 'rw' );
has 'premises'      => ( traits => ['Populate','Validate'], is => 'rw' );
has 'line_1'        => ( traits => ['Populate','Validate'], is => 'rw' );
has 'line_2'        => ( traits => ['Populate','Validate'], is => 'rw' );
has 'town'          => ( traits => ['Populate','Validate'], is => 'rw' );
has 'country'       => ( traits => ['Populate','Validate'], is => 'rw' );
has 'county'        => ( traits => ['Populate','Validate'], is => 'rw' );
has 'postcode'      => ( traits => ['Populate','Validate'], is => 'rw' );
has 'po_box'        => ( traits => ['Populate','Validate'], is => 'rw' );
has 'care_of'       => ( traits => ['Populate','Validate'], is => 'rw' );

#-------------------------------------------------------------------------------

validates 'premises'      => ( maxlength => 50, );
validates 'line_1'        => ( maxlength => 50, );
validates 'line_2'        => ( maxlength => 50, );
validates 'town'          => ( maxlength => 50, );
validates 'country'       => ( maxlength => 50, );
validates 'county'        => ( maxlength => 50, );
validates 'po_box'        => ( maxlength => 10, );
validates 'postcode'      => ( maxlength => 15, );
validates 'care_of'       => ( maxlength => 100, );

#-------------------------------------------------------------------------------

sub as_api_hash {
    my ( $self ) = @_;

    my $api_hash = {};

    $api_hash->{etag}           = $self->etag     if $self->etag;
    $api_hash->{premises}       = $self->premises if $self->premises;
    $api_hash->{address_line_1} = $self->line_1   if $self->line_1;
    $api_hash->{address_line_2} = $self->line_2   if $self->line_2;
    $api_hash->{region}         = $self->county   if $self->county;
    $api_hash->{country}        = $self->country  if $self->country;
    $api_hash->{postal_code}    = $self->postcode if $self->postcode;
    $api_hash->{locality}       = $self->town     if $self->town;
    $api_hash->{po_box}         = $self->po_box   if $self->po_box;
    $api_hash->{care_of}        = $self->care_of  if $self->care_of;

    return $api_hash;
}

# ------------------------------------------------------------------------------

sub from_api_hash {
    my ($self, $api_hash) = @_;

    $api_hash->{$_} ||= '' for qw(
        etag
        premises
        address_line_1
        address_line_2
        region
        country
        postal_code
        locality
        po_box
        care_of
    );

    $self->etag    ( $api_hash->{etag} );
    $self->premises( $api_hash->{premises} );
    $self->line_1  ( $api_hash->{address_line_1} );
    $self->line_2  ( $api_hash->{address_line_2} );
    $self->county  ( $api_hash->{region} );
    $self->country ( $api_hash->{country} );
    $self->postcode( $api_hash->{postal_code} );
    $self->town    ( $api_hash->{locality} );
    $self->po_box  ( $api_hash->{po_box} );
    $self->care_of ( $api_hash->{care_of} );

    return $self;
}

# ------------------------------------------------------------------------------

sub premises_and_line_1 {
    my ( $self ) = @_;

    return join(
        ( defined $self->premises && $self->premises =~ /^\d+$/ ) ? ' ' : ', ',
        grep { $_ && length $_ } ( $self->premises, $self->line_1 )
   );
}

# ------------------------------------------------------------------------------

sub as_string {
    my ( $self ) = @_;

    my $address_as_string = join(
        ', ',
        grep { $_ && length $_ } (
            $self->premises_and_line_1,
            $self->line_2,
            $self->town,
            $self->county,
            $self->country,
            $self->postcode,
        )
    );

    return $address_as_string;
}

# ------------------------------------------------------------------------------

sub country_as_string {
    my ($self) = @_;

    return $country_codes->{full}->country_for_code($self->country) // '';
}

# ------------------------------------------------------------------------------

sub get_country_list {
    my ($self, %options) = @_;

    my $list_type = $self->_country_list_type($options{list_type});
    return $country_codes->{$list_type}->{unmapped};
}

# ------------------------------------------------------------------------------
# ignore the keys and duplicate the values e.g.:
# from: [ { 'GB-ENG'  => 'England' }, { 'GB-SC'    => 'Scotland' }, ... ]
# to:   [ { 'England' => 'England' }, { 'Scotland' => 'Scotland' }, ... ]
sub get_country_name_list {
    my ($self, %options) = @_;

    my $list_type = $self->_country_list_type($options{list_type});

    unless (defined $country_codes->{$list_type}->{mapped}) {
        # XXX MooseX::Model::Role::Populate defines and exports a "values" attribute...
        my @countries = map { CORE::values(%$_) } @{ $self->get_country_list(list_type => $list_type) };
        $country_codes->{$options{$list_type}}->{mapped} = [ map { { $_ => $_ } } @countries ];
    }

    return $country_codes->{$options{$list_type}}->{mapped};
}

# ------------------------------------------------------------------------------

sub _country_list_type {
    my ($self, $type) = @_;

    return 'full' if $type =~ qr/^full$/i;
    return 'eea'  if $type =~ qr/^eea$/i;
    return 'restricted';
}

# ------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

=head1 NAME

ChGovUk::Models::Address

=head1 SYNOPSIS

    use Mojo::Base 'Mojolicious::Controller';

    use ChGovUk::Models::Address;
    use ChGovUk::Models::DataAdapter;

    my $address
        = ChGovUk::Models::Address->new(
                data_adapter => ChGovUk::Models::DataAdapter->new(
                    controller => $self
                )
            );

    $address->load( $config, { address_id => $address_id ) };

=head1 DESCRIPTION

Data model for a standard address.

A L<ChGovUk::Models::DataAdapter> must be supplied to the constructor.

=head1 ATTRIBUTES

[[ATTRIBUTES]]

=head1 METHODS

=head2 load

Load the address given an address id.

    @param   config     [hashref]   configuration hash
    @named   address_id [string]    id of address to load
    @returns 1=success, 0=failed

=head2 save

Persist address DB record

    @param   config    [hashref]  for database configuration
    @param   options   [hashref]  options (may include {address_id})
    @returns address database ID

=head2 as_hash

Return the model as a hash

    @param   options         [hash]      named options as following
    @named   address_id      [string]    (optional) address id for key
    @named   address_version [string]    (optional) address version for key
    @returns hashref containing data as saved in the model and the
             datakey. If address id and version are not supplied then
             they each default to zero.

=head2 get_country_list

Returns a reference to a list of ISO 3166-1 CODE => NAME pairs (single key hashrefs)
optionally filtered e.g. [ { 'GB' => 'Great Britain' }, ... ].

    @param   options    [hash]    named options as following
    @named   list_type  [string]  return full list if "full", else restricted
    @returns list (full or restricted) as determined by list_type

=head2 get_country_name_list

Returns a reference to a list of ISO 3166-1 NAME => NAME pairs (single key hashrefs)
optionally filtered e.g. [ { 'Great Britain' => 'Great Britain' }, ... ].

    @param   options    [hash]    named options as following
    @named   list_type  [string]  return full list if "full", else restricted
    @returns list (full or restricted) as determined by list_type

=head2 has_changed

Return whether the model has changed from when it was loaded.

TODO doco!

=head1 SEE ALSO

=cut
