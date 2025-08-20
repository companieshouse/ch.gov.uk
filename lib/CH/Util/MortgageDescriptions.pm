package CH::Util::MortgageDescriptions;

use CH::Perl;

# Stores data from mortgage_descriptions.yml on API (populated by ChGovUk::Plugins::MortgageDescriptions)
our %lookup_data = ();

# ------------------------------------------------------------------------------

sub lookup {
    my ($app, $class, $id) = @_;
    if ( exists $lookup_data{$class}->{$id} ) {
        $app->log->trace("LOOKUP CLASS [$class] ID [$id] [" . $lookup_data{$class}->{$id} . "] [MORTGAGE DESCRIPTIONS]");
    }
    else {
        $app->log->error("No description found corresponding to CLASS [$class] ID [$id] [MORTGAGE DESCRIPTIONS]");
    }
    return $lookup_data{$class}->{$id} // '';
}

# ------------------------------------------------------------------------------

1;

=head1 NAME

CH::Util::MortgageDescriptions

=head1 SYNOPSIS

    use CH::Util::MortgageDescriptions;

    # From a template
    $c.md_lookup( 'status', 'satisfied' )

=head2 [HashRef] lookup( $class, $id )

Returns the description corresponding to the id

    @param   class [String]       Mortgage Description class string
	@param   id    [String]       Mortgage Description id string

=cut


