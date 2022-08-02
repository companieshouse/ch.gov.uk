use strict;
use warnings;

package MockResponse;

use Moose;

has 'expectedBody' => (is => 'rw', isa => 'Any');

sub json {
    my $self = shift;

    return $self->expectedBody;
}

package MockTransaction;

use Moose;

has 'mockResponse' => (is => 'rw', isa => 'Any');

sub success {
    my $self = shift;

    return $self->mockResponse;
}

package MockUserAgent;

use Moose;

has 'mockTransaction' => (is => 'ro', isa => 'Object');

sub get {
    my $self = shift;

    return $self->mockTransaction;
}

sub post {
    my ($self) = shift;

    return $self->mockTransaction;
}

package main;

use Test::More;

my $class = "ChGovUk::Controllers::Company::BasketClient";
my $basket_client;
my $mockResponse = MockResponse->new;
my $mockTransaction = MockTransaction->new({
    mockResponse => $mockResponse
});

subtest "Can use the basket client as a dependency" => sub {
    use_ok $class, "Use a BasketClient as a dependency";
};

subtest "Can instantiate a basket client" => sub {
    $basket_client = new_ok $class => [{
        user_agent      => MockUserAgent->new({ mockTransaction => $mockTransaction }),
        access_token    => "access_token",
        basket_url      => "basket_url",
        append_item_url => "append_item_url"
    }];
};

subtest "Can use a basket client to fetch a user's basket" => sub {
    can_ok $basket_client, qw(get_basket append_item_to_basket);
};

subtest "Get basket" => sub {
    plan tests => 3;
    subtest "Fetch and map user's basket where user is enrolled and basket has deliverable items" => sub {
        $mockResponse->expectedBody({
            items    => [ { kind => 'item#certified-copy' } ],
            enrolled => \1
        });
        my $actual = $basket_client->get_basket;
        is_deeply $actual, { enrolled => 1, hasDeliverableItems => 1 }, "Return value should match expected value";
    };

    subtest "Fetch and map user's basket where user is disenrolled and basket has no deliverable items" => sub {
        $mockResponse->expectedBody({
            items    => [ { kind => 'item#missing-image-delivery' } ],
            enrolled => \0
        });
        my $actual = $basket_client->get_basket;
        is_deeply $actual, { enrolled => 0, hasDeliverableItems => 0 }, "Return value should match expected value";
    };

    subtest "Return undef if an error occurs when fetching user's basket" => sub {
        $mockTransaction->mockResponse(undef);
        my $actual = $basket_client->get_basket;
        is $actual, undef, "Return value should be undefined";
    };
};

subtest "Append item to basket" => sub {
    plan tests => 2;
    subtest "Return status=0 if item successfully appended to basket" => sub {
        $mockTransaction->mockResponse({
            mockResponse => MockResponse->new
        });
        my $actual = $basket_client->append_item_to_basket({
            item_uri => "/path/to/item"
        });
        is_deeply $actual, { status => 0 }, "The method should indicate the operation completed successfully";
    };
    subtest "Return status=1 if error returned by client" => sub {
        $mockTransaction->mockResponse(undef);
        my $actual = $basket_client->append_item_to_basket({
            item_uri => "/path/to/item"
        });
        is_deeply $actual, { status => 1 }, "The method should indicate the operation failed";
    };
};

done_testing;
