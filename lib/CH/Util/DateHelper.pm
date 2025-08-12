package CH::Util::DateHelper;

$ENV{LOG_DECLARE_STARTUP_LEVEL} = 'INFO'; # TODO Add suppression to CH::Util::Test

use CH::Perl;
use DateTime::Tiny;
use Date::Calc qw(Delta_Days N_Delta_YMD Add_Delta_Days Add_Delta_YM);
use DateTime::Format::ISO8601;
use POSIX qw(strftime);
use Time::Piece;

use DateTime;

# ------------------------------------------------------------------------------

sub from_internal {
    my ($class, $internal_formatted_date) = @_;

    # Attempt to parse to date and time portions where time is optional
    my ($date, $time) = ($internal_formatted_date =~ /^(\d{8})(\d{6})?$/);

    unless ($date =~ /\d{8}/) {
        error "Cannot convert [%s] to DateTime::Tiny object. Wrong format", $internal_formatted_date||'' [VALIDATION];
        CH::Exception->throw("Unable to parse date");
    }

    my ($year,$month,$day,$hour,$minute,$second) = (0,0,0,0,0,0);

    ($year,$month,$day)
        = ($date =~ /(\d{4})(\d{2})(\d{2})/);

    ($hour,$minute,$second)
        = ($time =~ /(\d{2})(\d{2})(\d{2})/) if $time;

    return DateTime::Tiny->new(
        year    => $year   + 0, # Add the zero to ensure we lose any padding
        month   => $month  + 0,
        day     => $day    + 0,
        hour    => $hour   + 0,
        minute  => $minute + 0,
        second  => $second + 0,
    );
}

# ------------------------------------------------------------------------------

sub to_internal {
    my ($class, $date_obj) = @_;

    if (!$date_obj || ref $date_obj ne 'DateTime::Tiny' ) {
        error "Cannot convert date object to string. Invalid object" [VALIDATION];
        CH::Exception->throw("Unable to parse date object");
    }

    return sprintf("%4d%02d%02d",
        $date_obj->year  || 0,
        $date_obj->month || 0,
        $date_obj->day   || 0
    );
}

# ------------------------------------------------------------------------------

sub is_valid {
    my ($class, $date) = @_;

    if ( ref($date) eq 'DateTime::Tiny' ) {
        $date = $class->to_internal( $date );
    }

    if ($date!~/^\d{8}$/) { return false };

    my $y = substr( $date, 0, 4 ) || 0;
    my $m = substr( $date, 4, 2 ) || 0;
    my $d = substr( $date, 6, 2 ) || 0;

    return $class->is_valid_y_m_d($y, $m, $d);
}

# ------------------------------------------------------------------------------

sub is_valid_y_m_d {
    my ($class, $y, $m, $d) = @_;

    state $days = [ qw/ 31 28 31 30 31 30 31 31 30 31 30 31 / ];
    my $leap = ((!(($y)%4))&&((($y)%100)||(!(($y)%400)))) ? 1 : 0;

    return
        ( $m > 0 && $m < 13 && $d > 0 && $d <= ($days->[$m-1] + (($m == 2) ? $leap : 0) ) && $y > 0 )
        ? true : false;
}

# ------------------------------------------------------------------------------

# flexibly convert thing to DateTime::Tiny


