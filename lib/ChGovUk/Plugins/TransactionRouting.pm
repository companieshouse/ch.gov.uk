package ChGovUk::Plugins::TransactionRouting;

use CH::Perl;
use Mojo::Base 'Mojolicious::Plugin';

# =============================================================================

sub register {
    my ($self, $app) = @_;
  
    my $root         = $app->routes;
    my $company      = $root->find('company_auth');
    my $transactions = $root->find('transactions');

    # Setup the transaction create, form get and form post routes for each form 
    my $map = $app->get_transaction_map;
    for my $endpoint (keys %$map) {
        my $form = $map->{$endpoint};
        #trace "Setting up transaction routing for endpoint '%s'", $endpoint [APP];
        $app->log->trace("Setting up transaction routing for endpoint '$endpoint' [APP]");

        # Create transaction (creates submission, redirects to transaction URL)
        $company->any($endpoint)->methods('POST', 'GET')->to('company-transactions#create');

        # Setup GET/POST routes for expanded form view
        $transactions->get ($endpoint)->to($form->{controller} . '#get');
        $transactions->post($endpoint)->to($form->{controller} . '#post');

        if(exists $form->{sections}) {
            # Create a placeholder route for sections (handled in transaction bridge)
            $transactions->get ($endpoint.'/:section')->to($form->{controller} . '#section_get');
            $transactions->post($endpoint.'/:section')->to($form->{controller} . '#section_post');
        }
    }

    return;
}

# -----------------------------------------------------------------------------
1;
