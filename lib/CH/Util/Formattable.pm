package CH::Util::Formattable;

use CH::Perl;
use Moose::Role;

requires 'unformatted', # Returns unformatted item
         'format';      # Formats the unformatted item or returns false

has 'formatted' => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build_formatted', );

sub _build_formatted {
    my ( $self ) = @_;

    return '' unless defined $self->unformatted;

    my $formatted = $self->format( $self->unformatted );

    return $formatted;
}

sub is_formattable {
    my ( $self ) = @_;

    return $self->formatted ? 1 : 0;
}

1;