sub to_date_time {

    my ($class, $date) = @_;
    my ($day, $month, $year, $hour, $minute, $second);
    if (ref($date) eq 'DateTime::Tiny') {
        return $date;
    }
    elsif (ref($date) eq 'ChGovUk::Models::Date') {
        ($day, $month, $year) = ($date->day, $date->month, $date->year);
    }
    elsif (ref($date) eq 'DateTime') {
       $year = substr $date,0,4;
       $month = substr $date, 5,2;
       $day = substr $date, 8,2;
    }
    elsif ($date =~ /^$/) {
        return undef;
    }
    elsif ($date =~ m@^(\d{1,2})([-/])(\d{1,2})\2(\d{4})$@) {
        ($day, $month, $year) = ($1, $3, $4);
    }
    elsif ($date =~ /^ (\d{4})(\d{2})(\d{2}) (?: (\d{2})(\d{2})(\d{2}) )? $/x) {
        ($year, $month, $day, $hour, $minute, $second) = ($1, $2, $3, $4, $5, $6);
    }
    # ISO 8601 format
    elsif ($date =~ m@^
                            (\d{4}) -? (\d{2}) -? (\d{2})
                            T
                            (\d{2}) :? (\d{2}) :? (\d{2})
                            (?:
                                [+\-] \d{2} :? \d{2}
                            )?
                        $@x) {
        ($year, $month, $day, $hour, $minute, $second) = ($1, $2, $3, $4, $5, $6);
    }
    elsif ($date =~ /^ -*(\d{8}) /x){
        $date   = DateTime->from_epoch( epoch=>$date/1000 );
        $year   = substr $date, 0,4;
        $month  = substr $date, 5,2;
        $day    = substr $date, 8,2;
        $hour   = $date->hour;
        $minute = $date->minute;
        $second = $date->second;

    }
    else {
        error "Unable to parse invalid date '%s'", d:$date [VALIDATION];
        CH::Exception->throw('Unable to parse date - Cannot process [' . $date . ']');
    }
    return DateTime::Tiny->new(
        year => $year, month  => $month,  day    => $day,
        hour => $hour, minute => $minute, second => $second,

    );
}

# ------------------------------------------------------------------------------

# TODO Consider using DateTime which has language/locale support
# TODO language switching
sub as_string {
    my ($class, $date, $format) = @_;

    # Workaround for dates that may have no value i.e secretary DOB
    return '' if !defined $date || length($date) == 0;

    $format //= "%e %B %Y";

    my $tiny_date = $class->to_date_time($date);

    $date = strftime($format, $tiny_date->second, $tiny_date->minute, $tiny_date->hour, $tiny_date->day, ($tiny_date->month - 1), ($tiny_date->year - 1900));
    return $date =~ s/^\s//r;
}

# ------------------------------------------------------------------------------

sub as_local_string {
    my ($class, $date) = @_;

    return '' if !defined $date || length($date) == 0;

    if ($date !~ /^[0-9]*$/) {
        error "Unable to parse invalid date [%s]", d:$date [VALIDATION];
        CH::Exception->throw('Unable to parse date - Cannot process [' . $date . ']');
    }

    my $new_date = localtime->new(int($date/1000))->strftime("%d %b %Y %T");

    return $new_date;
}

# ------------------------------------------------------------------------------

sub is_date_greater {
    my ($class, $first_date, $second_date) = @_;

    if ( $first_date !~ /\d{8}/ ){
        $first_date = $class->to_internal($first_date);
    }

    if ( $second_date !~ /\d{8}/ ){
        $second_date = $class->to_internal($second_date);
    }
    $first_date <= $second_date ? return 1 : return 0;
}

# ------------------------------------------------------------------------------

sub is_current_date_greater {
    my ($class, $date) = @_;
    $date =~ s/\-//g;
    my $date_tiny = $class->to_date_time($date);
    return $class->is_date_greater( $date_tiny, DateTime::Tiny->now );

}

# ------------------------------------------------------------------------------

sub add_date_YMD {
    my ($class, $date, $delta_year, $delta_month, $delta_day) = @_;

    $date = $class->to_internal($date);

    my $year  = substr($date,0,4);
    my $month = substr($date,4,2);
    my $day   = substr($date,6,2);

    my ($new_year, $new_month, $new_day)
        = Date::Calc::Add_Delta_Days(
                Date::Calc::Add_Delta_YM(
                        $year,$month,$day,$delta_year,$delta_month
                ),
          $delta_day);

    return DateTime::Tiny->new(
        year  => $new_year  + 0, # Add the zero to ensure we lose any padding
        month => $new_month + 0,
        day   => $new_day   + 0,
    );
}

# -----------------------------------------------------------------------------

