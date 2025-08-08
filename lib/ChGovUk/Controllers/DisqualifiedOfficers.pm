package ChGovUk::Controllers::DisqualifiedOfficers;

use Mojo::Base 'Mojolicious::Controller';

use CH::Perl;
use CH::Util::Pager;
use Time::HiRes qw(tv_interval gettimeofday);
use Scalar::Util qw(refaddr);

# ------------------------------------------------------------------------------

sub get_natural {
    my ($self) = @_;

    $self->get_disqualification('natural');
}

# ------------------------------------------------------------------------------

sub get_corporate {
    my ($self) = @_;

    $self->get_disqualification('corporate');
}

# ------------------------------------------------------------------------------

sub get_disqualification {
    my ($self, $disqualification_type) = @_;

    $self->render_later;

    my $officer_id           = $self->param('officer_id');
    my $is_corporate_officer = $disqualification_type eq 'corporate' ? 1 : 0;

    #trace 'Fetching disqualification for officer: [%s]', $officer_id;
    $self->app->log->trace("Fetching disqualification for officer: [$officer_id]");

    my $start = [Time::HiRes::gettimeofday()];
    $self->app->log->debug("TIMING disqualified_officer '" . refaddr(\$start) . "'");
    $self->ch_api->disqualified_officer($officer_id)->$disqualification_type->get->on(
        success => sub {
            my ($api, $tx) = @_;
            $self->app->log->debug("TIMING disqualified_officer success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

            my $results = $tx->res->json;

            my $officer_data = $is_corporate_officer ? _get_corporate_data($results) : _get_natural_data($results);

            $self->stash(
                disqualifications    => $results->{disqualifications},
                exemptions           => $results->{permissions_to_act},
                is_corporate_officer => $is_corporate_officer,
                %$officer_data,
            );

            return $self->render(template => 'disqualified_officer/view');
        },
        failure => sub {
            my ($api, $tx) = @_;
            $self->app->log->debug("TIMING disqualified_officer failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

            my ($error_code, $error_message) = @{ $tx->error }{qw(code message)};

            if ($error_code and $error_code == 404) {
                #trace 'Disqualified_officer officer not found. Officer ID: [%s]', $officer_id;
                $self->app->log->trace("Disqualified_officer officer not found. Officer ID: [$officer_id]");
                return $self->reply->not_found;
            }

            #error 'Failed to retrieve disqualified_officer with officer_id: [%s]: [%s]', $officer_id, $error_message;
            $self->app->log->error("Failed to retrieve disqualified_officer with officer_id: [$officer_id]: [$error_message]");
            return $self->render_exception("Failed to retrieve disqualified_officer: $error_message");
        },
        error => sub {
            my ($api, $error) = @_;
            $self->app->log->debug("TIMING disqualified_officer error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start));

            #error 'Error retrieving disqualified_officer with officer_id [%s]: [%s]', $officer_id, $error;
            $self->app->log->error("Error retrieving disqualified_officer with officer_id [$officer_id]: [$error]");
            return $self->render_exception("Error retrieving disqualified_officer: $error");
        },
    )->execute;
}

# ------------------------------------------------------------------------------

sub _get_corporate_data {
    my ($results) = @_;

    return {
        name                    => $results->{name},
        country_of_registration => $results->{country_of_registration},
        company_number          => $results->{company_number},
    };
}

# ------------------------------------------------------------------------------

sub _get_natural_data {
    my ($results) = @_;

    return {
        name          => (join ' ', grep { defined } map { $results->{$_} } qw(forename other_forenames surname)),
        date_of_birth => $results->{date_of_birth},
        nationality   => $results->{nationality},
    };
}

# ==============================================================================

1;
