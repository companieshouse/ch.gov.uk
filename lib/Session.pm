package MojoX::Security::Session;

use Mojo::Base 'Mojo::EventEmitter';

our $VERSION = '0.43';

use strict;

use Mojo::Util qw(b64_encode);
use Mojo::Log;

use Crypt::CBC;
use Digest::SHA qw(sha1_base64);
use Carp;

has [qw(domain secure)];
has cookie_name        => '__SID';
has cookie_path        => '/';
has default_expiration => $ENV{DEFAULT_SESSION_EXPIRATION};

# Multiples of 3 bytes avoids = padding in base64 string
# 7 * 3 bytes = (21/3) * 4 = 28 base64 characters
my $ID_BYTES  = 7 * 3;

# -----------------------------------------------------------------------------

sub load {
    my ($self, $c, $cb) = @_;

    return unless $cb;

    return $cb->() unless my $value = $c->cookie( $self->cookie_name);
    my $sig_start = ($ID_BYTES / 3) * 4;

    my $id = substr($value, 0, $sig_start);

    if( substr($value, $sig_start) ne $self->_hash_id($c, $id) ) {
        $c->app->log->error( "Invalid session signature." ); # You can get this if your mojo secrets are not the same across cooperating sites.
        return $cb->();
    }

    $c->app->log->debug( "Lookup session $id" );

    $self->emit(before_load => $c, $id);

    $c->app->cache->get( $id => sub {
        my ($session) = @_;

        $self->emit(after_load => $c, $id, $session);

        if( !$session ) {
            $c->app->log->debug( "Failed to load session $id" );
            return $cb->();
        }

        my $stash = $c->stash;

        # "expiration" value is inherited
        my $expiration = $session->{expiration} // $self->default_expiration;
        return $cb->() if !(my $expires = delete $session->{expires}) && $expiration;
        return $cb->() if defined $expires && $expires <= time;
        return $cb->() unless $stash->{'mojo.active_session'} = keys %$session;

        $stash->{'mojo.session'} = $session;
        $session->{flash} = delete $session->{new_flash} if $session->{new_flash};

        $cb->();
    } );
}

# -----------------------------------------------------------------------------


sub store {
    my ($self, $c, $cb) = @_;

    $c->render_later; # Ensure we wait for the async return from the store. If we
                      # don't do this we end up with store being called twice.

    return unless $cb;

    # Make sure session was active
    my $stash = $c->stash;
    return $cb->() unless my    $session  = $stash->{'mojo.session'};
    return $cb->() unless keys %$session || $stash->{'mojo.active_session'};

    # Don't reset flash for static files
    my $old = delete $session->{flash};
    @{$session->{new_flash}}{keys %$old} = values %$old if $stash->{'mojo.static'};
    delete $session->{new_flash} unless keys %{$session->{new_flash}};

    # Generate "expires" value from "expiration" if necessary
    my $now = time;
    my $expiration = $session->{expiration} // $self->default_expiration;
    my $default = delete $session->{expires};
    $session->{expires} = $default || $now + $expiration if $expiration || $default;

    $session->{last_access} = $now;

    my $sessionID = $session->{'.id'} || ($session->{'.id'} = $self->_generate_sessionID);

    my $cookie_val = $sessionID . $self->_hash_id( $c, $sessionID );

    $c->cookie( $self->cookie_name, $cookie_val, {
        domain   => $self->domain,
        expires  => $session->{expires},
        httponly => 1,
        path     => $self->cookie_path,
        secure   => $self->secure
    });

    my $ttl = $session->{expires} - $now;

    $self->store_session( $c, $sessionID, $session, $ttl, $cb);
}

# -----------------------------------------------------------------------------

sub store_session {
    my ($self, $c, $sessionID, $session, $ttl, $cb) = @_;

    if ($session->{'signin_info'}->{'user_profile'}) {
        $c->app->log->debug( "set private beta user" );
        $session->{'signin_info'}->{'user_profile'}->{'private_beta_user'} = $session->{'signin_info'}->{'user_profile'}->{'private_beta_user'} ? 1 : 0;
    }

    $c->app->log->debug( "Store session $sessionID" );

    $self->emit(before_store => $c, $sessionID, $session );

    $c->cache->set( $sessionID, $session, $ttl => sub {
        $self->emit(after_store => $c, $sessionID );
        $c->app->log->debug( "Return from save storage backend" );
        $cb->();
    } );
}

