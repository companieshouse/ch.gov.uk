package ChGovUk::Models::Date;

use CH::Perl;
use Moose;
use MooseX::Model;

use DateTime::Tiny;
use CH::Util::DateHelper;

#-------------------------------------------------------------------------------

has 'day'   => ( traits => ['Populate', 'Validate'], is => 'rw' );
has 'month' => ( traits => ['Populate', 'Validate'], is => 'rw' );
has 'year'  => ( traits => ['Populate', 'Validate'], is => 'rw' );

#-------------------------------------------------------------------------------

validates model => sub {
    my ($self, $model, $errors) = @_;

    my $is_valid = 1;

    if ( !$self->day && !$self->month && !$self->year ){
        $errors->{required} = 1;
        debug "All fields missing '%s'", r:$self [VALIDATION];
    }
    elsif ( !$self->day || !$self->month || !$self->year ){
        $is_valid = 0;
        debug "Some fields missing '%s'", r:$self [VALIDATION];
    }
    else {
        $is_valid = CH::Util::DateHelper->is_valid( $self->to_date );
        unless ( $is_valid ){
            debug "Invalid date '%s'", r:$self [VALIDATION];
        }
    }

    if (!$is_valid) {
        $errors->{valid_date} = 1;
    }
};

#-------------------------------------------------------------------------------

sub to_date {
    my ($self) = @_;

    return DateTime::Tiny->new(
        day   => $self->day,
        month => $self->month,
        year  => $self->year,
    );
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

=head1 NAME

CH::Models::Date

=head1 SYNOPSIS

    use CH::Models::Date;

    my $date = CH::Models::Date->new();

=head1 DESCRIPTION

Model for a date

=head1 METHODS

=head2 to_date

Using the internal day, month and year values will create and
return a new L<DateTime::Tiny> object.

    @returns new DateTime::Tiny object

Example

    my $ch_date = $date->to_date;


=cut
