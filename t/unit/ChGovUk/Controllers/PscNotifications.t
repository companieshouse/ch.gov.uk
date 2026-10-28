use CH::Perl;
use CH::Test;
use Test::More;
use Readonly;
use Mojo::IOLoop;
use Mojo::DOM;
use Mojo::URL;
use Mojo::Util qw(monkey_patch);
use Text::Xslate;

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

    sub uri {
        my ($self, $uri) = @_;
        my $url = Mojo::URL->new($uri);
        $self->{notifications_path} = $url->path->to_string;
        $self->{notifications_query} = $url->query->to_hash;
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
    $c->param(page => $args{page}) if defined $args{page};
    $c->get;

    my $ticks = 0;
    Mojo::IOLoop->one_tick while !$outcome{done} && $ticks++ < 10;

    return $c;
}

sub notification_page {
    my ($c) = @_;
    local *ChGovUk::Controllers::PscNotifications::url_for =
        sub { Mojo::URL->new("/persons-with-significant-control/$PSC_ID/notifications") };
    local *ChGovUk::Controllers::PscNotifications::suppressed_date_as_string =
        sub { 'January 1980' };

    my $renderer = Text::Xslate->new(
        path       => [ { 'base.tx' => "% block content -> { ; }\n" }, 'templates' ],
        syntax     => 'Kolon',
        tag_start  => '<%',
        tag_end    => '%>',
        line_start => '%',
        function   => { l => sub { $_[0] } },
    );

    return Mojo::DOM->new($renderer->render('psc_notifications/get.html.tx', {
        %{ $c->stash },
        c       => $c,
        cdn_url => 'example.test',
    }));
}

# ==============================================================================
# Tests

subtest 'requests notifications for the PSC with paging parameters' => sub {
    run_get(
        notifications => notifications_success(),
        profiles      => sub { fail 'profile should not be requested' },
    );

    is $api->{notifications_path}, "/persons-with-significant-control/$PSC_ID/notifications",
        'PSC notifications path passed to API';
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

for my $total (75, 106, 350, 351, 700) {
    subtest "out-of-range page retains metadata and final page links for $total notifications" => sub {
        local *ChGovUk::Controllers::PscNotifications::config =
            sub { { psc_notifications => { items_per_page => 35 } } };

        my $c = run_get(
            page => 10000,
            notifications => sub {
                my ($handlers) = @_;
                $handlers->{success}->(undef, tx(json => {
                    name          => 'PAGINATION TEST',
                    date_of_birth => { month => 1, year => 1980 },
                    items         => [],
                    total_results => $total,
                }));
            },
            profiles => sub { fail 'profile should not be requested' },
        );

        my $last_page = int(($total + 34) / 35);
        my $first_page = $last_page > 10 ? $last_page - 9 : 1;
        my $paging = $c->stash('paging');

        is $outcome{rendered}, 1, 'page rendered';
        is $outcome{not_found}, 0, 'not found not rendered';
        is_deeply $outcome{exceptions}, [], 'no exceptions rendered';
        is $api->{notifications_query}{start_index}, 349965, 'requested offset not clamped';
        is_deeply $c->stash('psc')->{notifications}, [], 'no notification entries';
        is $c->stash('psc')->{name}, 'PAGINATION TEST', 'PSC name retained';
        is $c->stash('psc')->{total_results}, $total, 'real total retained';
        is_deeply $c->stash('psc')->{date_of_birth}, { month => 1, year => 1980 },
            'date of birth retained';
        is_deeply $paging->{page_set}, [ $first_page .. $last_page ],
            'last ten valid pages, or all available pages';
        is $paging->{previous_page}, $last_page, 'Previous targets last valid page';
        is $paging->{next_page}, undef, 'no Next link';
        is $paging->{current_page_number}, 10000, 'no valid page is selected';
        is_deeply $api->{company_calls}, [], 'no company profile requests';

        my $dom = notification_page($c);
        is $dom->at('#psc-name')->all_text, 'PAGINATION TEST', 'PSC name displayed';
        like $dom->at('#psc-notifications')->all_text, qr/Total number of notifications $total/,
            'real total displayed';
        is $dom->find('.notifications-list > div')->size, 0, 'no rendered notification entries';
        is $dom->find('.pager strong')->size, 0, 'no highlighted page';
        is $dom->find('#next-page')->size, 0, 'no rendered Next link';
        is $dom->at('.pager li:first-child a')->attr('id'), 'previous-page',
            'Previous is leftmost';
        like $dom->at('#previous-page')->attr('href'), qr/\?page=$last_page$/,
            'Previous links to last valid page';
        is_deeply [
            $dom->find('.pager a[id^="page-number-"]')->map(sub {
                my $label = $_->all_text;
                $label =~ s/\s+//g;
                return 0 + $label;
            })->each
        ], [ $first_page .. $last_page ], 'correct numbered links rendered';
    };
}

subtest 'last valid page keeps its entries and normal Previous target' => sub {
    local *ChGovUk::Controllers::PscNotifications::config =
        sub { { psc_notifications => { items_per_page => 35 } } };

    my $c = run_get(
        page => 3,
        notifications => sub {
            my ($handlers) = @_;
            $handlers->{success}->(undef, tx(json => {
                items         => [ map { notification('12345673') } 1 .. 5 ],
                total_results => 75,
            }));
        },
        profiles => profile_success(
            '12345673' => { company_name => 'FIRST LTD', company_status => 'active' },
        ),
    );

    is $outcome{rendered}, 1, 'page rendered';
    is $api->{notifications_query}{start_index}, 70, 'last page offset';
    is scalar @{ $c->stash('psc')->{notifications} }, 5, 'last page entries retained';
    is $c->stash('paging')->{previous_page}, 2, 'Previous targets preceding page';
    is $c->stash('paging')->{current_page_number}, 3, 'valid page selected';
    is $c->stash('paging')->{next_page}, undef, 'no Next on last page';
};

done_testing;