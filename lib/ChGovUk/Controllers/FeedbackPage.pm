package ChGovUk::Controllers::FeedbackPage;

use CH::Perl;
use Mojo::Base 'Mojolicious::Controller';
use CH::Util::CVConstants;

#-------------------------------------------------------------------------------

sub home {
    my ($self) = @_;
    my $search_type = 'all';
    $self->session(pst => $search_type);
    $self->stash(search_type => $search_type);
    $self->render;
}

sub render_filepath {
    my ($self) = @_;
    my $path = 'static_pages/help/' . $self->param('filepath');
    $self->render(template => $path );
}

#===============================================================================

1;
