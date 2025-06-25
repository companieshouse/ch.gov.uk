package ChGovUk::Plugins::Routes;

use Mojo::Base 'Mojolicious::Plugin';
use CH::Perl;

use CH::Util::DateHelper qw(is_current_date_greater);

use CH::MojoX::SignIn::Bridge::OAuth2;
use CH::MojoX::UserPermissions::Bridge;

# =============================================================================

sub register {
    my ($self, $app, $args) = @_;

    # Add controllers namespace to routing
    push @{$app->routes->namespaces}, 'CH::MojoX::SignIn::Controller';
    push @{$app->routes->namespaces}, 'ChGovUk::Controllers';

    # 'root' is the root route... matches '/'
    my $root = $app->routes->find('root');

    # Get the bridges
    my $user         = $root->under->name('user_auth')->to( cb => \&CH::MojoX::SignIn::Bridge::OAuth2::bridge );
    my $company      = $root->find('company_auth');
    my $transactions = $root->find('transactions');

    # Main search and search results
    $root->get('/')->to('static_pages#home')->name('root');

    # AZ Listing
    $root->any->get('/register-of-disqualifications/:letter' => [ letter => qr/[A-Z]{1}/ ])->name('register_of_disqualifications')->to('register_of_disqualifications#list');

    # Search
    $root->any('/search')->get->name('search')->to('search#results');
    $root->any('/search/:search_type')->get->name('search_facet')->to('search#results');

    # Post user feedback
    $root->any('/customer-feedback')->to('CustomerFeedback#record_feedback');

    # Company name availability search
    $root->any('/company-name-availability')->to('Search::CompanyNameAvailability#company_name_availability');

    # Static help pages
    $root->get('/help/:filepath')->to('StaticPages#render_filepath');

    # Static accounts pages
    $root->get('/accounts/:filepath')->to('StaticPages#render_filepath');

    # Company authentication routes
    $root->get('/company/:company_number/authorise')->name('company_authorise')->to('o_auth2#company_signin');

    $user->get('user/transactions')->name('user_filings')->to('user-filings#list');
    $user->get('user/transactions/:transaction_number/registered-office-address')->name('show_registered_office_resource')->to('user-transactions-submitted_data#show_registered_office_address');
    $user->get('user/transactions/:transaction_number/resume')->name('resume_transaction')->to('user-transactions-resume#resume');

    # Company Profile route
    my $company_bridge = $root->find('company');
    $company_bridge->get('/')->name('company_profile')->to('company#view');
    $company_bridge->get('/filing-history')->name('company_filing_history')->to('company-filing_history#view');
    $company_bridge->get('/certified-documents')->name('company_certified_documents')->to('company-certified_documents#view');
    $company_bridge->post('/certified-documents')->name('company_certified_documents')->to('company-certified_documents#post');
    $company_bridge->get('/officers')->name('company_officers')->to('company-officers#list');
    $company_bridge->get('/registers')->name('company_registers')->to('company-registers#list');
    $company_bridge->get('/registers/directors')->name('company_registers_directors')->to('company-registers-directors#list');
    $company_bridge->get('/registers/secretaries')->name('company_registers_secretaries')->to('company-registers-secretaries#list');
    $company_bridge->get('/registers/persons-with-significant-control')->name('company_registers_pscs')->to('company-registers-pscs#list');
    $company_bridge->get('/registers/llp-members')->name('company_registers_members')->to('company-registers-members#list');
    $company_bridge->get('/insolvency')->name('company_insolvency')->to('company-insolvency#view');
    $company_bridge->get('/charges')->name('company_charges')->to('company-mortgages#view');
    $company_bridge->get('/charges/:charge_id')->name('company_charge_with_id')->to('company-mortgages#view_details');
    $company_bridge->get('/ukestablishments')->name('company_branches')->to('company-branches#view');
    $company_bridge->get('/more')->name("company_view_all")->to('company-view_all#view');

    # PSCs route
    $company_bridge->get('/persons-with-significant-control')->name('list_pscs')->to('company-pscs#list');

    # Officer route
    $root->get('/officers/:officer_id/appointments')->name('get_officer_appointments')->to('personal_appointments#get');

    # Disqualified Officers route
    $root->get('/disqualified-officers/corporate/:officer_id')->name('get_corporate_disqualification')->to('disqualified_officers#get_corporate');
    $root->get('/disqualified-officers/natural/:officer_id')->name('get_natural_disqualification')->to('disqualified_officers#get_natural');

    # Image view
    $company_bridge->get('/filing-history/:filing_history_id/document')->name('filing_history_document')->to('company-document#document');

    # Transactions
    $transactions->get('confirmation')->to('company-transactions#confirmation');

    # Charges
    #$company->get('/charges')->name('charges')->to('charges#list');

    # Admin
    my $admin = $root->under('/admin')->to(cb => \&CH::MojoX::UserPermissions::Bridge::bridge);

    # Route to development only page displaying examples of form elements.

    if($app->mode eq 'development') {
        $root->get('/dev')->to('static_pages#dev');
    }

    return;
}

# -----------------------------------------------------------------------------

1;

=head1 NAME

ChGovUk::Plugins::Routes

=cut
