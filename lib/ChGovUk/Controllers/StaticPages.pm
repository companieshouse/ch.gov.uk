package ChGovUk::Controllers::StaticPages;

use CH::Perl;
use Mojo::Base 'Mojolicious::Controller';
use CH::Util::CVConstants;
use ChGovUk::Controllers::Company::BasketClient;

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
                if ($show_basket_link) {
                    debug "User [%s] enrolled for multi-item basket; displaying basket link", $self->user_id, [HOMEPAGE];
                }
                else {
                    debug "User [%s] not enrolled for multi-item basket; not displaying basket link", $self->user_id, [HOMEPAGE];
                }
                $self->do_render(scalar @{$json->{data}{items} || []}, $json->{data}{enrolled} || undef);
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
    my $path = 'static_pages/help/' . $self->param('filepath');
    $self->render(template => $path );
}

sub do_render {
    my ($self, $basket_items, $show_basket_link) = @_;

    my $search_type = 'all';

    $self->session(pst => $search_type);
    $self->stash(
        search_type      => $search_type,
        basket_items     => $basket_items,
        show_basket_link => $show_basket_link
    );
    $self->render;
}

#===============================================================================

1;
