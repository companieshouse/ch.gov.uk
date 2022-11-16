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

    $self->render_later;

    my $company_name = $self->req->param('q');

    $self->stash(
        'title'           => ($company_name)
                          ?  $company_name . ' - Company name availability checker - Find and update company information - GOV.UK'
                          : 'Company name availability checker - Find and update company information - GOV.UK'
    );

    $self->get_basket($company_name);
}

sub perform_search() {
    my ($self, $company_name) = @_;

    debug "About to execute search", [COMPANY_NAME_AVAILABILITY];
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

            debug "search success , stash = %s", Dumper($self->stash), [COMPANY_NAME_AVAILABILITY];
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

            debug "search failure, stash = %s", Dumper($self->stash), [COMPANY_NAME_AVAILABILITY];
            return $self->render(template => "company/company_name_availability/form");

        },
        error => sub {
            my ($api, $error) = @_;

            my $message = "Error retrieving search results: $error";
            error '%s', $message;

            debug "search error, stash = %s", Dumper($self->stash), [COMPANY_NAME_AVAILABILITY];
            return $self->render_exception($message);
        },
    )->execute;

}

sub get_basket() {
    my ($self, $company_name) = @_;
    if ($self->is_signed_in) {
        debug "Signed in, calling basket API", [COMPANY_NAME_AVAILABILITY];
        $self->ch_api->basket->get->on(
            success        => sub {
                my ($api, $tx) = @_;
                debug "success", [COMPANY_NAME_AVAILABILITY];
                my $json = $tx->res->json;
                my $show_basket_link = $json->{data}{enrolled} || undef;
                my $items = scalar @{$json->{data}{items} || []};
                if ($show_basket_link) {
                    debug "User [%s] enrolled for multi-item basket; displaying basket link", $self->user_id, [COMPANY_NAME_AVAILABILITY];
                }
                else {
                    debug "User [%s] not enrolled for multi-item basket; not displaying basket link", $self->user_id, [COMPANY_NAME_AVAILABILITY];
                }
                $self->stash_basket_link($items, $show_basket_link);
                $self->search_or_render($company_name, "success");
            },
            not_authorised => sub {
                my ($api, $tx) = @_;
                debug "GET basket not_authorised", [COMPANY_NAME_AVAILABILITY];
                warn "User not authenticated; not displaying basket link", [COMPANY_NAME_AVAILABILITY];
                $self->stash_basket_link(0, undef);
                $self->search_or_render($company_name, "not_authorised");
            },
            failure        => sub {
                my ($api, $tx) = @_;
                log_error($tx, "failure");
                $self->stash_basket_link(0, undef);
                $self->search_or_render($company_name, "failure");
            },
            error          => sub {
                my ($api, $tx) = @_;
                log_error($tx, "error");
                $self->stash_basket_link(0, undef);
                $self->search_or_render($company_name, "error");
            }
        )->execute;
    } else {
        debug "User not signed in; not displaying basket link", [COMPANY_NAME_AVAILABILITY];
        $self->stash_basket_link(0, undef);
        $self->search_or_render($company_name, "Not signed in");
    }
}

sub stash_basket_link {
    my ($self, $basket_items, $show_basket_link) = @_;

    $self->stash(
        basket_items     => $basket_items,
        show_basket_link => $show_basket_link
    );
}

sub log_error {
    my($tx, $error_type) = @_;

    my $error_code = $tx->error->{code} // 0;
    my $error_message = $tx->error->{message} // 0;
    my $error = (defined $error_code ? "[$error_code] " : '').$error_message;
    error "%s returned by getBasketLinks endpoint: '%s'. Not displaying basket link.", uc $error_type, $error, [COMPANY_NAME_AVAILABILITY];
}

sub search_or_render {
    my($self, $company_name, $log_type) = @_;

    if ($company_name) {
        debug "%s: Calling perform_search()", $log_type, [COMPANY_NAME_AVAILABILITY];
        $self->perform_search($company_name);
    } else {
        debug "%s: Rendering page", $log_type, [COMPANY_NAME_AVAILABILITY];
        return $self->render(template => "company/company_name_availability/form");
    }
}

# =============================================================================

1;

__END__

