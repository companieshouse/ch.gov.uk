package ChGovUk::Plugins::FilingHistoryExceptions;

use CH::Perl;
use Mojo::Base 'Mojolicious::Plugin';
use CH::Util::FilingHistoryExceptions;
use YAML::XS;

# ------------------------------------------------------------------------------

# Called by Mojolicious when the plugin is registered
sub register {
    my ($self, $app, $config) = @_;

    $self->load_filing_history_exceptions($app);

    $app->helper(fhe_lookup => sub {
        my ($c, $id, ) = @_;
        return CH::Util::FilingHistoryExceptions::lookup($app, $id, );
    });

    return;
}

# ------------------------------------------------------------------------------

sub load_filing_history_exceptions {
    my ($self, $app) = @_;
    my $yaml = $app->home->rel_file('api-enumerations/filing_history_exceptions.yml');

    %CH::Util::FilingHistoryExceptions::lookup_data = %{
        YAML::XS::LoadFile($yaml)
    };
}

# ------------------------------------------------------------------------------

1;

=head1 NAME

ChGovUk::Plugins::FilingHistoryExceptions

=head1 SYNOPSIS

    use Mojo::Base 'Mojolicious';

    sub startup {
        ...
        $self->plugin('ChGovUk::Plugins::FilingHistoryExceptions');
        ...
    }


=head1 DESCRIPTION

Mojolicious plugin interface for Filing History Exception methods

=head1 METHODS


=head2 register

Called by mojolicious when plugin is registered. Registers the
L<fhe_lookup|/"fhe_lookup"> helpers.

    @param   app    [mojo app]  mojolicious application
    @param   config [hashref]   configuration hash


=head1 EXPORTED HELPERS

=head2 fhe_lookup

Lookup a particular filing history exception string

    @param   id      [number]    id
    @returns string containing matching exception string or undef if doesn't match

Calls L<CH::Util::FilingHistoryExceptions/lookup>.

Example

    % $c.fhe_lookup('filing-history-available-limited-partnership-from-2014');

=cut

