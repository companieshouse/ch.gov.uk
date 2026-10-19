use CH::Perl;
use CH::Test;
use Test::More;
use Readonly;
use Mojo::IOLoop;
use Mojo::Util qw(monkey_patch);

Readonly my $CLASS  => 'ChGovUk::Controllers::PscNotifications';
Readonly my $PSC_ID => 'wXCfzvf6TN-uyJxGFbcMUY5P1XA';

use_ok $CLASS;
new_ok $CLASS;
methods_ok $CLASS, qw(get);

# ==============================================================================
# Test doubles

{
    package Local::FakeTx;

    sub new     { my ($class, %args) = @_; return bless {%args}, $class }
    sub success { my ($self) = @_; return $self->{json} ? $self : undef }
    sub json    { return $_[0]->{json} }
    sub error   { return $_[0]->{error} }
}

{
    package Local::FakeRequest;

    sub new           { my ($class, %args) = @_; return bless {%args}, $class }
    sub notifications { my ($self, $query) = @_; $self->{api}->{notifications_query} = $query; return $self }
    sub profile       { return $_[0] }
    sub force_api_key { my ($self) = @_; push @{ $self->{api}->{forced} }, $self->{company_number}; return $self }
    sub get           { return $_[0] }
    sub on            { my ($self, %handlers) = @_; $self->{handlers} = \%handlers; return $self }
    sub execute       { my ($self) = @_; $self->{respond}->($self->{handlers}); return $self }
}

{
    package Local::FakeApi;

    sub new {
        my ($class, %args) = @_;
        return bless { %args, company_calls => [], forced => [] }, $class;
    }

    sub pscs {
        my ($self, $psc_id) = @_;
        $self->{psc_id} = $psc_id;
        return Local::FakeRequest->new(api => $self, respond => $self->{notifications});
    }

    sub company {
        my ($self, $company_number) = @_;
        push @{ $self->{company_calls} }, $company_number;
        return Local::FakeRequest->new(
            api            => $self,
            company_number => $company_number,
            respond        => sub { $self->{profiles}->($company_number, @_) },
        );
    }
}

# ==============================================================================
# Controller stubs

my $api;
my %outcome;

monkey_patch $CLASS,
    ch_api           => sub { $api },
    config           => sub { { psc_notifications => { items_per_page => 10 } } },
    get_filter       => sub { '' },
    get_basket_link  => sub { },
    render_later     => sub { $_[0] },
    render           => sub { $outcome{rendered}++; $outcome{done} = 1; 1 },
    render_not_found => sub { $outcome{not_found}++; $outcome{done} = 1; 1 },
    render_exception => sub {
        my ($c, $message) = @_;
        push @{ $outcome{exceptions} }, $message;
        $outcome{done} = 1;
        return 1;
    };

# ==============================================================================
# Helpers

sub tx { return Local::FakeTx->new(@_) }

sub notification {
    my ($company_number) = @_;
    return {
        notified_on        => '2026-09-17',
        natures_of_control => ['ownership-of-shares-25-to-50-percent'],
        notified_to        => defined $company_number ? { company_number => $company_number } : {},
    };
}

sub notifications_success {
    my (@items) = @_;
    return sub {
        my ($handlers) = @_;
        $handlers->{success}->(undef, tx(json => {
            items         => [@items],
            total_results => scalar @items,
        }));
    };
}

sub profile_success {
    my (%companies) = @_;
    return sub {
        my ($company_number, $handlers) = @_;
        $handlers->{success}->(undef, tx(json => $companies{$company_number}));
    };
}

sub run_get {
    my (%args) = @_;

    %outcome = (rendered => 0, not_found => 0, exceptions => [], done => 0);
    $api = Local::FakeApi->new(%args);

    my $c = $CLASS->new;
    $c->param(persons_with_significant_control_id => $PSC_ID);
    $c->get;

    my $ticks = 0;
    Mojo::IOLoop->one_tick while !$outcome{done} && $ticks++ < 10;

    return $c;
}

# ==============================================================================
# Tests

subtest 'requests notifications for the PSC with paging parameters' => sub {
    run_get(
        notifications => notifications_success(),
        profiles      => sub { fail 'profile should not be requested' },
    );

    is $api->{psc_id}, $PSC_ID, 'PSC id passed to API';
    is_deeply $api->{notifications_query},
        { filter => '', items_per_page => 10, start_index => 0 },
        'paging parameters passed to API';
};

