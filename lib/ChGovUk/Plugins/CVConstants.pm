package ChGovUk::Plugins::CVConstants;

use CH::Perl;
use Mojo::Base 'Mojolicious::Plugin';
use CH::Util::CVConstants;
use YAML::XS;

# ------------------------------------------------------------------------------

# Called by Mojolicious when the plugin is registered
sub register {
    my ($self, $app, $config) = @_;

    # Bless the classes
    my %table = %$CH::Util::CVConstants::cv_table;
    for my $class (keys %table) {
        for my $value (keys %{$table{$class}}) {
            next if $value =~ /^class_id$/;
            $table{$class}->{$value} = new CH::Util::CVConstants::Value(
                key   => $value,
                id    => $table{$class}->{$value},
                cv    => $self,
                class => $table{$class},
            );
        }
    };

    $self->load_cvconstants($app);

    $app->helper(cv => sub {
        return $CH::Util::CVConstants::cv_table;
    });

    $app->helper(cv_lookup => sub {
        my ($c, $class, $id, $lang) = @_;

        return CH::Util::CVConstants::lookup($app, $class, $id, $lang);
    });

    return;
}

# ------------------------------------------------------------------------------

sub load_cvconstants {
    my ($self, $app) = @_;
    my $yaml = $app->home->rel_file('api-enumerations/constants.yml');

    # Load the YAML data (synchronously, since this is required for startup)
    %CH::Util::CVConstants::lookup_data = %{ YAML::XS::LoadFile($yaml) };
}

# ------------------------------------------------------------------------------

1;

=head1 NAME

ChGovUk::Plugins::CVConstants

=head1 SYNOPSIS

    use Mojo::Base 'Mojolicious';

    sub startup {
        ...
        $self->plugin('ChGovUk::Plugins::CVConstants');
        ...
    }


=head1 DESCRIPTION

Mojolicious plugin interface for CV Constants methods


=head1 METHODS


=head2 register

Called by mojolicious when plugin is registered. Registers the
L<cv|/"cv"> and L<cv_lookup|/"cv_lookup"> helpers.

    @param   app    [mojo app]  mojolicious application
    @param   config [hashref]   configuration hash


=head1 EXPORTED HELPERS

=head2 cv

Returns the CV table.

    @returns hashref containing cv values

Example

    % my $cv_table = $c.cv;

    % $c.cv.class.class_id;
    % $c.cv.class.const;
    % $c.cv.class.const.description;
    % $c.cv.class.const.value;


=head2 cv_lookup

Lookup a particular CV value

    @param   class   [number]    CV class
    @param   id      [number]    CV id
    @param   lang    [string]    language flag - en or cy
    @returns hashref containing matching description and value or undef doesn't match

Calls L<CH::Util::CVConstants/lookup>.

Example

    % $c.cv_lookup('class', 1);
    % $c.cv_lookup('class', 1).description;
    % $c.cv_lookup('class', 1).value;

=cut