sub days_between {
    my $class = shift;
    my $from  = $class->to_internal(shift);
    my $to    = shift;

    my @to = ();
    if (defined $to) {
        if (not ref $to) {
            error "Need date object as second arg." [VALIDATION];
            CH::Exception->throw("Expected to date to be object");
        }
        @to = ($to->year, $to->month, $to->day);
    } else {
        @to = Date::Calc::Today();
    }

    $from =~ s/\s+//g;

    return '' unless ($from);

    my $from_y = substr( $from, 0, 4 );
    my $from_m = substr( $from, 4, 2 );
    my $from_d = substr( $from, 6, 2 );

    return Date::Calc::Delta_Days($from_y, $from_m, $from_d,
                                  @to);

}

# -----------------------------------------------------------------------------

sub isodate_as_string {
    my ($class, $date, $format) = @_;

    if ( ref $date eq 'HASH' && exists $date->{'$date'} ) {
        $date = $date->{'$date'} // '';
    }
    return '' if !defined $date || length($date) == 0;

    if ($date !~ /^(\d{4})-?(\d{2})-?(\d{2})T(\d{2}):?(\d{2}):?(\d{2})|(\d{4})-?(\d{2})-?(\d{2})$/) {
        error "Unable to parse invalid date [%s]", d:$date [VALIDATION];

        CH::Exception->throw('Unable to parse date - Cannot process [' . $date . ']');
    }

    $format //= '%e %B %Y';

    my $iso = DateTime::Format::ISO8601->parse_datetime( $date );
    $iso->set_time_zone('UTC');
    $iso->set_time_zone('Europe/London');

    my $fmt_iso = $iso->strftime($format);
    $fmt_iso =~ s/^\s+//;

    return $fmt_iso;
}

# -----------------------------------------------------------------------------

sub isodatetime_as_string {
    my ($class, $date, $format) = @_;

    return '' if !defined $date || length($date) == 0;

    if ($date !~ /^(\d{4})-?(\d{2})-?(\d{2})T(\d{2}):?(\d{2}):?(\d{2})$/) {
        error "Unable to parse invalid date [%s]", d:$date [VALIDATION];
        CH::Exception->throw('Unable to parse date - Cannot process [' . $date . ']');
    }

    $format //= '%e %B %Y %T';
    return $class->isodate_as_string($date, $format);
}

# -----------------------------------------------------------------------------

sub isotime_as_string {
    my ($class, $date) = @_;

    my $iso = DateTime::Format::ISO8601->parse_datetime( $date );
    $iso->set_time_zone('UTC');
    $iso->set_time_zone('Europe/London');

    return $iso;
}

# -----------------------------------------------------------------------------

sub suppressed_date_to_string {
    my ($class, $date) = @_;

    # Set the day to 01 to bypass date validation in the `isodate_as_string` call,
    # this value is arbitrary as it won't be captured within our formatted date.
    my $day   = sprintf '%02s', '01';
    my $month = sprintf '%02s', $date->{month};
    my $year  = $date->{year};

    return $class->isodate_as_string("$year-$month-$day", '%B %Y');
}

# ------------------------------------------------------------------------------

sub day_month_as_string {
    my ($class, $day, $month) = @_;

    my @abbr = qw(January Feburary March April May June July August September October November December);
    return "$day $abbr[$month-1]";
}

1;

=head1 NAME

CH::Util::DateHelper

=head1 SYNOPSIS

    use CH::Util::DateHelper;

    my $date_obj = DateTime::Tiny->new();
    my $date_str = '20010412';

    my $date_obj_from = CH::Util::DateHelper->from_internal( $date_str );

    my $date_str_to = CH::Util::DateHelper->to_internal( $date_obj );

    my $valid_obj = CH::Util::DateHelper->is_valid( $date_obj );
    my $valid_str = CH::Util::DateHelper->is_valid( $date_str );

=head1 DESCRIPTION

Date utility functions.

=head1 METHODS

=head2 from_internal

Convert an 'internal format' date string (C<yyyymmdd> or C<yyyymmddHHMMSS>)
into a C<DateTime::Tiny> instance.

Does not perform any date validation. It is left up to the caller how to
interpret the resulting object.

    @param   internal_formatted_date    [string]    date string to convert
    @returns new DateTime::Tiny instance

