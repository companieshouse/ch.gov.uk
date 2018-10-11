package ChGovUk::Plugins::Admin::Routes;

use Mojo::Base 'Mojolicious::Plugin';

use CH::Perl;
use CH::MojoX::Administration::Bridge::ValidateAdmin;

# =============================================================================

sub register {
    my ($self, $app, $args) = @_;

    push @{ $app->routes->namespaces }, 'ChGovUk::Controllers::Admin';

    my $admin_route = $app->routes->find('user_auth')->bridge('/admin')->name('has_admin_permission')->to(cb => sub {
        my ($controller) = @_;

        return 1 if CH::MojoX::Administration::Bridge::ValidateAdmin::web($controller);

        $controller->render_not_found;
        return undef;
    });
    $admin_route = $admin_route->bridge->name('has_route_permission')->to(cb => \&CH::MojoX::UserPermissions::Bridge::bridge);

    my $transaction = $admin_route->route('/transactions/:transaction_number');

    $admin_route->get('/user/:user_id/transactions')->to('user-filings#list');
    $admin_route->get('/transactions/:transaction_number')->to('admin-transaction#filing');
    $admin_route->get('/company/:company_number/transactions')->name('admin_transaction_by_company_number')->to('admin-transaction#search_by_company_number');
    $admin_route->get('/view_json')->name('admin_transaction_resource_details')->to('admin-transaction#submission_json');
    $transaction->get('/details')->name('admin_transaction_details')->to('admin-transaction#transaction_json');
    $transaction->post('/reprocess')->name('admin_transaction_reprocess')->to('admin-transaction#transaction_reprocess');

    my $filing = $transaction->route('/:barcode');
    $filing->get ('/email')->name('admin_email_view')->to('admin-transaction#email_confirm');
    $filing->post('/email')->name('admin_email_post')->to('admin-transaction#email');
    $filing->get ('/resubmit')->name('admin_filing_confirm')->to('admin-transaction#resubmit_confirm');
    $filing->post('/resubmit')->name('admin_filing_resubmit')->to('admin-transaction#resubmit');

    return;
}

#-------------------------------------------------------------------------------

1;

=head1 NAME

ChGovUk::Plugins::Admin::Routes

=cut
