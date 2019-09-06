package ChGovUk::Controllers::Company::ViewAll;

use Mojo::Base 'Mojolicious::Controller';
use CH::Perl;

#-------------------------------------------------------------------------------

# View All Tab
sub view {
  my ($self) = @_;
  
  return $self->render;
}

#-------------------------------------------------------------------------------

1;