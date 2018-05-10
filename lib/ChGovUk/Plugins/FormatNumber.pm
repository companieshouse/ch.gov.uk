package ChGovUk::Plugins::FormatNumber;

use Mojo::Base 'Mojolicious::Plugin';
use CH::Perl;
use CH::Util::FormatNumber;

# ------------------------------------------------------------------------------ 

# Called by Mojolicious when the plugin is registered
sub register {
    my ($self, $app) = @_;
    
    $app->helper(format_number => sub {
        my ($c, $number) = @_;
        return CH::Util::FormatNumber->format($number);
    });

    return;
}

# ------------------------------------------------------------------------------ 

1;
