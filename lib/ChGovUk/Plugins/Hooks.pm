package ChGovUk::Plugins::Hooks;

use CH::Perl;
use Mojo::Base 'Mojolicious::Plugin';
use Locale::Simple;

# =============================================================================

sub register {
    my ($self, $app) = @_;

    $self->setup_before_dispatch_hook($app);

    return;
}

#-------------------------------------------------------------------------------

# Setup request lifecycle hooks
sub setup_before_dispatch_hook {
    my ($self, $app) = @_;

    # Hook into before_dispatch so we can add session data to the stash
    $app->hook( before_dispatch => sub {
        my ($self) = @_;

        $self->res->headers->server('Companies House');
        $self->res->headers->cache_control('no-store, no-cache, must-revalidate, post-check=0, pre-check=0');
        $self->res->headers->header( 'Pragma' => 'no-cache');
        $self->res->headers->header( 'X-Frame-Options' => 'DENY');
        $self->res->headers->header( 'X-Content-Type-Options' => 'nosniff');

        if ($self->app->mode eq 'production') {
            $self->res->headers->header( 'Strict-Transport-Security' => 'max-age=31536000');
        }

        $self->stash( session => $self->session );

        if(exists $self->config->{cdn}->{url}) {
            $self->stash(cdn_url => $self->config->{cdn}->{url});
        }
        if(exists $self->config->{accounts_template}->{url}) {
          $self->stash(accounts_template_url => $self->config->{accounts_template}->{url});
        }
    } );

    return;
}

# -----------------------------------------------------------------------------

1;

=head1 NAME

ChGovUk::Plugins::Hooks

=head1 SYNOPSIS

    sub startup {
        ...
        $self->plugin('ChGovUk::Plugins::Hooks');
        ...
    }


=head1 DESCRIPTION

Defines a set of hooks to be used in the application

=head1 METHODS

=head2 [void] register( $app )

Called to register the plugin with the mojolicious framework

	@param   app  [object]     mojolicious application

=cut
