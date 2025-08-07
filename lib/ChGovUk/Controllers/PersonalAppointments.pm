package ChGovUk::Controllers::PersonalAppointments;

use Mojo::Base 'Mojolicious::Controller';

use CH::Perl;
use CH::Util::Pager;
use Time::HiRes qw(tv_interval gettimeofday);
use Scalar::Util qw(refaddr);
use Data::Dumper;

use constant AVAILABLE_CATEGORIES => {
    active => 'Current appointments',
};

# ------------------------------------------------------------------------------

sub get {
    my ($self) = @_;

    $self->render_later;

    my $officer_id     = $self->param('officer_id');
    my $page           = abs int($self->param('page') || 1);
    my $items_per_page = $self->config->{officer_appointments}->{items_per_page} || 10;
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

    my $filter = join ',', map { $_->{id} } grep { $_->{checked} } @categories;

    #trace 'Fetching appointments page [%s] for officer [%s]', $page, $officer_id;
    $self->app->log->trace("Fetching appointments page [$page] for officer [$officer_id]");

    # Get the basket link for the user nav bar
    $self->get_basket_link;

    my $start = [Time::HiRes::gettimeofday()];
    $self->app->log->debug("TIMING officers.appointments '" . refaddr(\$start) . "'");
    $self->ch_api->officers($officer_id)->appointments({
        filter         => $filter,
        items_per_page => $items_per_page,
        start_index    => $absolute_page,
    })->get->on(
        success => sub {
            my ($api, $tx) = @_;
            $self->app->log->debug("TIMING officers.appointments success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

            my $results = $tx->res->json;
            #trace 'Appointments for officer [%s]: %s', $officer_id, d:$results;
            $self->app->log->trace("Appointments for officer [$officer_id]: " . Dumper($results));

            foreach my $item(@{$results->{items} // []}) {
                next if !$item->{identity_verification_details};
                my @list = @{ $item->{identity_verification_details}{anti_money_laundering_supervisory_bodies} // []} or next;
                $item->{identity_verification_details}{supervisory_bodies_string} = join ', ', @list;
            }

            my $officer = {
                appointments    => $results->{items},
                date_of_birth   => $results->{date_of_birth},
                name            => $results->{name},
                total_results   => $results->{total_results},
            };

            $pager->total_entries($results->{total_results});
            #trace 'Total appointments [%d] with [%d] entries per page', $pager->total_entries, $pager->entries_per_page;
            $self->app->log->trace("Total appointments [" . $pager->total_entries . "] with [" . $pager->entries_per_page . "]");

            my $paging = {
                current_page_number => $pager->current_page,
                page_set            => $pager->pages_in_set,
                next_page           => $pager->next_page,
                previous_page       => $pager->previous_page,
                entries_per_page    => $pager->entries_per_page,
            };

            # If the filter string contains 'active' we are assuming
            # the active filter is set. If is_active_filter_set then we
            # supress the resigned_count on template.
            my $is_active_filter_set = $filter =~ m/active/ ? 1 : 0;

            $self->stash(
                categories           => \@categories,
                is_active_filter_set => $is_active_filter_set,
                officer              => $officer,
                paging               => $paging,
            );

            return $self->render;
        },
        failure => sub {
            my ($api, $tx) = @_;
            $self->app->log->debug("TIMING officers.appointments failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

            my ($error_code, $error_message) = @{ $tx->error }{qw(code message)};

            if ($error_code and $error_code == 404) {
                #trace 'Appointments not found for officer [%s]', $officer_id;
                $self->app->log->trace("Appointments not found for officer [$officer_id]");
                return $self->render_not_found;
            }

            #error 'Failed to retrieve appointments for officer [%s]: [%s]', $officer_id, $error_message;
            $self->app->log->error("Failed to retrieve appointments for officer [$officer_id]: [$error_message]");
            return $self->render_exception("Failed to retrieve officer appointments: $error_message");
        },
        error => sub {
            my ($api, $error) = @_;
            $self->app->log->debug("TIMING officers.appointments error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

            #error 'Error retrieving appointments for officer [%s]: [%s]', $officer_id, $error;
            $self->app->log->error("Error retrieving appointments for officer [$officer_id]: [$error]");
            return $self->render_exception("Error retrieving officer appointments: $error");
        },
    )->execute;
}

# ------------------------------------------------------------------------------

sub get_basket_link {
    my ( $self ) = @_;
        if ($self->is_signed_in) {
        my $start = [Time::HiRes::gettimeofday()];
        $self->app->log->debug("TIMING basket (personal appointments) '" . refaddr(\$start) . "'");
        $self->ch_api->basket->get->on(
            success        => sub {
                my ($api, $tx) = @_;
                $self->app->log->debug("TIMING basket (personal appointments) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
                my $json = $tx->res->json;
                my $show_basket_link = $json->{data}{enrolled} || undef;
                my $items = scalar @{$json->{data}{items} || []};
                if ($show_basket_link) {
                    #debug "User [%s] enrolled for multi-item basket; displaying basket link", $self->user_id, [PERSONAL_APPOINTMENTS];
                    $self->app->log->debug("User [" . $self->user_id . "] enrolled for multi-item basket; displaying basket link [PERSONAL_APPOINTMENTS]");
                }
                else {
                    #debug "User [%s] not enrolled for multi-item basket; not displaying basket link", $self->user_id, [PERSONAL_APPOINTMENTS];
                    $self->app->log->debug("User [" . $self->user_id . "] not enrolled for multi-item basket; not displaying basket link [PERSONAL_APPOINTMENTS]");
                }
                $self->stash_basket_link($show_basket_link, $items);
            },
            not_authorised => sub {
                my ($api, $tx) = @_;
                $self->app->log->debug("TIMING basket (personal appointments) not_authorised '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
                #warn "User not authenticated; not displaying basket link", [PERSONAL_APPOINTMENTS];
                $self->app->log->warn("User not authenticated; not displaying basket link [PERSONAL_APPOINTMENTS]");
                $self->stash_basket_link(undef, 0);
            },
            failure        => sub {
                my ($api, $tx) = @_;
                $self->app->log->debug("TIMING basket (personal appointments) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
                log_error($tx, "failure");
                $self->stash_basket_link(undef, 0);
            },
            error          => sub {
                my ($api, $tx) = @_;
                $self->app->log->debug("TIMING basket (personal appointments) error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));
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
    my($tx, $error_type) = @_;

    my $error_code = $tx->error->{code} // 0;
    my $error_message = $tx->error->{message} // 0;
    my $error = (defined $error_code ? "[$error_code] " : '').$error_message;
    return if uc($error_type) eq 'FAILURE' && $error_code eq '404'; # don't log empty basket
    # TODO log
    #error "%s returned by getBasketLinks endpoint: '%s'. Not displaying basket link.", uc $error_type, $error, [PERSONAL_APPOINTMENTS];
}

# ------------------------------------------------------------------------------

sub _sort_filter {
    $a->{name} cmp $b->{name};
}

# ------------------------------------------------------------------------------

sub _build_filter {
    my ($filter) = @_;

    return {
        id   => $filter,
        name => AVAILABLE_CATEGORIES->{$filter},
    };
}

# ==============================================================================

1;
