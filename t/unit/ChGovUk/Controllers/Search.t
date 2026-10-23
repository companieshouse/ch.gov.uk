use CH::Perl;
use CH::Test;
use Test::More;
use Mojo::Util qw(monkey_patch);

my $class = 'ChGovUk::Controllers::Search';

use_ok $class;

{
    package Local::SearchResponse;

    sub new  { return bless { json => $_[1] }, $_[0] }
    sub json { return $_[0]->{json} }
}

{
    package Local::SearchTransaction;

    sub new { return bless { response => $_[1] }, $_[0] }
    sub res { return $_[0]->{response} }
}

{
    package Local::SearchEndpoint;

    sub new {
        my ($class, $api) = @_;
        return bless { api => $api }, $class;
    }

    sub query {
        my ($self, $query) = @_;
        $self->{api}->{query} = $query;
        return $self;
    }

    sub get { return $_[0] }

    sub on {
        my ($self, %handlers) = @_;
        $self->{handlers} = \%handlers;
        return $self;
    }

    sub execute {
        my ($self) = @_;
        $self->{api}->{executed}++;
        $self->{handlers}->{success}->(
            undef,
            Local::SearchTransaction->new(
                Local::SearchResponse->new($self->{api}->{response})
            )
        );
        return $self;
    }
}

{
    package Local::SearchApi;

    sub new { return bless {}, $_[0] }

    sub uri {
        my ($self, $path) = @_;
        $self->{path} = $path;
        return Local::SearchEndpoint->new($self);
    }
}

{
    package Local::SearchHeaders;

    sub accept { return 'text/html' }
}

{
    package Local::SearchRequest;

    sub headers { return bless {}, 'Local::SearchHeaders' }
}

my $api;
my $rendered = 0;
my @formatted_dates;

monkey_patch $class,
    ch_api => sub { return $api },
    param => sub { return { q => 'Demo', search_type => 'persons-with-significant-control', page => 1 }->{$_[1]} },
    session => sub { return $_[0] },
    req => sub { return bless {}, 'Local::SearchRequest' },
    config => sub { return { elasticsearch => { max_pages => 2500, max_results => 50000 } } },
    get_basket_link => sub { return },
    render_later => sub { return $_[0] },
    render => sub { $rendered++; return 1 },
    isodate_as_string => sub {
        my ($self, $date, $format) = @_;
        push @formatted_dates, [$date, $format];
        return 'April 1980';
    };

subtest 'PSC search uses the PSC endpoint and renders the API response' => sub {
    $api = Local::SearchApi->new;
    $api->{response} = {
        kind => 'search#persons-with-significant-control',
        total_results => 1,
        items_per_page => 20,
        items => [{
            kind => 'searchresults#persons-with-significant-control',
            title => 'Dr Demo Person',
            notification_count => 3,
            date_of_birth => { month => 4, year => 1980 },
            address => { premises => '1', address_line_1 => 'Demo Street' },
        }],
    };
    $rendered = 0;
    @formatted_dates = ();

    my $controller = $class->new;
    $controller->results;

    is $api->{path}, '/search/persons-with-significant-control',
        'requests the PSC-only search endpoint';
    is_deeply $api->{query}, { q => 'Demo', num => 20, start_index => 0 },
        'passes the term and paging arguments';
    is $api->{executed}, 1, 'executes the PSC API request';
    is $rendered, 1, 'renders the results page';
    is_deeply \@formatted_dates, [['1980-04-01', '%B %Y']],
        'formats PSC DOB as month and year';
    is $controller->stash('results')->{items}->[0]->{date_of_birth}, 'April 1980',
        'stores the formatted DOB for the template';
};

done_testing;