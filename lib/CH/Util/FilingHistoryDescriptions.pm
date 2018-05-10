package CH::Util::FilingHistoryDescriptions;

use CH::Perl;

# Stores data from filing_history_descriptions.yml on API (populated by ChGovUk::Plugins::FilingHistoryDescriptions)
our %lookup_data = ();

# ------------------------------------------------------------------------------ 

sub lookup {
    my ($app, $id) = @_;
    if ( exists $lookup_data{description}->{$id} ) { 
        trace "LOOKUP ID [%s] [%s]", $id, $lookup_data{description}->{$id} [FILING HISTORY DESCRIPTIONS];
    }
    else {
        error "No description found corresponding to ID [%s]", $id [FILING HISTORY DESCRIPTIONS];
    }
    return $lookup_data{description}->{$id} // '';
}

# ------------------------------------------------------------------------------

1;

=head1 NAME

CH::Util::FilingHistoryDescriptions

=head1 SYNOPSIS

    use CH::Util::FilingHistoryDescriptions;

    # From a template
    $c.fhd_lookup( 'scheme-of-arrangement' )

=head2 [HashRef] lookup( $id )

Returns the description corresponding to the id

	@param   id    [String]       Filing History Description ID / key string

=cut


