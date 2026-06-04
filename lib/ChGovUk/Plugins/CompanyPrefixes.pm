package ChGovUk::Plugins::CompanyPrefixes;

use Mojo::Base 'Mojolicious::Plugin';
use CH::Perl;

use CH::Util::CompanyPrefixes;

# ------------------------------------------------------------------------------ 

# Called by Mojolicious when the plugin is registered
sub register {
    my ($self, $app) = @_;

    trace "Registering %s::company_is_llp helper", __PACKAGE__ [APP];
    $app->helper(company_is_llp => sub {
        my ($c, $company_number) = @_;
        return CH::Util::CompanyPrefixes::coIsLLP($company_number);
    });
    trace "Registering %s::company_has_no_sic helper", __PACKAGE__ [APP];
    $app->helper(company_has_no_sic => sub {
        my ($c, $company_number, $subtype) = @_;
        return CH::Util::CompanyPrefixes::coHasNoSic($company_number, $subtype);
    });
    trace "Registering %s::company_is_digital_lp helper", __PACKAGE__ [APP];
    $app->helper(company_is_digital_lp => sub {
        my ($c, $subtype) = @_;
        return CH::Util::CompanyPrefixes::coIsDigitalLP($subtype);
    });
    trace "Registering %s::company_is_lp_update_allowed helper", __PACKAGE__ [APP];
    $app->helper(company_is_lp_update_allowed => sub {
        my ($c, $company) = @_;

        my $acsp_number = $c->session->{signin_info} && $c->session->{signin_info}->{acsp_number};

        return coIsLPUpdateAllowed(
            is_signed_in    => $c->is_signed_in,
            company_type    => $company->{type},
            company_subtype => $company->{subtype},
            acsp_number     => $acsp_number,
        );
    });
    return;
}

# ------------------------------------------------------------------------------ 

1;

=head1 NAME

ChGovUk::Plugins::CompanyPrefixes

=head1 SYNOPSIS

    sub startup {
        ...
        $self->plugin( 'ChGovUk::Plugins::CompanyPrefixes' );
        ...
    }

=head1 METHODS

=head2 register

Called by mojolicious when plugin is registered. Registers the
L<cv|/"cv"> and L<cv_lookup|/"cv_lookup"> helpers.

    @param   app    [mojo app]  mojolicious application
    @param   config [hashref]   configuration hash


=head1 EXPORTED HELPERS

=head2 company_is_llp

Determine whether a given company number refers to an LLP company or not.

    @param   company_number [string]    company number to test
    @retruns 1=company is llp, 0=company is not llp
    

=cut

