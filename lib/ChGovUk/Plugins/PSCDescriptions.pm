package ChGovUk::Plugins::PSCDescriptions;

use CH::Perl;
use Mojo::Base 'Mojolicious::Plugin';
use CH::Util::PSCDescriptions;
use CH::Util::DateHelper;
use YAML::XS;

# ------------------------------------------------------------------------------

# Called by Mojolicious when the plugin is registered
sub register {
    my ($self, $app, $config) = @_;

    $self->load_psc_descriptions($app);

    $app->helper(psc_lookup => sub {
        my ($c, $id, $class) = @_;
        return CH::Util::PSCDescriptions::lookup($app, $id, $class);
    });

    return;
}

# ------------------------------------------------------------------------------

sub load_psc_descriptions {
    my ($self, $app) = @_;
    my $yaml = $app->home->rel_file('api-enumerations/psc_descriptions.yml');

    %CH::Util::PSCDescriptions::lookup_data = %{
        YAML::XS::LoadFile($yaml)
    };
}

#-------------------------------------------------------------------------------


1;
