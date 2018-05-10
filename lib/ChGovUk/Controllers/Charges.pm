package ChGovUk::Controllers::Charges;

use Mojo::Base 'Mojolicious::Controller';

use CH::Perl;
use POSIX;

use ChGovUk::Models::Charges;


#-------------------------------------------------------------------------------

# Charge list with links to all forms
sub list {
    my ($self) = @_;

    my $page = $self->param('page') // 1;
    my $type = $self->param('type');

    my $model = new ChGovUk::Models::Charges( 
        config         => $self->app->config, 
        page           => $page,
        company_number => $self->stash('company_number'),
    );
    $model->page_size( $self->param('page_size') ) if $self->param('page_size');

    $self->stash( charges => $model, type => $type, );
    $self->render();
    return;
}

#-------------------------------------------------------------------------------

1;