Example

    my $date_obj = CH::Util::DateHelper->from_internal('20130820');


=head2 to_internal

Convert a C<DateTime::Tiny> object instance into a C<yyyymmdd> 'internal'
formatted date string.

Does not perform any date validation. It is left up to the caller how to
interpret the resulting string.  Ignores any B<time> elements.

    @param   date_obj   [DateTime::Tiny]    a DateTime::Tiny object
    @returns yyyymmdd   [string]            date string

Example

    my $internal = CH::Util::DateHelper->to_internal($date_obj);


=head2 is_valid

Test whether a date is valid as a real date (ignores any time element).

    @param   date     [string|object]  either internal format string or
                                       DateTime::Tiny object.
    @returns is_valid boolean          true if C<date> is valid

Example

    if (CH::Util::DateHelper->is_valid( '20010402' )) {
        return 1;
    }
    return 0;


=head2 is_valid_y_m_d

Test whether the date represented by the arguments are a valid date.

    @param   year      int
    @param   month     int
    @param   day       int
    @returns is_valid  boolean      true iff arguments make a valid date

Example

    if (CH::Util::DateHelper->is_valid_y_m_d( 2001, 10, 2 )) {
        return 1;
    }
    return 0;


=head2 as_string

Converts a date-like string, ChGovUk::Models::Date or DateTime::Tiny object into a
string. An optional strftime format can also be passed.

Will return '--' if passed ''.

    @param   date     [string|object] string in one of the following formats:
                                      - "(d|dd)-(m|mm)-yyyy"
                                      - "(d|dd)/(m|mm)/yyyy"
                                      - "yyyymmdd"
                                      - DateTime::Tiny object
                                      - ChGovUk::Models::Date object
    @param   format   [string]        Optional string that represents a strftime format.
                                      Defaults to "%e %B %Y"
    @returns str_date [string]        "(d|dd) month_name yyyy" (or '--' if C<date> was '')

Example

    my $date_model = ChGovUk::Models::Date->new(
        year  => 2013,
        month => 12,
        day   => 13,
    );

    say CH::Util::DateHelper->as_string("13-12-2013");         # 13 December 2013
    say CH::Util::DateHelper->as_string($date_model);          # 13 December 2013
    say CH::Util::DateHelper->as_string($date_model->to_date); # 13 December 2013

=head2 to_date_time

Flexibly convert a string or object to a DateTime::Tiny object.
Will throw an exception if the C<date> parameter is not an expected value.

Does not validate the date or time (see L<is_valid>).

    @param   date   [string|object]  string or object (DateTime::Tiny or ChGovUk::Models::Date or MongoDB ISODate object((comes as a long string ))
                                     - string "(d|dd)-(m|mm)-yyyy" or "(d|dd)/(m|mm)/yyyy"
                                     - string "yyyymmdd" or "yyyymmddHHMMSS"
                                     - object: DateTime::Tiny or ChGovUk::Models::Date
                                     - epoch time (in milliseconds!)
    @returns object [DateTime::Tiny] object that represents the C<date> parameter

Examples


    $tiny_date = CH::Util::DateHelper->to_date_time("20201231");
    $tiny_date = CH::Util::DateHelper->to_date_time("20/2/2031");

    my $date_model = ChGovUk::Models::Date->new( year=>2013, month=>12, day=>13 );
    $tiny_date = CH::Util::DateHelper->to_date_time( $date_model );

=head2 days_between

Calculate days between dates, (if one date argument, assume now)

=over

    @param   from_date    date    date object
    @param   to_date      date    optional date object, default is now

    @returns days         int     number of days

=back

Get the number of C<days> between C<from_date> and C<to_date> (or now).

If C<from_date> precedes (or is) C<to_date> then C<days> will be non-negative,
else it will be negative.

=head2 day_month_as_string

Convert the numeric values for day and month into a string

    @param day   [string]  string in the format of 1-31
    @param month [string]  string in the format of 1-12

    @returns     [string]  in the format of "1 June"

=cut
