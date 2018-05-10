use strict;
use Test::More;
use Test::Exception;
use CH::Test;

use Readonly;
Readonly my $CLASS => 'ChGovUk::Models::Roles::Pager';

use_ok $CLASS;

    methods_ok $CLASS, qw( default_page_size );

    # -----------------------------------------------------
    # Can't instantiate a role directly, so need to test
    # by applying to a plain moose object.
    package Object;
    use Moose;
    with $CLASS;

    # Properties for convenience when we want to
    # set different values for various tests.
    has '_namespace'   => ( is => 'rw', default => '' );
    has '_total_items' => ( is => 'rw', default => 0 );

    # Add methods required by role
    # TODO nice to be able to test this requirement
    sub namespace   { $_[0]->{_namespace}   }
    sub total_items { $_[0]->{_total_items} }

    # Add methods that would be supplied by framework
    sub config {{
            paging => {
                page_size => 5,
                namespace1 => {
                    page_size => 10
                },
            },
    }}
    # -----------------------------------------------------

    package main;

    test_method_default_page_size();
    test_builder_page_size();
    test_builder_number_of_pages();

done_testing();

# ============================================================================== 

sub test_method_default_page_size {
    subtest "Test method - default_page_size" => sub {
        
        my $inst = Object->new();

        is($inst->default_page_size, 5, 'no namespace correct page size');

        $inst->_namespace('namespace1');
        is($inst->default_page_size, 10, 'has namespace correct page size');

    };
    return;
}

# ------------------------------------------------------------------------------ 

sub test_builder_page_size {
    subtest "Test builder - _build_page_size" => sub {
        my $inst = Object->new();
        is($inst->page_size, 5, 'read default page size');
    };
    return;
}

# ------------------------------------------------------------------------------ 

sub test_builder_number_of_pages {
    subtest "Test builder - _number_of_pages" => sub {

        subtest "10 items, 5 per page = 2 pages" => sub {
            my $inst = Object->new(); # Fresh for lazy build
            $inst->_namespace('');
            $inst->_total_items(10);
            is($inst->number_of_pages, 2, 'correct number of pages');
        };

        subtest "100 items, 10 per page = 10 pages (using namespace)" => sub {
            my $inst = Object->new(); # Fresh for lazy build
            $inst->_namespace( 'namespace1' );
            $inst->_total_items(100);
            is($inst->number_of_pages, 10, 'correct number of pages');
        };

    };
    return;
}

# ============================================================================== 

