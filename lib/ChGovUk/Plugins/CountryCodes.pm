package ChGovUk::Plugins::CountryCodes;

use Mojo::Base 'Mojolicious::Plugin';

use CH::Perl;
use CH::Util::CountryCodes;

# ------------------------------------------------------------------------------ 

# Called by Mojolicious when the plugin is registered
sub register {
    my ($self, $app) = @_;

    #trace "Registering %s::country_codes helper", __PACKAGE__ [APP];
    $app->log->trace("Registering " . __PACKAGE__ . "::country_codes helper [APP]");

    $app->helper(code_for_country => sub {
        my ($c, $country, $language, $filter,) = @_;
        return CH::Util::CountryCodes
            ->new( language => $language, filter => $filter )
            ->code_for_country( $country );
    });

    $app->helper(country_for_code => sub {
        my ($c, $code, $language, $filter,) = @_;
        return CH::Util::CountryCodes
            ->new( language => $language, filter => $filter )
            ->country_for_code( $code );
    });

    $app->helper(country_list => sub {
        my ($c, $language, $filter, $list_type) = @_;
        return CH::Util::CountryCodes
            ->new( language => $language, filter => $filter, list_type => $list_type )
            ->list;
    });

    return;
}

# ------------------------------------------------------------------------------ 

1;

=head1 NAME

ChGovUk::Plugins::CountryCodes

=head1 SYNOPSIS

    $app->plugin( 'ChGovUk::Plugins::CountryCodes' );

=cut

