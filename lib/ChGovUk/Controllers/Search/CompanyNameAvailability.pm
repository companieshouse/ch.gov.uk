package ChGovUk::Controllers::Search::CompanyNameAvailability;

use CH::Perl;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util;

use constant DEFAULT_ITEMS_PER_PAGE => 50;

# see if a company name is available to register? perform a 'same as' check based on Alphakey?
#------------------------------------------------------------------------------
sub company_name_availability {

    my ($self) = @_;

    my $company_name = $self->req->param('q');

    return $self->render(template => 'company/company_name_availability/form')
        unless $company_name;
    
    $self->render_later;

    $self->ch_api->search->companies({
        'q'              => $company_name,
        'items_per_page' => DEFAULT_ITEMS_PER_PAGE,
        'start_index'    => 1,
        # search 'same as' names for active companies
        'restrictions'   => 'active-companies legally-equivalent-company-name'
    })->get->on(
        success => sub {
            my ($api, $tx) = @_;

            my $json  = $tx->res->json;

            $self->stash(
                query             => $company_name,
                company_name      => $company_name,
                companies         => $json,
                total_results     => $json->{total_results},
                current_page      => 1,
                show_pager        => 0,
            );

            return $self->render(template => "company/company_name_availability/form");

        },
        failure => sub {
            my ($api, $tx) = @_;

            my $error_code = $tx->error->{code}       // 0;
            my $error_message = $tx->error->{message} // 0;

            error 'Failed to retrieve search results: [%s] [%s]', $error_code, $error_message;

            return $self->render('error', error => 'invalid_request', description => 'You have requested a page outside of the available result set', status => 416)
                if $error_code == 416;
              
            # don't throw to the error page show a message inline 
            $self->stash(query => $company_name, show_error => 1);

            return $self->render(template => "company/company_name_availability/form");

        },
        error => sub {
            my ($api, $error) = @_;

            my $message = "Error retrieving search results: $error";
            error '%s', $message;

            return $self->render_exception($message);
        },
    )->execute;
}

# =============================================================================

1;

__END__

