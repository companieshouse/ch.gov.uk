package ChGovUk::Plugins::DisqualifiedOfficerDescriptions;

use Mojo::Base 'Mojolicious::Plugin';

use CH::Perl;
use YAML::XS;

my %data = ();

# ------------------------------------------------------------------------------

sub register {
    my ($self, $app, $config) = @_;

    $self->_load_disqualified_officer_descriptions($app);

    $app->helper(disqualified_officer_description_lookup => sub {
        my ($c, $class, $id) = @_;

        return $data{$class}->{$id} if exists $data{$class}->{$id};

        warn 'No value found for id [%s] in class [%s]', $id, $class;

        return undef;
    });

    return;
}

# ------------------------------------------------------------------------------

sub _load_disqualified_officer_descriptions {
    my ($self, $app) = @_;

    my $yaml_file = $app->home->rel_file('api-enumerations/disqualified_officer_descriptions.yml');
    %data = %{ YAML::XS::LoadFile($yaml_file) };
}

# ==============================================================================

1;

=head1 NAME

ChGovUk::Plugins::DisqualifiedOfficerDescriptions

=head1 SYNOPSIS

    use Mojo::Base 'Mojolicious';

    sub startup {
        ...
        $self->plugin('ChGovUk::Plugins::DisqualifiedOfficerDescriptions');
        ...
    }

=head1 DESCRIPTION

Mojolicious plugin for Disqualified Officer Description methods.

=head1 METHODS

=head2 register

Called by Mojolicious when the plugin is registered with the application. Registers the
L<disqualified_officer_description_lookup|/"disqualified_officer_description_lookup">
helpers.

    @param app     [mojo app]  mojolicious application object
    @param config  [hashref]   configuration hash

=head1 HELPERS

=head2 disqualified_officer_description_lookup

Lookup a particular disqualified officer description.

    @param class  [string]  The class (section) of the hash
    @param id     [string]  The lookup key

    @returns description value or undef

=cut