# -----------------------------------------------------------------------------

sub regenerate_sessionID {
    my ($self, $c) = @_;

    # Make sure session was active
    my $stash = $c->stash;
    my $session = $stash->{'mojo.session'};

    return ($session->{'.id'} = $self->_generate_sessionID);
}

# -----------------------------------------------------------------------------

sub clear {
    my ($self, $c) = @_;

    $c->stash->{'mojo.session'} = {};
    $self->regenerate_sessionID;
}

# -----------------------------------------------------------------------------

sub delete {
    my ($cb, $self, $c, $sessionID) = (pop,@_);

    $sessionID //= $c->stash->{'mojo.session'}->{'.id'};
    $c->cache->delete( $sessionID => $cb );
}

# -----------------------------------------------------------------------------

sub _hash_id {
    my ($self, $c, $id) = @_;

    my $secrets = $c->app->secrets;
    return sha1_base64($id . $secrets->[0]);
}

# -----------------------------------------------------------------------------

sub on {
    my ($self, $events) = @_;

    for my $event (keys %$events) {
        $self->SUPER::on($event => $events->{$event});
    }
    return $self;
}

# ------------------------------------------------------------------------------

sub _many_sessionIDs {
    my ($num) = @_;
    for (my $i = 0; $i < $num; $i++) {
          print  _generate_sessionID() . "\n";
    }
}
sub _generate_sessionID {
    my ($self) = @_;

    my $id = b64_encode( Crypt::CBC->random_bytes($ID_BYTES) ); # 168 bits
    $id =~ s/\n//m;

    return $id;
}

# -----------------------------------------------------------------------------

1;

=encoding utf8

=head1 NAME

MojoX::Security::Session - Secure cookie/memcached session manager

=head1 SYNOPSIS

  use MojoX::Security::Sessions;

  $self->sessions(
     MojoX::Security::Session->new->on(
        before_load  => sub { my ($c, $id) = @_; },
        after_store  => sub { my ($c, $id) = @_; },
        after_load   => sub { my ($c, $id, $session) = @_; },
        before_store => sub { my ($c, $id, $session) = @_; },
        verify       => sub {
            my ($cb, $c, $id, $session) = (pop,@_);

            $cb->(1); # Accept session
            $cb->(0); # Reject session
        },
     )
  );

  # or

  $self->plugin('MojoX::Security::Session::Plugin',
         domain => '....',
         secure => 1/0,
         hooks  => {
             before_load  => sub { my ($c, $id) = @_; },
             after_load   => sub { },
             before_store => sub { },
             after_store  => sub { },
             verify       => sub { },
         }
  );


=head1 DESCRIPTION

L<Mojox::Security::Session:> overrides the L<Mojolicious> session handling
to provide secure, hijack resistant session management with server-side storage.
Session IDs are carried by client side cookies.

=head1 SECURITY

=head2 SESSION ID

The session ID carried by the client side cookie consists of the following key
components:

=over 2

=item * Session identifier

This is a randomly generated identifier that remains static for the duration of
the session.

By default, this is 160 bits which safely provides for 1.09951162778e+12 unique
sessions (168 - 128 = 40 -> 2**40 = 1.09951162778e+12)

=item * Sequence number

This is a randomly generated sequence number that changes each time the session
is consumed by the server.

This is a 48 bit number.

=item * Signature

The signature of the Session identifier and Sequence number, included to prevent
modification of the cookie at the client.

=back

The cookie value is set to be the concatination of the three base64 encoded
components, without padding characters '='.

=head1 METHODS

L<Mojox::Security::Session> inherits all methods from L<Mojo::Base> and
implements the following new ones.

=head2 load

  $sessions->load(Mojolicious::Controller->new);

Load session data from signed cookie.

=head2 store

  $sessions->store(Mojolicious::Controller->new);

Store session data in signed cookie.

=head1 Configuration

L<MojoX::Plugin::AnyCache> is used as the caching backend, see its
documentation for more information about cache configuratoin.

=head1 AJAX and Parallel requests

Where content is dynamically loaded into pages or requests may be made in
parallel, session accesses may overlap and falsely trigger a "hijacked sesson"
pattern.

To suppress this, the C<MojoX::Security::Session::Bridge::ignore_hijack> bridge
can be added to such AJAX Mojolicious routes.

=head1 SEE ALSO

L<MojoX::Plugin::AnyCache>, L<Mojolicious>, L<Mojolicious::Sessions>

=cut
