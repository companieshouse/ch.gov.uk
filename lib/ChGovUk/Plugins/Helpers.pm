package ChGovUk::Plugins::Helpers;

use CH::Perl;
use Mojo::Base 'Mojolicious::Plugin';

# =============================================================================

sub register {
    my ($self, $app) = @_;

    $app->helper(base_url         => \&_base_url);
    $app->helper(external_url_for => \&_external_url_for);
    $app->helper(parent_url_for   => \&_parent_url_for);

	# Helper to return the current URL for a different language
    $app->helper(url_for_lang => sub {
        my $self = shift;
        my $lang = shift;
        my $url  = $self->req->url->to_abs;

        $url->host($self->config->{languages}{$lang}{host});

        return $url;
    });

    $app->helper(is_selected   => \&_is_selected);

    return;
}

# -----------------------------------------------------------------------------

sub _base_url {
    my ($app) = @_;

    my $url = 'http'
              . ($app->req->is_secure ? 's' : '')
              . '://'
              . $app->req->url->base->host
              . ( $app->req->url->base->port != 80
                            ? ':' . $app->req->url->base->port
                            : ''
                )
              . '/';
    return $url
}

# -----------------------------------------------------------------------------

sub _external_url_for {
    my $app  = shift;
    my $name = shift;
    my $arg  = ref($_[0]) eq 'HASH' ? shift : {@_};
    my $url;

    unless (exists($app->config->{external_url_for}{$name})) {
        error "Cannot find external_url_for [%s] in config", $name [HELPERS];
        return;
    }

    $url = new Mojo::URL($app->config->{external_url_for}{$name});
    debug "Got external_url_for [%s] in config", $name [HELPERS];

    my $pattern = new Mojolicious::Routes::Pattern($url->path);
    $url->path($pattern->render($arg));

    return $url;
}

# -----------------------------------------------------------------------------

sub _parent_url_for {
    my $app  = shift;

    my $url_for = $app->url_for;

    $url_for->path(Mojo::Path->new($url_for->path . '/..')->canonicalize);

    return $url_for;
}

# -----------------------------------------------------------------------------

# TODO GCI-1305 Is a helper function the best way to do this?
# TODO GCI-1305 Remove/replace all warns.

sub _is_selected {
    my $app  = shift;
    my $document_id = shift;
    my $selected_documents = shift;

    warn "_is_selected(".$document_id.", ".$selected_documents.")";

    my $found = 0;
    if (!defined $selected_documents) {
        warn "_is_selected() returning 0 as \$selected_documents is not defined.";
        return $found;
    }

    my @selected_documents;
    if (ref($selected_documents) eq 'ARRAY')
    {
        warn "_is_selected(): Already an array, no conversion required.";
        @selected_documents = @{$selected_documents};
    }
    else
    {
        warn "_is_selected(): Converting a scalar to an array";
        @selected_documents = [$selected_documents];
    }

    warn "_is_selected(".$document_id.", ".@selected_documents.")";

    if (ref(@selected_documents) eq 'ARRAY') {
        warn "_is_selected(): ARRAY";
    } else {
        warn "_is_selected(): NOT AN ARRAY!";
    }

    foreach my $filing_history_id (@selected_documents) {
        warn ">>> ".$filing_history_id;
        if ($filing_history_id eq $document_id) {
            $found = 1;
            # TODO GCI-1305 Can we come out iteration?
        }
    };

    warn "Returning ".$found;
    return $found;
}


1;

=head1 NAME

ChGovUk::Plugins::Helpers

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 [void] register( $app )

Called to register the plugin with the mojolicious framework

	@param   app  [object]     mojolicious application

=head2 [string] _base_url

Get a base url from the current request

    @param   app  [object]  reference to the controller
    @returns the base url as a string

=cut


