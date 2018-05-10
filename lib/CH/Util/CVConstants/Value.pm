package CH::Util::CVConstants::Value;
use Mouse;

use CH::Perl;

has 'id' => ( is => 'rw', required => 1 );
has 'key' => ( is => 'rw', required => 1 );
has 'cv' => ( is => 'rw', required => 1 );
has 'class' => ( is => 'rw', required => 1 );
has 'cache' => ( is => 'rw' );

# Causes this object to stringify to its ID
use overload '""' => sub {
    my ($self) = @_;
    return $self->id;
};

# ------------------------------------------------------------------------------ 

sub get {
    my ($self) = @_;

    if(!$self->cache) {
        my $result = $self->cv->lookup($self->class->{class_id}, $self->id);
        $self->cache($result);
    }

    return $self->cache;
}

# ------------------------------------------------------------------------------ 

sub value       { return $_[0]->get->{value};       }
sub description { return $_[0]->get->{description}; }

# ------------------------------------------------------------------------------ 

1;

=head1 NAME

CH::Util::CVConstants::Value

=head1 SYNOPSIS

    use CH::Util::CVConstants::Value;

    my $value = CH::Util::CVConstants::Value->new();

=head1 DESCRIPTION

Class representing a CV item.

=head1 METHODS

=head2 get ()

Returns a hashref containing value and description looked up in the database

    @returns hashref containing value and description

Example

    my $hash = $value->get;

=head2 value ()

Returns the value associated with this CV value from the database

    @returns  value

Example

    my $value = $cv->value();

=head2 description ()

Returns the description associated with this CV value from the database

    @returns  description

Example

    my $desc = $cv->description;

=cut


