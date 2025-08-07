package ChGovUk;

use Mojo::Base 'Mojolicious';
use MojoX::Log::Declare;
use CH::Perl;
use CH::Util::DateHelper;
use Locale::Simple;
use Time::HiRes qw(tv_interval gettimeofday);

# ------------------------------------------------------------------------------

# Called once at server start
sub startup {
    my $self = shift;
    #debug "Starting application" [APP];
    $self->log->debug("Starting application [APP]");

    # Set CH::Log as the default logger via this wrapper
    #$self->log(MojoX::Log::Declare->new());
    
    $self->plugin('CH::MojoX::Plugin::Config', { files => ['appconfig.yml','errors.yml'] } );

    # Fail fast if required private config variables are missing
    foreach my $var (qw(cookie_signing_key url_sign_salt)) {
        die "Missing " . $var . " in configuration" unless $self->config->{$var};
    }
    
    $self->secrets([$self->config->{cookie_signing_key}]);

    l_dir( File::Spec->join($self->app->home, 'i18n') );
    ltd('chgovuk');
    l_lang('en');

    $self->plugin('MojoX::JSON::XS');

    $self->plugin('CH::MojoX::Administration::Plugin');
    
    # Configure web path to role name mappings
    $self->plugin('CH::MojoX::UserPermissions::Plugin', map => [
        {path => qr#^/admin/roles(/.*)?$#,  urn => '/admin/roles'},
        {path => qr#^/admin/user(/.*)/transactions?$#,   urn => '/admin/user/filings'},
        {path => qr#^/admin/user(/.*)?$#,   urn => '/admin/user/search'},
        {path => qr#^/admin/search(/.*)?$#, urn => '/admin/search'},
        {path => qr#^/admin/transaction/.*?/.*?/resubmit$#, urn => '/admin/filing/resubmit'},
        {path => qr#^/admin/transaction/.*?/.*?/email$#,    urn => '/admin/filing/resend'},
        {path => qr#^/admin/transactions/.*$#,              urn => '/admin/transaction-lookup'},
    ]);

    $self->plugin('CH::MojoX::Plugin::QueueAPI');
    $self->plugin('MojoX::Plugin::Hook::BeforeRendered');
    $self->plugin('MojoX::Plugin::AnyCache' => $self->config->{cache});

    $self->plugin('CH::MojoX::Plugin::Exception');

    $self->register_session_manager();
    $self->plugin('CH::MojoX::SignIn::Plugin');
    $self->plugin('CH::MojoX::Plugin::HealthCheck');

    $self->plugin('CH::MojoX::Plugin::Xslate');
    $self->plugin('MojoX::URL::Sign::Plugin', salt => $self->config->{url_sign_salt});
    $self->plugin('MojoX::Renderer::IncludeLater');

    $self->plugin('ChGovUk::Plugins::Hooks');
    $self->plugin('ChGovUk::Plugins::Bridges');
    $self->plugin('ChGovUk::Plugins::TransactionMap');
    $self->plugin('ChGovUk::Plugins::TransactionRouting');
    $self->plugin('ChGovUk::Plugins::Routes');
    $self->plugin('ChGovUk::Plugins::Admin::Routes');

    $self->plugin('CH::MojoX::Plugin::API');

    $self->plugin('ChGovUk::Plugins::CVConstants');
    $self->plugin('ChGovUk::Plugins::DateHelpers');
    $self->plugin('ChGovUk::Plugins::AddressHelper');
    $self->plugin('ChGovUk::Plugins::Helpers');
    $self->plugin('ChGovUk::Plugins::Postcode');
    $self->plugin('ChGovUk::Plugins::FormHelpers');
    $self->plugin('ChGovUk::Plugins::CompanyPrefixes');
    $self->plugin('ChGovUk::Plugins::FilingHistoryDescriptions');
    $self->plugin('ChGovUk::Plugins::FilingHistoryExceptions');
    $self->plugin('ChGovUk::Plugins::DisqualifiedOfficerDescriptions');
    $self->plugin('ChGovUk::Plugins::CountryCodes');
    $self->plugin('ChGovUk::Plugins::JWE');
    $self->plugin('ChGovUk::Plugins::FormatNumber');
    $self->plugin('ChGovUk::Plugins::MortgageDescriptions');
    $self->plugin('ChGovUk::Plugins::FilterHelper');
    $self->plugin('ChGovUk::Plugins::PSCDescriptions');
    $self->plugin('ChGovUk::Plugins::ExemptionDescriptions');

    $self->mode($ENV{'MOJO_MODE'} // 'development');

    if($self->mode eq 'development') {
        $self->plugin('MojoX::Plugin::PODRenderer');
    }

    $self->plugin('MojoX::Plugin::Statsd', config => $self->config->{statsd}, namespace => sub {
        my ($ctrl) = @_;

        return $ctrl->app->moniker.".".$ctrl->current_route;
    });

    # FIXME: Remove this when Doc API goes live
    $self->helper(can_view_images => sub {
        my ($c) = @_;
        my $image_date_from_config = $c->config->{image_service_start_date};
        my $image_service_active;

        if (defined($image_date_from_config) && $image_date_from_config =~ m/^\d\d\d\d-\d\d-\d\d$/) {
            $image_date_from_config =~ s/-//g;

            if (CH::Util::DateHelper->days_between(CH::Util::DateHelper->from_internal($image_date_from_config)) >= 0) {
                $image_service_active = 1;
            }
        }

        return !!($image_service_active || ($c->is_signed_in && CH::MojoX::UserPermissions->new->can_do(urn => '/admin/images', permissions => $c->session->{signin_info}->{user_profile}->{permissions})));
    });

    return;
}

#-------------------------------------------------------------------------------

sub register_session_manager {
    my ($self) = @_;

    my $namespace = "ch_gov_uk"; # moniker does not work for after_load, app is not set up yet??

    $self->plugin('MojoX::Security::Session::Plugin',
        domain => $self->config->{cookie_domain},
        secure => $ENV{SECURE_COOKIE},
        hooks  => {
            before_load  => sub {
                my ($self, $c, $id) = @_;
                $c->stash->{'.statsd.session.started'} = [Time::HiRes::gettimeofday()];
            },
            before_store => sub {
                my ($self, $c, $id) = @_;
                $c->stash->{'.statsd.session.started'} = [Time::HiRes::gettimeofday()];
            },
            after_load   => sub {
                my ($self, $c, $id) = @_;
                $c->time_stats     ( "session.load.elapsed", Time::HiRes::tv_interval(
                                      $c->stash->{'.statsd.session.started'}, [Time::HiRes::gettimeofday()] ),
                                      namespace =>  $namespace );
                $c->increment_stats( "session.load", namespace => $namespace );
            },
            after_store  => sub {
                my ($self, $c, $id) = @_;
                $c->time_stats     ( "session.store.elapsed", Time::HiRes::tv_interval(
                                      $c->stash->{'.statsd.session.started'}, [Time::HiRes::gettimeofday()] ),
                                      namespace => $namespace );
                $c->increment_stats( "session.store", namespace => $namespace );
            },
        });
}

#-------------------------------------------------------------------------------
1;

=head1 NAME

ChGovUk

=head1 DESCRIPTION

Initialisation of application

=head1 METHODS

=head2 [void] startup ()

Called by Mojolicious on application startup

=cut
