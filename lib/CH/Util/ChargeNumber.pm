package CH::Util::ChargeNumber;

use CH::Perl;
use Moose;

with 'CH::Util::Formattable';

has 'charge_number' => ( is => 'rw', isa => 'Str', lazy => 1, default  => '', );

sub unformatted {

    return $_[0]->charge_number;
}

sub format {
    my ( $self, $charge_number ) = @_;

    my $charge_code = '';
    if ( length( $charge_number ) > 4 ) {
            ( $charge_code = $charge_number ) =~ s/^(.{4})(.{4})/$1 $2 /;
    }

    return $charge_code;
}

# Stringify
use overload '""' => sub {
    my ( $self ) = @_;

    return $self->is_formattable ? $self->formatted : $self->unformatted;
};
 
# TODO Decide between the following:
# ChargeNumber->new( charge_number => $number ) 
# ChargeNumber->from_charge_number( $number )
sub from_charge_number {
    my ( $class, $charge_number ) = @_;

    return $class->new( charge_number => $charge_number );
}

1;
