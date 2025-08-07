package ChGovUk::Plugins::DateHelpers;

use Mojo::Base 'Mojolicious::Plugin';
use CH::Perl;
use CH::Util::DateHelper;

# ------------------------------------------------------------------------------ 

# Called by Mojolicious when the plugin is registered
sub register {
    my ($self, $app) = @_;

    $app->log->trace("Registering " . __PACKAGE__ . "::date_as_string helper [APP]");
    $app->helper(date_as_string => sub {
        my ($c, $date, $optional_format) = @_;
        return CH::Util::DateHelper->as_string($date, $optional_format);
    });
    $app->helper(datetime_as_local_string => sub {
        my ($c, $date) = @_;
        return CH::Util::DateHelper->as_local_string($date);
    });
    $app->helper(isodatetime_as_string => sub {
        my ($c, $date, $optional_format) = @_;
        return CH::Util::DateHelper->isodatetime_as_string($date, $optional_format);
    });
    $app->helper(isodate_as_string => sub {
        my ($c, $date, $optional_format) = @_;
        return CH::Util::DateHelper->isodate_as_string($date, $optional_format);
    });
    $app->helper(isodate_as_short_string => sub {
        my ($c, $date) = @_;
        return CH::Util::DateHelper->isodate_as_string($date, "%d %b %Y");
    });
    $app->helper(isodatetime_as_short_string => sub {
        my ($c, $date) = @_;
        return CH::Util::DateHelper->isodatetime_as_string($date, "%d %b %Y %T");
    });
    $app->helper(suppressed_date_as_string => sub {
        my ($c, $date) = @_;
        return CH::Util::DateHelper->suppressed_date_to_string($date);
    });
    $app->helper(day_month_as_string => sub {
        my ($c, $day, $month) = @_;
        return CH::Util::DateHelper->day_month_as_string($day, $month);
    });

    return;
}

# ------------------------------------------------------------------------------ 

1;

=head1 NAME

ChGovUk::Plugins::DateHelpers

=head1 SYNOPSIS

    sub startup {
        ...
        $self->plugin( 'ChGovUk::Plugins::DateHelpers' );
        ...
    }

=head1 METHODS

=head2 register

Called by mojolicious when plugin is registered. Registers the
L</date_as_string> helper.

    @param   app    [mojo app]  mojolicious application

=head1 EXPORTED HELPERS

=head2 date_as_string

Converts a date-like string, CH::Models::Date or DateTime::Tiny object into a
string. An optional strftime format can be passed.

    @param   date   [string|object]  string in format of (d|dd)-(m|mm)-yyyy or (d|dd)/(m|mm)/yyyy or
                                     DateTime::Tiny object or
                                     CH::Models::Date object.
    @param   format [string]         Optional string that represents a strftime format.
    @returns string "(d|dd) month_name yyyy"

=cut

