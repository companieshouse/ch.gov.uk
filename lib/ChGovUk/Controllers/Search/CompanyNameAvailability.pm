package ChGovUk::Controllers::Search::CompanyNameAvailability;

use CH::Perl;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util;
use Data::Dumper;

use constant DEFAULT_ITEMS_PER_PAGE => 50;

# see if a company name is available to register? perform a 'same as' check based on Alphakey?
#------------------------------------------------------------------------------
sub company_name_availability {

    my ($self) = @_;

    my $company_name = $self->req->param('q');

    $self->stash(
        'title'           => ($company_name)
                          ?  $company_name . ' - Company name availability checker - Find and update company information - GOV.UK'
                          : 'Company name availability checker - Find and update company information - GOV.UK'
    );

    debug "Calling get_basket()...", [HOMEPAGE];

    $self->get_basket();

    debug "AFTER get_basket() stash = %s", Dumper($self->stash), [HOMEPAGE];
    debug "\$company_name = %s", Dumper($company_name), [HOMEPAGE];

    return $self->render(template => 'company/company_name_availability/form')
        unless $company_name;

    debug "CONTINUING ON TO render_later", [HOMEPAGE];
    
    $self->render_later;

    debug "About to execute search", [HOMEPAGE];
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
                'title'           => ($company_name)
                                  ?  $company_name . ' - Company name availability checker - Find and update company information - GOV.UK'
                                  : 'Company name availability checker - Find and update company information - GOV.UK'
            );

            debug "search success , stash = %s", Dumper($self->stash), [HOMEPAGE];
            return $self->render(template => "company/company_name_availability/form");

        },
        failure => sub {
            my ($api, $tx) = @_;

            my $error_code = $tx->error->{code}       // 0;
            my $error_message = $tx->error->{message} // 0;

            error 'Failed to retrieve search results: [%s] [%s]', $error_code, $error_message;

            return $self->render('error', error => 'outside_result_set', description => 'You have requested a page outside of the available result set', status => 416)
                if $error_code == 416;
              
            # don't throw to the error page show a message inline 
            $self->stash(query => $company_name, show_error => 1);

            debug "search failure , stash = %s", Dumper($self->stash), [HOMEPAGE];
            return $self->render(template => "company/company_name_availability/form");

        },
        error => sub {
            my ($api, $error) = @_;

            my $message = "Error retrieving search results: $error";
            error '%s', $message;

            debug "search error , stash = %s", Dumper($self->stash), [HOMEPAGE];
            return $self->render_exception($message);
        },
    )->execute;
}

sub get_basket() {
    my ($self) = @_;
    if ($self->is_signed_in) {
        debug "Signed in, calling basket API", [HOMEPAGE];
        $self->ch_api->basket->get->on(
            success        => sub {
                my ($api, $tx) = @_;
                debug "success", [HOMEPAGE];
                my $json = $tx->res->json;
                my $show_basket_link = $json->{data}{enrolled} || undef;
                my $items = scalar @{$json->{data}{items} || []};
                if ($show_basket_link) {
                    debug "User [%s] enrolled for multi-item basket; displaying basket link", $self->user_id, [HOMEPAGE];
                }
                else {
                    debug "User [%s] not enrolled for multi-item basket; not displaying basket link", $self->user_id, [HOMEPAGE];
                }
                $self->do_render($items, $show_basket_link);
            },
            not_authorised => sub {
                my ($api, $tx) = @_;
                debug "not_authorised", [HOMEPAGE];
                debug "User not authenticated; not displaying basket link", [HOMEPAGE];
                $self->do_render(0, undef);
            },
            failure        => sub {
                my ($api, $tx) = @_;
                debug "failure", [HOMEPAGE];
                debug "Error returned by getBasketLinks endpoint; not displaying basket link", [HOMEPAGE];
                $self->do_render(0, undef);
            },
            error          => sub {
                my ($api, $tx) = @_;
                debug "error", [HOMEPAGE];
                debug "Error returned by getBasketLinks endpoint; not displaying basket link", [HOMEPAGE];
                $self->do_render(0, undef);
            }
        )->execute;
    } else {
        debug "User not signed in; not displaying basket link", [HOMEPAGE];
        $self->do_render(0, undef);
    }
}

sub do_render {
    my ($self, $basket_items, $show_basket_link) = @_;

    debug "Stashing basket_items = %s, show_basket_link = %s", $basket_items, $show_basket_link [HOMEPAGE];
    $self->stash(
        basket_items     => $basket_items,
        show_basket_link => $show_basket_link
    );
    debug "AFTER stashing, stash = %s", Dumper($self->stash), [HOMEPAGE];
    # $self->render;
}

# =============================================================================

1;

__END__

