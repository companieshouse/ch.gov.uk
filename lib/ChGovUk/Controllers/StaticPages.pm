package ChGovUk::Controllers::StaticPages;

use CH::Perl;
use Mojo::Base 'Mojolicious::Controller';
use CH::Util::CVConstants;
use Time::HiRes qw(tv_interval gettimeofday);
use Scalar::Util qw(refaddr);

#-------------------------------------------------------------------------------

sub home {
    my ($self) = @_;

    $self->render_later;

    $self->get_basket(0);
}

sub render_filepath {
    my ($self) = @_;

    $self->render_later;

    $self->get_basket(1);
}

sub get_basket {
    my ($self, $is_static_page) = @_;

    if ($self->is_signed_in) {
	my $start = [Time::HiRes::gettimeofday()];
	debug "TIMING basket (static pages) '" . refaddr(\$start) . "'";
        $self->ch_api->basket->get->on(
            success        => sub {
                my ($api, $tx) = @_;
                debug "TIMING basket (static pages) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                my $json = $tx->res->json;
                my $show_basket_link = $json->{data}{enrolled} || undef;
                my $items = scalar @{$json->{data}{items} || []};
                if ($show_basket_link) {
                    debug "User [%s] enrolled for multi-item basket; displaying basket link", $self->user_id, [HOMEPAGE];
                }
                else {
                    debug "User [%s] not enrolled for multi-item basket; not displaying basket link", $self->user_id, [HOMEPAGE];
                }
                $self->render_page($items, $show_basket_link, $is_static_page);
            },
            not_authorised => sub {
                my ($api, $tx) = @_;
                debug "TIMING basket (static pages) not_authorised '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                warn "User not authenticated; not displaying basket link", [HOMEPAGE];
                $self->render_page(0, undef, $is_static_page);
            },
            failure        => sub {
                my ($api, $tx) = @_;
                debug "TIMING basket (static pages) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                log_error($tx, "failure");
                $self->render_page(0, undef, $is_static_page);
            },
            error          => sub {
                my ($api, $tx) = @_;
                debug "TIMING basket (static pages) error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                log_error($tx, "error");
                $self->render_page(0, undef, $is_static_page);
            }
        )->execute;
    } else {
        debug "User not signed in; not displaying basket link", [HOMEPAGE];
        $self->render_page(0, undef, $is_static_page);
    }

}

sub render_page {
    my ($self, $basket_items, $show_basket_link, $is_static_page) = @_;

    if ($is_static_page) {
        $self->render_static_page($basket_items, $show_basket_link);
    } else {
        $self->render_homepage($basket_items, $show_basket_link);
    }
}

sub render_homepage {
    my ($self, $basket_items, $show_basket_link) = @_;

    debug "render_homepage(%s, %s)", $basket_items, $show_basket_link//'undef' [HOMEPAGE];

    my $search_type = 'all';

    $self->session(pst => $search_type);
    $self->stash(
        search_type      => $search_type,
        basket_items     => $basket_items,
        show_basket_link => $show_basket_link
    );
    $self->render;
}

sub render_static_page {
    my ($self, $basket_items, $show_basket_link) = @_;

    debug "render_static_page(%s, %s)", $basket_items, $show_basket_link//'undef' [HOMEPAGE];

    $self->stash(
        basket_items     => $basket_items,
        show_basket_link => $show_basket_link
    );

    my $path = 'static_pages/help/' . $self->param('filepath');
    $self->render(template => $path);
}

sub render_error {
    my($self, $tx, $error_type, $action) = @_;

    my $error_code = $tx->error->{code} // 0;
    my $error_message = $tx->error->{message} // 0;
    my $message = (uc $error_type).' '.(defined $error_code ? "[$error_code] " : '').$action.': '.$error_message;
    $self->render_exception($message);
}

sub log_error {
    my($tx, $error_type) = @_;

    my $error_code = $tx->error->{code} // 0;
    my $error_message = $tx->error->{message} // 0;
    my $error = (defined $error_code ? "[$error_code] " : '').$error_message;
    return if uc($error_type) eq 'FAILURE' && $error_code eq '404'; # don't log empty basket
    error "%s returned by getBasketLinks endpoint: '%s'. Not displaying basket link.", uc $error_type, $error, [HOMEPAGE];
}

#===============================================================================

1;
