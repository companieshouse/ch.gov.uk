use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use CH::Test;

use lib 't/lib';

my $t = Test::Mojo->new('ChGovUk');

# must provide at least some customer_feedback
subtest 'no feedback' => sub {
    $t->get_ok('/customer-feedback')
        ->status_is(400)
        ->json_is('/message', 'No feedback entered. Please enter some feedback.')
        ->json_is('/error_code', 400);
};

# only customer_feedback is required
subtest 'handle feedback' => sub {
    $t->get_ok('/customer-feedback?customer_feedback=great+site')
        ->status_is(200)
        ->json_is('/message', 'Feedback saved OK');
};


# if an email address is provided - do a basic validity check
subtest 'feedback with invalid email address' => sub {
    $t->get_ok('/customer-feedback?customer_feedback=really+great+site&customer_email=no_at_symbol_here')
        ->status_is(400)
        ->json_is('/message', 'Invalid email address. Please enter a valid email address.');
};

# handle all the expected data
subtest 'feedback with invalid email address' => sub {
    $t->get_ok('/customer-feedback?customer_feedback=very+happy&customer_email=a@aaa.com&source_url=http://chs-dev&customer_name=Joe+Bloggs')
        ->status_is(200)
        ->json_is('/message', 'Feedback saved OK');
};


done_testing();