subtest 'enriches notifications with company name and status' => sub {
    my $c = run_get(
        notifications => notifications_success(
            notification('12345673'),
            notification('87654321'),
            notification('12345673'),
        ),
        profiles => profile_success(
            '12345673' => { company_name => 'FIRST LTD',  company_status => 'active' },
            '87654321' => { company_name => 'SECOND LTD', company_status => 'dissolved' },
        ),
    );

    is $outcome{rendered}, 1, 'page rendered exactly once';
    is_deeply $outcome{exceptions}, [], 'no exceptions rendered';

    is_deeply $api->{company_calls}, ['12345673', '87654321'],
        'each company profile requested once';
    is_deeply $api->{forced}, ['12345673', '87654321'],
        'profile requests use the API key';

    my $notifications = $c->stash('psc')->{notifications};

    is $notifications->[0]{notified_to}{company_name},   'FIRST LTD',  'first notification name';
    is $notifications->[0]{notified_to}{company_status}, 'active',     'first notification status';
    is $notifications->[1]{notified_to}{company_name},   'SECOND LTD', 'second notification name';
    is $notifications->[1]{notified_to}{company_status}, 'dissolved',  'second notification status';
    is $notifications->[2]{notified_to}{company_name},   'FIRST LTD',  'duplicate company notification also enriched';

    is $c->stash('psc')->{total_results}, 3, 'total results stashed';
    ok $c->stash('paging'),     'paging stashed';
    ok $c->stash('categories'), 'categories stashed';
};

subtest 'renders without profile lookups when there are no notifications' => sub {
    my $c = run_get(
        notifications => notifications_success(),
        profiles      => sub { fail 'profile should not be requested' },
    );

    is $outcome{rendered}, 1, 'page rendered';
    is_deeply $api->{company_calls}, [], 'no profile requests made';
    is_deeply $c->stash('psc')->{notifications}, [], 'empty notifications stashed';
};

subtest 'renders an exception when a notification has no company number' => sub {
    run_get(
        notifications => notifications_success(notification(undef)),
        profiles      => sub { fail 'profile should not be requested' },
    );

    is $outcome{rendered}, 0, 'page not rendered';
    is_deeply $outcome{exceptions}, ['PSC notification is missing a company_number'],
        'missing company number exception rendered';
    is_deeply $api->{company_calls}, [], 'no profile requests made';
};

subtest 'renders an exception when a company profile request fails' => sub {
    run_get(
        notifications => notifications_success(notification('12345673')),
        profiles      => sub {
            my ($company_number, $handlers) = @_;
            $handlers->{failure}->(undef, tx(error => { code => 404, message => 'Not Found' }));
        },
    );

    is $outcome{rendered}, 0, 'page not rendered';
    is_deeply $outcome{exceptions},
        ['Failed to retrieve company profile [12345673]: Not Found'],
        'profile failure exception rendered';
};

subtest 'renders an exception when a company profile request errors' => sub {
    run_get(
        notifications => notifications_success(notification('12345673')),
        profiles      => sub {
            my ($company_number, $handlers) = @_;
            $handlers->{error}->(undef, 'Connection refused');
        },
    );

    is $outcome{rendered}, 0, 'page not rendered';
    is_deeply $outcome{exceptions},
        ['Error retrieving company profile [12345673]: Connection refused'],
        'profile error exception rendered';
};

subtest 'renders only after all profiles return, reporting any failure' => sub {
    run_get(
        notifications => notifications_success(
            notification('12345673'),
            notification('87654321'),
        ),
        profiles => sub {
            my ($company_number, $handlers) = @_;
            return $handlers->{success}->(undef, tx(json => {
                company_name   => 'FIRST LTD',
                company_status => 'active',
            })) if $company_number eq '12345673';

            $handlers->{failure}->(undef, tx(error => { code => 500, message => 'Server Error' }));
        },
    );

    is $outcome{rendered}, 0, 'page not rendered after partial failure';
    is scalar @{ $outcome{exceptions} }, 1, 'exception rendered exactly once';
    like $outcome{exceptions}[0], qr/\[87654321\]: Server Error/, 'failing company reported';
};

subtest 'renders not found when the notifications request returns 404' => sub {
    run_get(
        notifications => sub {
            my ($handlers) = @_;
            $handlers->{failure}->(undef, tx(error => { code => 404, message => 'Not Found' }));
        },
        profiles => sub { fail 'profile should not be requested' },
    );

    is $outcome{not_found}, 1, 'not found rendered';
    is $outcome{rendered},  0, 'page not rendered';
};

done_testing;