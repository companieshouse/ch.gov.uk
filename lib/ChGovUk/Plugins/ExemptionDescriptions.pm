package ChGovUk::Plugins::ExemptionDescriptions;

use CH::Perl;
use Mojo::Base 'Mojolicious::Plugin';
use CH::Util::ExemptionDescriptions;
use CH::Util::DateHelper;
use YAML::XS;

# ------------------------------------------------------------------------------

# Called by Mojolicious when the plugin is registered
sub register {
    my ($self, $app, $config) = @_;

    $self->load_exemption_descriptions($app);

    $app->helper(exemption_lookup => sub {
        my ($c, $id, $class) = @_;
        return CH::Util::ExemptionDescriptions::lookup($app, $id, $class);
    });

    return;
}

# ------------------------------------------------------------------------------

sub load_exemption_descriptions {
    my ($self, $app) = @_;
    my $yaml = $app->home->rel_file('api-enumerations/exemption_descriptions.yml');

    %CH::Util::ExemptionDescriptions::lookup_data = %{
        YAML::XS::LoadFile($yaml)
    };
}

#-------------------------------------------------------------------------------


1;
