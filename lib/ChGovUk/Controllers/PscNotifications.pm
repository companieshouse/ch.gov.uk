package ChGovUk::Controllers::PscNotifications;

use Mojo::Base 'Mojolicious::Controller';

use CH::Perl;
use CH::Util::Pager;
use Time::HiRes qw(tv_interval gettimeofday);
use Scalar::Util qw(refaddr);
use Mojo::IOLoop::Delay;
use Mojo::URL;

use constant AVAILABLE_CATEGORIES => {
    active => 'Current notifications',
};

sub get {
    my ($self) = @_;

    $self->render_later;

    my $psc_id         = $self->param('persons_with_significant_control_id');
    my $page           = abs int($self->param('page')|| 1);
    my $items_per_page = $self->config->{psc_notifications}->{items_per_page} || 10;
    my $absolute_page  = abs int($page == 1 ? 0 : ($page - 1) * $items_per_page);

    my $pager = CH::Util::Pager->new(
        current_page     => $page,
        entries_per_page => $items_per_page,
    );

    # List of categories to filter by (optional)
    my @filters = split ',', $self->get_filter('oa');

    # Generate an arrayref containing hashrefs of category ids/names that are sorted by name
    my @categories = sort _sort_filter map { _build_filter($_) } keys %{ AVAILABLE_CATEGORIES() };

    # Iterate through categories setting checked flag
    for my $category (@categories) {
        $category->{checked} = 1 if grep { $category->{id} eq $_ } @filters;
    }

    my $filter = join ',', map { $_->{id}} grep {$_->{checked} } @categories;

    trace 'Fetching notifications page [%s] for psc [%s]', $page, $psc_id;

    # Get the basket link for the user nav bar
    $self->get_basket_link;

    my $start = [Time::HiRes::gettimeofday()];
    debug "TIMING psc.notifications '" . refaddr(\$start) . "'";
    my $notifications_url = Mojo::URL->new;
    $notifications_url->path->parts(['persons-with-significant-control', $psc_id, 'notifications']);
    $notifications_url->path->leading_slash(1);
    $notifications_url->query({
        filter          => $filter,
        items_per_page  => $items_per_page,
        start_index     => $absolute_page,
    });
    $self->ch_api->uri($notifications_url->to_string)->get->on(
        success => sub {
            my ($api, $tx) = @_;
            debug "TIMING psc.notifications success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);

            my $results = $tx->success->json;
            trace 'Notifications for psc [%s]: %s', $psc_id, d:$results;

            my $psc = {
                notifications   => $results->{items},
                date_of_birth   => $results->{date_of_birth},
                name            => $results->{name},
                total_results   => $results->{total_results},
            };

            $pager->total_entries($results->{total_results});
            trace 'Total notifications [%d] with [%d] entries per page', $pager->total_entries, $pager->entries_per_page;

            my $is_out_of_range = $page > $pager->last_page;

            my $paging = {
                current_page_number => $pager->current_page,
                page_set            => $pager->pages_in_set,
                next_page           => $pager->next_page,
                previous_page       => $is_out_of_range
                    ? $pager->last_page
                    : $pager->previous_page,
                entries_per_page    => $pager->entries_per_page,
            };

            # If the filter string contains 'active' we are assuming
            # the active filter is set. If is_active_filter_set then we
            # supress the resigned_count on template.
            my $is_active_filter_set = $filter =~ m/active/ ? 1 : 0;

            # Group notifications so each company profile is fetched only once.psc_notifications
            my %notifications_by_company;

            for my $notification (@{$psc->{notifications} // []}) {
                my $company_number = $notification->{notified_to}->{company_number};

                unless (defined $company_number && length $company_number) {
                    error 'PSC notification is missing a company number';
                    return $self->render_exception(
                        'PSC notification is missing a company_number'
                    );
                }
                push @{ $notifications_by_company{$company_number} }, $notification;
            }

            my $delay = Mojo::IOLoop::Delay->new;
            my @profile_errors;

            $delay->on(
                finish => sub {
                    if (@profile_errors) {
                        return $self->render_exception(join '; ', @profile_errors);
                    }

                    $self->stash(
                        categories              => \@categories,
                        is_active_filter_set    => $is_active_filter_set,
                        psc                     => $psc,
                        paging                  => $paging,
                    );

                    return $self->render;
                },
            );

            # Keep the delay open while requests are registered.
            # Releasing this also handles an empty notifications list.
            my $registration_end = $delay->begin(0);

            for my $company_number (sort keys %notifications_by_company) {
                my $profile_end = $delay->begin(0);

                $self->ch_api->company($company_number)->profile->force_api_key->get->on(
                    success => sub {
                        my ($api, $tx) = @_;
                        my $company = $tx->success->json;

                        for my $notification (
                            @{ $notifications_by_company{$company_number} }
                        ) {
                            $notification->{notified_to}->{company_name} = $company->{company_name};

                            $notification->{notified_to}->{company_status} = $company->{company_status};
                        }

                        $profile_end->();
                    },
                    failure => sub {
                        my ($api, $tx) = @_;
                        my $message = sprintf(
                            'Failed to retrieve company profile [%s]: %s',
                            $company_number,
                            $tx->error->{message},
                        );

                        error '%s', $message;
                        push @profile_errors, $message;
                        $profile_end->();
                    },
                    error => sub {
                        my ($api, $error) = @_;
                        my $message = sprintf(
                            'Error retrieving company profile [%s]: %s',
                            $company_number,
                            $error,
                        );

                        error '%s', $message;
                        push @profile_errors, $message;
                        $profile_end->();
                    },
                )->execute;
            }

            $registration_end->();
            return;
        },
        failure => sub {
            my ($api, $tx) = @_;
            debug "TIMING psc.notifications failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);

            my ($error_code, $error_message) = @{ $tx->error }{qw(code message)};

            if ($error_code and $error_code == 404) {
                trace 'Notifications not found for psc [%s]', $psc_id;
                return $self->render_not_found;
            }

            error 'Failed to retrieve notifications for psc [%s]', $psc_id, $error_message;
            return $self->render_exception("Failed to retrieve psc notifications: $error_message");
        },
        error => sub {
            my ($api, $error) = @_;
            debug "TIMING psc.notifications error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);

            error 'Error retrieving notifications for psc [%s]: [%s]', $psc_id, $error;
            return $self->render_exception("Error retrieving psc notifications: $error");
        },
    )->execute;
}

# ------------------------------------------------------------------------------

sub get_basket_link {
    my ( $self ) = @_;

    if ($self->is_signed_in) {
        my $start = [Time::HiRes::gettimeofday()];
        debug "TIMING basket (psc notifications) '" . refaddr(\$start) . "'";
        $self->ch_api->basket->get->on(
            success         => sub {
                my ($api, $tx) = @_;
                debug "TIMING basket (psc notifications) success'" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                my $json = $tx->success->json;
                my $show_basket_link = $json->{data}{enrolled} || undef;
                my $items = scalar @{$json->{data}{items} || []};
                if ($show_basket_link) {
                    debug "User [%s] enrolled for multi-item basket; displaying basket link", $self->user_id, [PSC_NOTIFICATIONS];
                } else {
                    debug "User [%s] not enrolled for multi-item basket; not displaying basket link", $self->user_id, [PSC_NOTIFICATIONS];
                }
                $self->stash_basket_link($show_basket_link, $items);
            },
            not_authorised  => sub {
                my ($api, $tx) = @_;
                debug "TIMING basket (psc notifications) not_authorised'" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                warn "User not authenticated; not displaying basket_link", [PSC_NOTIFICATIONS];
                $self->stash_basket_link(undef, 0);
            },
            failure         => sub {
                my ($api, $tx) = @_;
                debug "TIMING basket (psc notifications) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                log_error($tx, "failure");
                $self->stash_basket_link(undef, 0);
            },
            error           => sub {
                my ($api, $tx) = @_;
                debug "TIMING basket (psc notifications) error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                log_error($tx, "error");
                $self->stash_basket_link(undef, 0);
            }
        )->execute;
    } else {
        $self->stash_basket_link(undef, 0);
    }
}

# ------------------------------------------------------------------------------

sub stash_basket_link {
    my ( $self, $show_basket_link, $basket_items ) = @_;

    $self->stash(
        show_basket_link => $show_basket_link,
        basket_items     => $basket_items
    );
}

# ------------------------------------------------------------------------------

sub log_error {
    my ($tx, $error_type) = @_;

    my $error_code = $tx->error->{code} // 0;
    my $error_message = $tx->error->{message} // 0;
    my $error = (defined $error_code ? "[$error_code]" : '').$error_message;
    return if uc($error_type) eq 'FAILURE' && $error_code eq '404'; # don't log empty basket
    error "%s returned by getBasketLinks endpoint: '%s'. Not displaying basket link.", uc $error_type, $error, [PSC_NOTIFICATIONS];
}

# -----------------------------------------------------------------------------

sub _sort_filter {
    $a->{name} cmp $b->{name};
}

# ------------------------------------------------------------------------------

sub _build_filter {
    my ($filter) = @_;

    return {
        id   => $filter,
        name => AVAILABLE_CATEGORIES()->{$filter},
    };
}
1;