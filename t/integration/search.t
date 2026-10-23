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

subtest 'PSC search with no term does not display a no-results message' => sub {
    $t->get_ok('/search/persons-with-significant-control')
        ->status_is(200)
        ->content_unlike(qr/No results found/);
};

subtest 'PSC search with no matches displays the no-results message' => sub {
    $t->get_ok('/search/persons-with-significant-control?q=zzqzxvbnmnoresults15424')
        ->status_is(200)
        ->content_like(qr/No results found/)
        ->content_like(qr/There are no results that match your search\. Try searching again using different search criteria\./);
};

done_testing();
