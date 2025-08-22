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
	$self->app->log->debug("TIMING basket (static pages) '" . refaddr(\$start) . "'");
        $self->ch_api->basket->get->on(
            success        => sub {
                my ($api, $tx) = @_;
                $self->app->log->debug("TIMING basket (static pages) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
                my $json = $tx->res->json;
                my $show_basket_link = $json->{data}{enrolled} || undef;
                my $items = scalar @{$json->{data}{items} || []};
                if ($show_basket_link) {
                    #debug "User [%s] enrolled for multi-item basket; displaying basket link", $self->user_id, [HOMEPAGE];
                    $self->app->log->debug("User [" . $self->user_id . "] enrolled for multi-item basket; displaying basket link [HOMEPAGE]");
                }
                else {
                    #debug "User [%s] not enrolled for multi-item basket; not displaying basket link", $self->user_id, [HOMEPAGE];
                    $self->app->log->debug("User [" . $self->user_id . "] not enrolled for multi-item basket; not displaying basket link [HOMEPAGE]");
                }
                $self->render_page($items, $show_basket_link, $is_static_page);
            },
            not_authorised => sub {
                my ($api, $tx) = @_;
                $self->app->log->debug("TIMING basket (static pages) not_authorised '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
                #warn "User not authenticated; not displaying basket link", [HOMEPAGE];
                $self->app->log->warn("User not authenticated; not displaying basket link [HOMEPAGE]");
                $self->render_page(0, undef, $is_static_page);
            },
            failure        => sub {
                my ($api, $tx) = @_;
                $self->app->log->debug("TIMING basket (static pages) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
                log_error($self->app->log, $tx, "FAILURE");
                $self->render_page(0, undef, $is_static_page);
            },
            error          => sub {
                my ($api, $tx) = @_;
                $self->app->log->debug("TIMING basket (static pages) error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
                log_error($self->app->log, $tx, "ERROR");
                $self->render_page(0, undef, $is_static_page);
            }
        )->execute;
    } else {
        #debug "User not signed in; not displaying basket link", [HOMEPAGE];
        $self->app->log->debug("User not signed in; not displaying basket link [HOMEPAGE]");
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

    #debug "render_homepage(%s, %s)", $basket_items, $show_basket_link//'undef' [HOMEPAGE];
    $self->app->log->debug("render_homepage($basket_items, " . ($show_basket_link//'undef') . ") [HOMEPAGE]");

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

    #debug "render_static_page(%s, %s)", $basket_items, $show_basket_link//'undef' [HOMEPAGE];
    $self->app->log->debug("render_static_page($basket_items, " . ($show_basket_link//'undef') . ") [HOMEPAGE]");

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
    $self->reply->exception($message);
}

sub log_error {
    my ($log, $tx, $error_type) = @_;

    my $error_code = $tx->error->{code} // '';
    my $error_message = $tx->error->{message} // '';
    my $error = ($error_code ? "[$error_code] " : '') . $error_message;
    return if $error_type eq 'FAILURE' && $error_code eq '404'; # don't log empty basket
    $log->error("$error_type returned by getBasketLinks endpoint: '$error'. Not displaying basket link. [HOMEPAGE]");
}

#===============================================================================

1;
