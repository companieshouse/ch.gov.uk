package CH::Util::ExemptionDescriptions;

use CH::Perl;

# Stores data from exemption_descriptions.yml on API (populated by ChGovUk::Plugins::ExemptionDescriptions)
our %lookup_data = ();

# ------------------------------------------------------------------------------ 

sub lookup {
    my ($app, $id, $class ) = @_;
    if ( exists $lookup_data{$class}->{$id} ) { 
        trace "LOOKUP ID [%s] [%s]", $id, $lookup_data{$class}->{$id} [EXEMPTION DESCRIPTIONS];
    }
    else {
        error "No description found corresponding to ID [%s]", $id [EXEMPTION DESCRIPTIONS];
    }
    return $lookup_data{$class}->{$id} // '';
}

# ------------------------------------------------------------------------------

1;
