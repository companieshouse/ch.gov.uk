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
        $self->app->log->debug("TIMING basket (basket link controller) '" . refaddr(\$start) . "'");
        $self->ch_api->basket->get->on(
            success        => sub {
                my ($api, $tx) = @_;
                $self->app->log->debug("TIMING basket (basket link controller) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
                my $json = $tx->success->json;
                my $show_basket_link = $json->{data}{enrolled} || undef;
                my $items = scalar @{$json->{data}{items} || []};
                if ($show_basket_link) {
                    $self->app->log->debug("User [" . $self->user_id . "] enrolled for multi-item basket; displaying basket link. [BASKET_LINK_CONTROLLER]");
                }
                else {
                    $self->app->log->debug("User [" . $self->user_id . "] not enrolled for multi-item basket; not displaying basket link. [BASKET_LINK_CONTROLLER]");
                }
                $self->stash_basket_link($show_basket_link, $items);
                $next->();
            },
            not_authorised => sub {
                my ($api, $tx) = @_;
                $self->app->log->debug("TIMING basket (basket link controller) not_authorised '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
                warn "User not authenticated; not displaying basket link.", [BASKET_LINK_CONTROLLER];
                $self->hide_basket_link;
                $next->();
            },
            failure        => sub {
                my ($api, $tx) = @_;
                $self->app->log->debug("TIMING basket (basket link controller) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
                log_error($self->app->log, $tx, "FAILURE");
                $self->hide_basket_link;
                $next->();
            },
            error          => sub {
                my ($api, $tx) = @_;
                $self->app->log->debug("TIMING basket (basket link controller) error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
                log_error($self->app->log, $tx, "ERROR");
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
    my ($log, $tx, $error_type) = @_;

    my $error_code = $tx->error->{code} // '';
    my $error_message = $tx->error->{message} // '';
    my $error = ($error_code ? "[$error_code] " : '') . $error_message;
    return if $error_type eq 'FAILURE' && $error_code eq '404'; # don't log empty basket
    $log->error("$error_type returned by getBasketLinks endpoint: '$error'. Not displaying basket link. [BASKET_LINK_CONTROLLER]");
}

# ------------------------------------------------------------------------------

sub hide_basket_link {
    my($self) = @_;

    $self->stash_basket_link(undef, 0);
}

# ------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;
