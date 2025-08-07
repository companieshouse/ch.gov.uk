package ChGovUk::Plugins::MortgageDescriptions;

use CH::Perl;
use Mojo::Base 'Mojolicious::Plugin';
use CH::Util::MortgageDescriptions;
use YAML::XS;

# ------------------------------------------------------------------------------

# Called by Mojolicious when the plugin is registered
sub register {
    my ($self, $app, $config) = @_;

    $self->load_mortgage_descriptions($app);

    $app->helper(md_lookup => sub {
        my ($c, $class, $id, ) = @_;
        return CH::Util::MortgageDescriptions::lookup($app, $class, $id, );
    });
}

# ------------------------------------------------------------------------------

sub load_mortgage_descriptions {
    my ($self, $app) = @_;

    %CH::Util::MortgageDescriptions::lookup_data = %{
        YAML::XS::LoadFile($app->home->rel_file . '/api-enumerations/mortgage_descriptions.yml')
    };
}

# ------------------------------------------------------------------------------

1;

=head1 NAME

ChGovUk::Plugins::MortgageDescriptions

=head1 SYNOPSIS

    use Mojo::Base 'Mojolicious';

    sub startup {
        ...
        $self->plugin('ChGovUk::Plugins::MortgageDescriptions');
        ...
    }


=head1 DESCRIPTION

Mojolicious plugin interface for Mortgage Description methods

=head1 METHODS


=head2 register

Called by mojolicious when plugin is registered. Registers the
L<md_lookup|/"md_lookup"> helpers.

    @param   app    [mojo app]  mojolicious application
    @param   config [hashref]   configuration hash


=head1 EXPORTED HELPERS

=head2 md_lookup

Lookup a particular mortgage description

    @param   class   [string]    the class to look in
    @param   id      [string]    the value to lookup
    @param   lang    [string]    language flag - en or cy
    @returns string containing matching description or undef if doesn't match

Calls L<CH::Util::MortgageDescriptions/lookup>.

Example

    % $c.md_lookup('status', 'satisfied');

=head2 load_mortgage_descriptions

    @param  doc     [hashref]   mortgage item
    @returns hashref

=cut

