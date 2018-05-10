use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use CH::Test;

use lib 't/lib';

my $t = Test::Mojo->new('ChGovUk');


subtest 'Check search' => sub {
    $t->get_ok('/search?q=girl')
        ->status_is(200)
        ->content_like(qr/GIRL/);
};

done_testing();
