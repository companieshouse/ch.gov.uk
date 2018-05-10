#!/home/cpan/perl/bin/perl

# Compare data from CHD with CHS API and Elastic Seearch ( via CHS API )

use CH::Perl;
use Test::More;
use List::MoreUtils qw(uniq);
use Data::Dumper;
use DateTime;

use lib 't/lib';
use Summariser::CHD;
use Summariser::CHS;
use Summariser::ES;

my $summariser_chs = Summariser::CHS->new();
my $summariser_chd = Summariser::CHD->new();
my $summariser_es  = Summariser::ES->new();

my @numbers_from_file = undef;
{
    local $/ = undef;
    open my $in, "<t/sanity_check.company_numbers";
    @numbers_from_file = split "\n", <$in>;
    close $in;
}

# Elastic Search only has recently dissolved companies
my $es_dissolved_threshold = DateTime->today()->subtract(years=>1)->ymd();

SKIP: {
    skip "No env var WANT_SANITY_CHECK", 1 unless defined $ENV{WANT_SANITY_CHECK};

    my @company_numbers = map {/^\s*(\w+)/ ? $1 : () } @numbers_from_file;
    
    my $blocking = 0; # Run tests in blocking mode
    
    for my $company_number ( @company_numbers ) {
    
        if ( $blocking ) {
            runs_tests_in_blocking_mode( $company_number );
        }
        else {
            runs_tests_in_non_blocking_mode( $company_number );
        }
    
    }

};

done_testing();

#-------------------------------------------------------------------------------

sub runs_tests_in_blocking_mode {
    my ( $company_number ) = @_;

    my $chd_summary = $summariser_chd->summary( $company_number, undef, );
    my $chs_api_summary = $summariser_chs->summary( $company_number, undef, );
    my $es_summary = $summariser_es->summary( $company_number, undef, );

    say "FINISH ( BLOCKING ):",Dumper({ chs_api_summary=>$chs_api_summary, chd_summary=>$chd_summary, es_summary=>$es_summary, });
    test_company( $company_number, $chd_summary, $chs_api_summary, $es_summary, );

}

#-------------------------------------------------------------------------------

sub runs_tests_in_non_blocking_mode {
    my ( $company_number ) = @_;

    my $delay = Mojo::IOLoop->delay();

    $delay->on( finish =>
        sub {
            my ( $delay, $chd_summary, $chs_api_summary, $es_summary, @args ) = @_;
            say "FINISH ( NON-BLOCKING ):",Dumper({ chs_api_summary=>$chs_api_summary, chd_summary=>$chd_summary, es_summary=>$es_summary, args => \@args });
            test_company( $company_number, $chd_summary, $chs_api_summary, $es_summary, );
            diag $chd_summary->{error} if $chd_summary->{error};
            diag $chs_api_summary->{error} if $chs_api_summary->{error};
            diag $es_summary->{error} if $es_summary->{error};
        }
    );
    $delay->on( error =>
        sub {
            my ( $delay, $chd_summary, $chs_api_summary, $es_summary, @args ) = @_;
            say "ERROR";
            test_company( $company_number, $chd_summary, $chs_api_summary, $es_summary, );
        }
    );

    say "XTRACKa:",@{$delay->remaining};
    $summariser_chd->summary( $company_number, $delay, );
    
    say "XTRACKb:",@{$delay->remaining};
    $summariser_chs->summary( $company_number, $delay, );
    
    say "XTRACKc:",@{$delay->remaining};
    $summariser_es->summary( $company_number, $delay, );

    say "XTRACKd:",@{$delay->remaining};
    $delay->wait;

    say "XTRACKe:",@{$delay->remaining};
}

#-------------------------------------------------------------------------------

