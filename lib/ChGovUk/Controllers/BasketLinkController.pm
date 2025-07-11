package ChGovUk::Controllers::BasketLinkController;

use Log::Declare;
use Moose;
extends 'MojoX::Moose::Controller';
use Time::HiRes qw(tv_interval gettimeofday);
use Scalar::Util qw(refaddr);

# -----------------------------------------------------------------------------

sub get_basket_link {
    my ($self, $next) = @_;

    if ($self->is_signed_in) {
        my $start = [Time::HiRes::gettimeofday()];
        debug "TIMING basket (basket link controller) '" . refaddr(\$start) . "'";
        $self->ch_api->basket->get->on(
            success        => sub {
                my ($api, $tx) = @_;
                debug "TIMING basket (basket link controller) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                my $json = $tx->success->json;
                my $show_basket_link = $json->{data}{enrolled} || undef;
                my $items = scalar @{$json->{data}{items} || []};
                if ($show_basket_link) {
                    debug "User [%s] enrolled for multi-item basket; displaying basket link.", $self->user_id, [BASKET_LINK_CONTROLLER];
                }
                else {
                    debug "User [%s] not enrolled for multi-item basket; not displaying basket link.", $self->user_id, [BASKET_LINK_CONTROLLER];
                }
                $self->stash_basket_link($show_basket_link, $items);
                $next->();
            },
            not_authorised => sub {
                my ($api, $tx) = @_;
                debug "TIMING basket (basket link controller) not_authorised '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                warn "User not authenticated; not displaying basket link.", [BASKET_LINK_CONTROLLER];
                $self->hide_basket_link;
                $next->();
            },
            failure        => sub {
                my ($api, $tx) = @_;
                debug "TIMING basket (basket link controller) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                log_error($tx, "failure");
                $self->hide_basket_link;
                $next->();
            },
            error          => sub {
                my ($api, $tx) = @_;
                debug "TIMING basket (basket link controller) error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                log_error($tx, "error");
                $self->hide_basket_link;
                $next->();
            }
        )->execute;
    } else {
        $self->hide_basket_link;
        $next->();
    }
}

# ------------------------------------------------------------------------------

sub stash_basket_link {
    my ($self, $show_basket_link, $basket_items) = @_;

    $self->stash(
        show_basket_link => $show_basket_link,
        basket_items     => $basket_items
    );
}

# ------------------------------------------------------------------------------

sub log_error {
    my($tx, $error_type) = @_;

    my $error_code = $tx->error->{code} // 0;
    my $error_message = $tx->error->{message} // 0;
    my $error = (defined $error_code ? "[$error_code] " : '').$error_message;
    return if uc($error_type) eq 'FAILURE' && $error_code eq '404'; # don't log empty basket
    error "%s returned by getBasketLinks endpoint: '%s'. Not displaying basket link.", uc $error_type, $error, [BASKET_LINK_CONTROLLER];
}

# ------------------------------------------------------------------------------

sub hide_basket_link {
    my($self) = @_;

    $self->stash_basket_link(undef, 0);
}

# ------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;
