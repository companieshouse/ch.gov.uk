package ChGovUk::Plugins::JWE;

use CH::Perl;

use Mojo::Base 'Mojolicious::Plugin';

use JSON::WebEncryption;
use MIME::Base64 qw(decode_base64);

# =============================================================================

sub register {
    my ($self, $app) = @_;

    $app->helper( jwe => sub {
        my ($controller, %args) = @_;

        my $security = $controller->config->{security};

        die "No security section in configuration" unless $security;

        my $oauth2_request_key = $security->{'oauth2_request_key'};

        die "Missing oauth2_request_key in provider security configuration" unless $oauth2_request_key;

        # Return a new instance of this plugin which encapsulates
        # the controller and model
        return JSON::WebEncryption->new(
            enc => 'A128CBC-HS256',
            alg => 'dir',
            key => decode_base64( $oauth2_request_key )
        );
    });
}

# -----------------------------------------------------------------------------
1;
