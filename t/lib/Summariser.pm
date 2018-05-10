package Summariser;

use CH::Perl;
use Moose;
use Test::Mojo;
use Mojo::URL;

#-------------------------------------------------------------------------------------------

has '_ua'            => ( is => 'rw', isa => 'Mojo::UserAgent', lazy => 1, builder => '_build_ua',  );
has '_url'           => ( is => 'rw', isa => 'Mojo::URL',       lazy => 1, builder => '_build_url', );

#-------------------------------------------------------------------------------------------

sub _build_url {
    my ( $self ) = @_;

    die "_build_url must be overridden";
}

#-------------------------------------------------------------------------------

sub _build_ua {
    my ( $self ) = @_;

    return Mojo::UserAgent->new;
}

#-------------------------------------------------------------------------------------------

sub initial_summary {
    return {
        top_level_total => 0,
        subdoc_total    => 0,
        combined_total  => 0,
        officer_total   => 0,
        incorporation_date        => '',
        accounting_reference_date => '',
        last_return_to            => '',
        next_return_to            => '',
        next_accounts_due         => '',
        last_accounts_to          => '',
        accounts_type             => '',
        charges                   => '',
        top_level       => {},
        subdoc          => {},
        combined        => {},
        officers        => {},
    };
}

#-------------------------------------------------------------------------------------------

sub increment_summary {
    my ( $self, $summary, $level, $type, $year_month_day ) = @_;

    # Live CHD and test CHS will diverge after test database snapshot date
    my $latest_year_month_day = '20130122';

    if ( $type eq 'SH01' && $level eq 'subdoc' ) {
        # note "Discard SH01 sub docs as cannot be compared";
        return $summary;
    }
#    if ( $year_month_day gt '20130122' ) {
#        note "Skipping form $type date $year_month_day as too recent";
#        return $summary;
#    }
    $summary->{$level}->{$type}++;
    $summary->{$level.'_total'}++;
    $summary->{combined}->{$type}++;
    $summary->{combined_total}++;
    push @{ $summary->{date_combined}->{$type} }, $year_month_day;
    return $summary;
}

#-------------------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;
