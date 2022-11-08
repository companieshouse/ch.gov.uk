package ChGovUk::Controllers::StaticPages;

use CH::Perl;
use Mojo::Base 'Mojolicious::Controller';
use CH::Util::CVConstants;
use Data::Dumper;

#-------------------------------------------------------------------------------

sub home {
    my ($self) = @_;

    $self->render_later;

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
                $self->do_render($items, $show_basket_link);
            },
            not_authorised => sub {
                my ($api, $tx) = @_;
                debug "User not authenticated; not displaying basket link", [HOMEPAGE];
                $self->do_render(0, undef);
            },
            failure        => sub {
                my ($api, $tx) = @_;
                debug "Error returned by getBasketLinks endpoint; not displaying basket link", [HOMEPAGE];
                $self->do_render(0, undef);
            },
            error          => sub {
                my ($api, $tx) = @_;
                debug "Error returned by getBasketLinks endpoint; not displaying basket link", [HOMEPAGE];
                $self->do_render(0, undef);
            }
        )->execute;
    } else {
        debug "User not signed in; not displaying basket link", [HOMEPAGE];
        $self->do_render(0, undef);
    }
}

sub render_filepath {
    my ($self) = @_;

    debug "render_filepath: filepath = %s",  $self->param('filepath'), [HOMEPAGE];
    my $path = 'static_pages/help/' . $self->param('filepath');
    debug "render_filepath: \$path = %s",  $path, [HOMEPAGE];

    $self->render_later;

    if ($self->is_signed_in) {
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
                $self->do_render_2($items, $show_basket_link, $path);
            },
            # TODO BI-11899 What's wrong with this?
            # not_authorised => sub {
            #     my ($api, $tx) = @_;
            #     debug "User not authenticated; not displaying basket link", [HOMEPAGE];
            #     $self->do_render(0, undef);
            # },
            failure        => sub {
                my ($api, $tx) = @_;
                debug "Failure returned by getBasketLinks endpoint; not displaying basket link", [HOMEPAGE];
                $self->do_render_2(0, undef, $path);
            },
            error          => sub {
                my ($api, $tx) = @_;
                debug "Error returned by getBasketLinks endpoint; not displaying basket link", [HOMEPAGE];
                $self->do_render_2(0, undef, $path);
            }
        )->execute;
    } else {
        debug "User not signed in; not displaying basket link", [HOMEPAGE];
        $self->do_render_2(0, undef, $path);
    }

    my $path = 'static_pages/help/' . $self->param('filepath');
    $self->render(template => $path );
}

sub do_render {
    my ($self, $basket_items, $show_basket_link) = @_;

    debug "do_render(%s, %s)", $basket_items, $show_basket_link [HOMEPAGE];

    my $search_type = 'all';

    $self->session(pst => $search_type);
    $self->stash(
        search_type      => $search_type,
        basket_items     => $basket_items,
        show_basket_link => $show_basket_link
    );
    $self->render;
}

sub do_render_2 {
    my ($self, $basket_items, $show_basket_link, $path) = @_;

    debug "do_render_2(%s, %s, %s)", $basket_items, $show_basket_link, $path [HOMEPAGE];

    $self->stash(
        basket_items     => $basket_items,
        show_basket_link => $show_basket_link
    );

    debug "stash AFTER = %s", Dumper($self->stash), [HOMEPAGE];

    $self->render(template => $path);
}

#===============================================================================

1;