sub test_company {
    my ( $company_number, $chd_summary, $chs_api_summary, $es_summary, ) = @_;
    
    subtest 'Company ' . $company_number => sub {
    
        ok( ! $chd_summary->{error}, 'Confirm that data available in CHD for company number ' . $company_number );

        SKIP: { 
            skip "Company not found in CHD", 3 if $chd_summary->{error};
        
        subtest 'Company Profile ' . $company_number => sub {
    
            is( $chs_api_summary->{company_name}, 
                $chd_summary->{company_name}, 
                'Compare CHD (expected) and CHS API (got) company names for company number ' . $company_number );
        
            is( $chs_api_summary->{company_number}, 
                $chd_summary->{company_number}, 
                'Compare CHD (expected) and CHS API (got) company numbers for company number ' . $company_number );
        
            # CHD sometimes shortens address by dropping element preceding postcode
            my $chd_address = $chd_summary->{registered_office_address} // '';
            my $chs_address = $chs_api_summary->{registered_office_address} // '';
            my $common_start_length = length $chd_address;
            my $omitted_length = length( $chs_address ) - $common_start_length;
            if ( $omitted_length ) {
                until ( substr($chs_address,0,$common_start_length) eq substr($chd_address,0,$common_start_length)) {
                    $common_start_length-- ;
                    if ( $common_start_length == 0 ) {
                        $omitted_length = 0;
                        last;
                    }
                }
            }
            is( substr($chs_address,0,$common_start_length) . substr($chs_address,$common_start_length+$omitted_length), 
                substr($chd_address,0,$common_start_length) . substr($chd_address,$common_start_length),
                'Compare CHD (expected) and CHS API (got) registered office addresses for company number ' . $company_number );
    
            SKIP: { 
                skip "Data not available in CHD", 7 unless $chd_summary->{available}->{company_details};

                SKIP: { 
                    skip "Data not available in CHD", 1 if $company_number =~ /^RC/;
                    is( $chs_api_summary->{incorporation_date}, 
                        $chd_summary->{incorporation_date}//'',
                        'Compare CHD (expected) and CHS API (got) incorporation dates for company number ' . $company_number );
                }

                is( $chs_api_summary->{dissolution_date}//'', 
                    $chd_summary->{dissolution_date}//'',
                    'Compare CHD (expected) and CHS API (got) dissolution dates for company number ' . $company_number );

                is( $chs_api_summary->{status}, 
                    $chd_summary->{status}//'', 
                        'Compare CHD (expected) and CHS API (got) status company number ' . $company_number );
    
                is( $chs_api_summary->{accounting_reference_date}, 
                    $chd_summary->{accounting_reference_date}//'', 
                    'Compare CHD (expected) and CHS API (got) accounting reference dates for company number ' . $company_number );
    
                is( $chs_api_summary->{last_return_to}, 
                    $chd_summary->{last_return_to}//'', 
                    'Compare CHD (expected) and CHS API (got) last return made up to dates for company number ' . $company_number );

                is( $chs_api_summary->{next_return_to}, 
                    $chd_summary->{next_return_to}//'', 
                    'Compare CHD (expected) and CHS API (got) next return due dates for company number ' . $company_number );

                is( $chs_api_summary->{next_accounts_due}, 
                    $chd_summary->{next_accounts_due}//'', 
                    'Compare CHD (expected) and CHS API (got) next accounts due dates for company number ' . $company_number );

                is( $chs_api_summary->{last_accounts_to}, 
                    $chd_summary->{last_accounts_to}//'', 
                        'Compare CHD (expected) and CHS API (got) last accounts made up to dates for company number ' . $company_number );
            }
        };
    
        subtest 'Company Filing History ' . $company_number => sub {
    
            is( $chs_api_summary->{combined_total}//0, 
                $chd_summary->{combined_total}//0, 
                'Compare CHD (expected) and CHS API (got) document counts for company number ' . $company_number . ' - all forms' );
            
            for my $type ( uniq keys $chd_summary->{combined}, keys $chs_api_summary->{combined} ) {
                if ( !
                    is( $chs_api_summary->{combined}->{$type}//0, 
                        $chd_summary->{combined}->{$type}//0, 
                        'Compare CHD (expected) and CHS API (got) document counts for company number ' . $company_number . ' - form ' . $type )
                ) {
                    my $chs_string = join(' ',sort @{ $chs_api_summary->{date_combined}->{$type} // [] });
                    my $chd_string = join(' ',sort @{ $chd_summary->{date_combined}->{$type} // [] });
                    my $common_length = length $chd_string >= length $chs_string ? length $chd_string : length $chs_string;
                    until ( substr($chs_string,0,$common_length) eq substr($chd_string,0,$common_length) ) {
                        $common_length -= 9;
                    }
                    $common_length = 0 if $common_length < 0;
                    diag 'CHS: ', $common_length?'...':'', substr($chs_string,$common_length) if $chs_string;
                    diag 'CHD: ', $common_length?'...':'', substr($chd_string,$common_length) if $chd_string;
                }
            }    
    
        };

        subtest 'Company Officers Listing ' . $company_number => sub {
    
            is( $chs_api_summary->{officer_total}//0, 
                $chd_summary->{officer_total}//0, 
                'Compare CHD (expected) and CHS API (got) officer counts for company number ' . $company_number . ' - all officers' );
            
            for my $officer_key ( uniq keys $chd_summary->{officers}, keys $chs_api_summary->{officers} ) {
                ok( exists $chd_summary->{officers}->{$officer_key}, 'Officer exists on CHD for company number ' . $company_number . ' - ' . $officer_key )
                    and
                ok( exists $chs_api_summary->{officers}->{$officer_key}, 'Officer exists on CHS for company number ' . $company_number . ' - ' . $officer_key )
                    and 
                is( $chs_api_summary->{officers}->{$officer_key}//0, 
                    $chd_summary->{officers}->{$officer_key}//0, 
                    'Compare CHD (expected) and CHS API (got) officer counts for company number ' . $company_number . ' - ' . $officer_key );
            }    
        };
    
        subtest 'Elastic Search ' . $company_number => sub {
    
            my $chd_dissolution_date = $chd_summary->{dissolution_date}//'';
            SKIP: { 
                skip "Not expecting data to be available in Elastic Search for company dissolved before $es_dissolved_threshold", 5 if $chd_dissolution_date lt $es_dissolved_threshold;

                my $have_result = defined $es_summary->{company_number};
                ok( $have_result, 'Elastic Search returned a result for company number ' . $company_number );
    #            diag explain "HAVE_RESULT:", explain $es_summary;
    
                SKIP: { 
                    skip "Data not available in Elastic Search", 4 unless $have_result;
    
                    is( $es_summary->{company_name}=~s/\s+//gr,
                        $chd_summary->{company_name}=~s/\s+//gr,
                        'Compare CHD (expected) and ES (got) company names ( ignoring whitespace ) for company number ' . $company_number );
            
                    is( $es_summary->{company_number}, 
                        $chd_summary->{company_number}, 
                        'Compare CHD (expected) and ES API (got) company numbers for company number ' . $company_number );
            
                    SKIP: { 
                        skip "Data not available in CHD", 2 unless $chd_summary->{available}->{company_details};
    
                        SKIP: { 
                            skip "Data not available in CHD", 1 if $company_number =~ /^RC/;
                            if ( $chd_summary->{status} eq 'dissolved' ) {
                                is( $es_summary->{date}, 
                                    $chd_summary->{dissolution_date}//'',
                                    'Compare CHD (expected) and ES API (got) dissolution dates for company number ' . $company_number );
                            }
                            else {
                                is( $es_summary->{date}, 
                                    $chd_summary->{incorporation_date}//'',
                                    'Compare CHD (expected) and ES API (got) incorporation dates for company number ' . $company_number );
                            }
                        }
    
                        is( $es_summary->{status}, 
                            $chd_summary->{status}//'', 
                                'Compare CHD (expected) and ES API (got) status company number ' . $company_number );
                    }
                }
            };
        };
    };

    }

}

#-------------------------------------------------------------------------------
