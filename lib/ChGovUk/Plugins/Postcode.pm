package ChGovUk::Plugins::Postcode;

use Mojo::Base 'Mojolicious::Plugin';

use CH::Perl;
use Try::Tiny;
use CH::Util::AddressFieldValidate;
use Mojo::Util qw/ url_escape /;
use Mojo::UserAgent;

has 'app';

# ========================================================| MOJO INTERFACE |====

# Call by Mojolicious when the plugin is registered
sub register {
    my ($self, $app) = @_;

    $self->app($app);

    #trace "Registering %s::lookup as postcode_lookup helper", __PACKAGE__ [APP];
    $app->log->trace("Registering " . __PACKAGE__ . "::lookup as postcode_lookup helper [APP]");
    $app->helper(postcode_lookup => sub{
            my $controller = shift;
            return $self->lookup(@_)
        });

    return;
}

# ================================================================| PUBLIC |====


sub lookup {
    my ($self, $postcode, $callback) = @_;

    #trace "Looking up postcode: $postcode";
    $self->app->log->trace("Looking up postcode: $postcode");

    $postcode =~ s/\s*//g;
    
    my $url = $self->app->config->{postcode}->{url} . '/' . url_escape($postcode);
    #trace "Postcode URL=$url";
    $self->app->log->trace("Postcode URL=$url");

    # FIXME Use Admin::Net::CompaniesHouse so that the call is authenticated
    my $pcua = Mojo::UserAgent->new();
    $pcua->get($url => sub {
        my ($ua, $tx) = @_;
        
        my $keep_scope = $pcua; # Stop pcua going out of scope. FIXME Not needed when using Admin::NET::Companieshouse

        if ($tx->success) {
            #trace "Postcode lookup complete: %s", d:$tx->res->json [POSTCODE];
            $self->app->log->trace("Postcode lookup complete: " . $tx->res->json . " [POSTCODE]");
            $callback->($tx->res->json);
        } elsif (defined $tx->res->code and $tx->res->code == 404) {
            #trace "Postcode service failed to find postcode %s", $postcode [POSTCODE];
            $self->app->log->trace("Postcode service failed to find postcode $postcode [POSTCODE]");
            $callback->({ invalid_postcode => 1 });
        } else {
            #error "Unexpected response received from postcode service" [POSTCODE];
            $self->app->log->error("Unexpected response received from postcode service [POSTCODE]");
            $callback->({ postcode_error => 1 });
        }
    });
}

# ============================================================================== 

1;

=head1 NAME

ChGovUk::Plugins::Postcode

=head1 SYNOPSIS

    use Mojo::Base 'Mojolicious';

    sub startup {
        ...
        $self->plugin('ChGovUk::Plugins::Postcode');
        ...
    }


=head1 DESCRIPTION

Postcode lookup utility plugin


=head1 METHODS

=head2 register

Called to register the plugin with the mojolicious framework. Registers the
L<lookup|/"lookup_postcode"> helper.

	@param   app  [object]     mojolicious application


=head2 lookup

Attempts to lookup address for the given postcode.

    @param   postcode [string]  postcode to lookup address for 
    @returns the address associated with the postcode which will contain
             fields for post_code, address_line1, address_line2, county and
             country.

=cut

=head1 EXPORTED HELPERS

=head2 lookup_postcode

Helper alias to L<lookup|/"lookup">.

Example

    % my $address = $c.lookup( $a_postcode );

=cut
