#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Differences;

subtest 'Instantiate class' => sub {
    plan tests => 4;

    use_ok 'CH::Util::Pager';
    new_ok 'CH::Util::Pager';

    can_ok('CH::Util::Pager', qw(first_page last_page first last previous_page next_page));
    my $obj = CH::Util::Pager->new();
    isa_ok( $obj, 'CH::Util::Pager' );
};

subtest 'attribute defaults' => sub {
    plan tests => 4;

    my $obj = CH::Util::Pager->new();
    is $obj->current_page, 1, "initial current page 1";
    is $obj->total_entries,  0, "initial total entries";
    is $obj->entries_per_page, 10, "default entries per page";
    is $obj->pages_per_set, 10, "default pages_per_set";
};

subtest 'first page set' => sub {
    plan tests => 3;

    my $obj = CH::Util::Pager->new(total_entries => 20, entries_per_page => 5, pages_per_set => 2);
    eq_or_diff $obj->pages_in_set(), [ 1, 2 ], "first page set";
    is $obj->next_set(), 3, "next page set";
    is $obj->previous_set(), undef, "No previous page set";
};

subtest 'second page set' => sub {
    plan tests => 3;

    my $obj = CH::Util::Pager->new(total_entries => 20, entries_per_page => 5, pages_per_set => 2);
    $obj->pages_in_set();
    $obj->current_page($obj->next_set());
    eq_or_diff $obj->pages_in_set(), [ 3, 4 ], "second page set";
    is $obj->next_set(), 3, "end of pages";
    is $obj->previous_set(), 2, "previous set at beginning";
};

done_testing();
