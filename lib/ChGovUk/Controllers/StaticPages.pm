package ChGovUk::Controllers::StaticPages;

use CH::Perl;
use Mojo::Base 'Mojolicious::Controller';
use CH::Util::CVConstants;

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
        $self->ch_api->basket->get->on(
            success        => sub {
                my ($api, $tx) = @_;
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
                debug "User not authenticated; not displaying basket link", [HOMEPAGE];
                $self->render_page(0, undef, $is_static_page);
            },
            failure        => sub {
                my ($api, $tx) = @_;
                debug "Error returned by getBasketLinks endpoint; not displaying basket link", [HOMEPAGE];
                return $self->render_error($tx, 'failure', 'getting basket');
            },
            error          => sub {
                my ($api, $tx) = @_;
                debug "Error returned by getBasketLinks endpoint; not displaying basket link", [HOMEPAGE];
                return $self->render_error($tx, 'failure', 'getting basket');
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

    debug "render_homepage(%s, %s)", $basket_items, $show_basket_link [HOMEPAGE];

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

    debug "render_static_page(%s, %s)", $basket_items, $show_basket_link [HOMEPAGE];

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
    return $self->render_exception($message);
}

#===============================================================================

1;
