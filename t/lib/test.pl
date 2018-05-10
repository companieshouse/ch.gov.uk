#!/usr/bin/perl

package main;

    use strict;
    use warnings;

    use TAP::Harness::JUnit;
    use TAP::Parser::Aggregator;
    use File::Find;
    use Getopt::Long;

    use FindBin;
    $ENV{PERL5LIB} = "$FindBin::Bin/../lib:".$ENV{PERL5LIB}.":$FindBin::Bin/lib/fakelib";

    our @tests;
    my $integration_testing;
    my @testfiles;

    # Populate which test cases to run
    sub filter_test_cases {

        my $SCM_FILTER = $ENV{FILTER_SCM} || '\/\.svn|\/\.git';
        my $TC_FILTER = $ENV{FILTER_TC} || '\.t$';
        my $TC_INTEGRATION = $ENV{FILTER_INTEGRATION} || 'integration';

        my $path = $File::Find::name;

        if ( ! ($path =~ m/$SCM_FILTER/) ) {

            #return if $path =~ /wellFormedVLD\.t$/;
            #return if $path =~ /dict\.t$/;
            #return if $path =~ /validHTML\.t$/;
            return if !$integration_testing and $path =~ m#/$TC_INTEGRATION/#;
            return if $path !~ /$TC_FILTER/;

            push( @tests, $path );
        }

    }

    GetOptions ( "integration" => \$integration_testing,
                 "test=s"      => \@testfiles)
        or die("Error in command line arguments\n");

    # Default the search if none passed
    if (!@testfiles){
        push( @testfiles, './' );
    }

    # Find tests
    find( {
            wanted => \&filter_test_cases,
            no_chdir => 1,
            follow => 1
          },
          @testfiles
    );

    # Create a harness
    my $harness = TAP::Harness::JUnit->new(
        {
             xmlfile => 'output.xml',
             merge => 1,
        }
    );

    # Execute the test cases
    my $aggregate = $harness->runtests( @tests );

    # Return status to caller (non-zero indicates test case failure)
    exit $aggregate->exit;

1;

