package ChGovUk::Controllers::PscNotifications;

use Mojo::Base 'Mojolicious::Controller';

use CH::Perl;

sub get { 
    my ($self) = @_; 
    
    $self->render(psc_id => $self->param('psc_id')); 

}

1;