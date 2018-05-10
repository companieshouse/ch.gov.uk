package ChGovUk::Plugins::FilingHistoryDescriptions;

use CH::Perl;
use Mojo::Base 'Mojolicious::Plugin';
use CH::Util::FilingHistoryDescriptions;
use CH::Util::DateHelper;
use YAML::XS;

# ------------------------------------------------------------------------------

# Called by Mojolicious when the plugin is registered
sub register {
    my ($self, $app, $config) = @_;

    $self->load_filing_history_descriptions($app);

    $app->helper(fhd_lookup => sub {
        my ($c, $id, ) = @_;
        return CH::Util::FilingHistoryDescriptions::lookup($app, $id, );
    });

    $app->helper(format_filing_history_dates => sub {
        my ($c, $doc) = @_;
        _dates_to_strings( $c, $doc->{description_values} );
        map { _dates_to_strings($_); }  @{$doc->{description_values}->{capital}} if exists $doc->{description_values}->{capital};
        map { _dates_to_strings($_); }  @{$doc->{description_values}->{alt_capital}} if exists $doc->{description_values}->{alt_capital};
        for my $subdoc_type ( grep { exists $doc->{$_} } qw( associated_filings resolutions annotations ) ) {
            for my $subdoc ( @{ $doc->{$subdoc_type} } ) {
                _dates_to_strings( $subdoc->{description_values} );
            }
        }

        return $doc;
    });

    return;
}

# ------------------------------------------------------------------------------

sub load_filing_history_descriptions {
    my ($self, $app) = @_;
    my $yaml = $app->home->rel_file('api-enumerations/filing_history_descriptions.yml');

    %CH::Util::FilingHistoryDescriptions::lookup_data = %{
        YAML::XS::LoadFile($yaml)
    };
}

# ------------------------------------------------------------------------------

sub _dates_to_strings {
    my ( $self, $description_values, ) = @_;

    for my $field ( grep { /date$/ } keys %{ $description_values // {} } ) {
        $description_values->{$field} = CH::Util::DateHelper->isodate_as_string( $description_values->{$field} );
    }
}

#-------------------------------------------------------------------------------


1;

=head1 NAME

ChGovUk::Plugins::FilingHistoryDescriptions

=head1 SYNOPSIS

    use Mojo::Base 'Mojolicious';

    sub startup {
        ...
        $self->plugin('ChGovUk::Plugins::FilingHistoryDescriptions');
        ...
    }


=head1 DESCRIPTION

Mojolicious plugin interface for Filing History Description methods

=head1 METHODS


=head2 register

Called by mojolicious when plugin is registered. Registers the
L<fhd_lookup|/"fhd_lookup"> helpers.

    @param   app    [mojo app]  mojolicious application
    @param   config [hashref]   configuration hash


=head1 EXPORTED HELPERS

=head2 fhd_lookup

Lookup a particular filing history description

    @param   id      [number]    CV id
    @param   lang    [string]    language flag - en or cy
    @returns string containing matching description or undef if doesn't match

Calls L<CH::Util::FilingHistoryDescriptions/lookup>.

Example

    % $c.cv_lookup('scheme-of-arrangement');

=head2 load_filing_history_descriptions

    @param  doc     [hashref]   filing history item
    @returns hashref with date fields in the form of '01 Jan 2004'

=cut

