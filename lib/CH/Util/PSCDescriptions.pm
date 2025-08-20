package CH::Util::PSCDescriptions;

use CH::Perl;

# Stores data from psc_descriptions.yml on API (populated by ChGovUk::Plugins::PSCDescriptions)
our %lookup_data = ();

# ------------------------------------------------------------------------------

sub lookup {
    my ($app, $id, $class ) = @_;
    if ( exists $lookup_data{$class}->{$id} ) {
        $app->log->trace("LOOKUP ID [$id] [" . $lookup_data{$class}->{$id} . "] [PSC DESCRIPTIONS]");
    }
    else {
        $app->log->error("No description found corresponding to ID [$id] [PSC DESCRIPTIONS]");
    }
    return $lookup_data{$class}->{$id} // '';
}

# ------------------------------------------------------------------------------

1;
