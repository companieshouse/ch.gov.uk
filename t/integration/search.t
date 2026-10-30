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

subtest 'PSC name links to its notifications in the same tab' => sub {
    my $psc_id = 'pscdata1';
    my $expected_url =
        "/persons-with-significant-control/$psc_id/notifications";
    my $selector = '#results li.type-psc h3 a';

    $t->get_ok('/search/persons-with-significant-control?q=Demo')
        ->status_is(200)
        ->element_exists($selector)
        ->text_is($selector, 'Dr Ralph Person')
        ->element_exists(
            "$selector[href=\"$expected_url\"]",
            'PSC name links to the expected notifications page'
        )
        ->element_exists_not(
            "$selector[target]",
            'PSC link does not specify another browsing context'
        );
};

done_testing();
