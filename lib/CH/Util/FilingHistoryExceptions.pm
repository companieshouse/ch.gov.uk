package CH::Util::FilingHistoryExceptions;

use CH::Perl;

# Stores data from filing_history_exceptions.yml on API (populated by ChGovUk::Plugins::FilingHistoryExceptions)
our %lookup_data = ();

# ------------------------------------------------------------------------------

sub lookup {
    my ($app, $id) = @_;
    return $lookup_data{exceptions}->{$id};
}

# ------------------------------------------------------------------------------

1;

=head1 NAME

CH::Util::FilingHistoryExceptions

=head1 SYNOPSIS

    use CH::Util::FilingHistoryExceptions;

    # From a template
    $c.fhe_lookup( 'filing-history-not-available-scottish-royal-charter' )

=head2 [HashRef] lookup( $id )

Returns the exception corresponding to the id

	@param   id    [String]       Filing History Exception ID / key string

=cut


