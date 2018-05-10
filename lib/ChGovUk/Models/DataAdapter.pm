package ChGovUk::Models::DataAdapter;

use CH::Perl;
use Moose;
extends 'MooseX::Model::DataAdapter';

use Readonly;

Readonly our $CAP09_DATE         => 20091001;
Readonly our $CHARGE_REFORM_DATE => 20130406;

has 'controller' => ( is => 'rw', isa => 'Mojolicious::Controller' );

has 'cap09_date'           => ( is => 'ro', default => sub { $CAP09_DATE         } );
has 'charge_reform_date'   => ( is => 'ro', default => sub { $CHARGE_REFORM_DATE } );

has 'company_number'     => ( is => 'ro', lazy => 1, builder => '_build_company_number' );
has 'person_number'      => ( is => 'ro', lazy => 1, builder => '_build_person_number' );

#-------------------------------------------------------------------------------

sub _build_company_number {
    my ($self) = @_;

    return $self->controller->stash('company_number');
}

#-------------------------------------------------------------------------------

sub _build_person_number {
    my ($self) = @_;

    return $self->controller->stash('person_number');
}

##-------------------------------------------------------------------------------
__PACKAGE__->meta->make_immutable;
