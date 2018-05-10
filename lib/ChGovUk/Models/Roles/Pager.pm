package ChGovUk::Models::Roles::Pager;

use CH::Perl;
use Moose::Role;

requires 'namespace'; # TODO implement properly - derive from package name?

requires 'total_items'; # maps the relevant item total to a standard name

has 'page'            => ( is => 'rw', isa => 'Int', lazy => 1, default => 1 );
has 'page_size'       => ( is => 'rw', isa => 'Int', lazy => 1, builder => '_build_page_size', );
has 'number_of_pages' => ( is => 'rw', isa => 'Int', lazy => 1, builder => '_build_number_of_pages', );


# -----------------------------------------------------------------------------

# Builder methods
#

sub _build_page_size {
    my ( $self, ) = @_;

    return $self->default_page_size;
}

# -----------------------------------------------------------------------------

sub _build_number_of_pages {
    my ( $self, ) = @_;
    my $number_of_pages = POSIX::ceil( $self->total_items / $self->page_size );
    debug "Number of pages [%s]", $number_of_pages [GENERAL];
    return $number_of_pages;
}

# -----------------------------------------------------------------------------

# Other methods
#

sub default_page_size {
    my ( $self, ) = @_;

    my $page_size = $self->config->{paging}->{ $self->namespace }->{page_size} ||
                    $self->config->{paging}->{page_size};

    return $page_size;
}

# -----------------------------------------------------------------------------



# TODO is there a better way? For example override $self->set_page_size
sub _check_page_size {
    my ( $self, ) = @_;

    my $maximum_page_size = 2 * $self->default_page_size;
    $self->page_size( $maximum_page_size ) if ($self->page_size > $maximum_page_size);

    return;
}

# -----------------------------------------------------------------------------

1;

=head1 NAME

ChGovUk::Models::Roles::Pager

=head1 SYNOPSIS

    use ChGovUk::Models::Roles::Pager;

=head1 DESCRIPATION

Generic control for paging - determines page list number and the number of pages.  Also the size of each page, based on a parameter passed in the url or a default value in app config.  Check is done to ensure that double the default value is not exceeded.

=head1 ATTRIBUTES

[[ATTRIBUTES]]

=head1 METHODS

=head2 default_page_size ()

    @returns    appconfig value for type of list

=cut
