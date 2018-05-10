package ChGovUk::Plugins::FilterHelper;

use Mojo::Base 'Mojolicious::Plugin';
use CH::Perl;
use Mojo::Util qw( url_unescape url_escape );

# ------------------------------------------------------------------------------ 

# Called by Mojolicious when the plugin is registered
sub register {
    my ($self, $app) = @_;

    trace "Registering %s::get_filter helper", __PACKAGE__ [APP];
    $app->helper(get_filter => sub {
        my ($c, $filter_name) = @_;
        
        my $params = _populate_stash($c);
        return $params->to_hash->{$filter_name} || '';
    });
    $app->helper(set_filter => sub {
        my ($c, $filter_name, $value) = @_;
        
        my $params = _populate_stash($c);
        $params->merge({$filter_name => $value});
        
        return ;
    });
    
    $app->hook( around_action => sub {
        my ($next, $c, $action, $last) = @_;
        my $done = $next->();
        
        my $params = _populate_stash($c);

        # put the query params into the cookie after url escaping
        $c->cookie( 'sft' => url_escape($params->to_string), {path => '/company'} );
        
        return $done;
    } );

    return;
}

# ------------------------------------------------------------------------------ 

sub _populate_stash {
    my ($c) = @_;
    
    return $c->stash('results_filter') if defined $c->stash('results_filter');
    
    my $params;
    
    my $cookie = $c->cookie('sft');
    if (defined $cookie) {
        if ($cookie eq '1') {
            $params = Mojo::Parameters->new('fh_type=1'); # special case for legacy cookie with value '1' -> convert to new cookie format
        } else {
            $params = Mojo::Parameters->new( url_unescape($cookie) );
        }
    } else {
        $params = Mojo::Parameters->new;
    }
    
    $c->stash('results_filter', $params);  
    return $c->stash('results_filter');
}

# ------------------------------------------------------------------------------ 

1;

=head1 NAME

ChGovUk::Plugins::FilterCookie

=head1 SYNOPSIS

    sub startup {
        ...
        $self->plugin( 'ChGovUk::Plugins::FilterCookie' );
        ...
    }

=head1 METHODS

=head2 register

Called by mojolicious when plugin is registered. Registers the
L</get_filter> andL</set_filter> helpers.

    @param   app    [mojo app]  mojolicious application

=head1 EXPORTED HELPERS

=head2 get_filter

Checks the filter cookie (sft) for a value for the given filter name

    @param   name   [string]  string denoting the name of the filter to get.
    @returns string "comma separated list of filters for the given filter name"

=head2 set_filter

Updates the filter cookie (sft) with a value for the given filter name

    @param   name   [string]  the name of the filter.
    @param   filter [string]  the value to store in the cookie for the filter name.

=cut
