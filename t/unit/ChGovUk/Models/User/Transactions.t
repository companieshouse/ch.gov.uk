use strict;
use Test::More;
use CH::Test;

use Readonly;
Readonly my $CLASS => 'ChGovUk::Models::User::Transactions';

use_ok( $CLASS );

    methods_ok(
        $CLASS,
        qw( 
            filings
        ),
    );
    
    my $constructor_arguments = constructor_arguments();
    
    my $override_results = override_results();
    
    my $filings = $CLASS->new(
    
        # Normal arguments
        #
        %$constructor_arguments,
    
        # Additional arguments to prevent builder methods
        # being called which require a database
        #
        _results => $override_results,
    
    );
    
    isa_ok( $filings, $CLASS );
    
    # Test the filings()
    my $expected_filings = expected_filings();
    is_deeply( $filings->filings, $expected_filings, 'Recent filings as expected' );
    
    is( $filings->days, $constructor_arguments->{days}, 'Days as expected' );

done_testing( );

#------------------------------------------------------------------------------

# Data setup methods
#

# Normal set of arguments to new()
#
sub constructor_arguments {
    return {
        auth_id => '0000',
        days => 15,
    };
}

# Additional argument to new() to set the private '_results'
# variable and prevent the builder method being called
# which would try to access the database via external module calls
#
sub override_results {
    return [
        {
          'language' => 'en',
          'status' => '2',
          'docSeq' => undef,
          'subnumber' => '000-002983',
          'authID' => '9342',
          'attachmentID' => '0',
          'docFilename' => undef,
          'coNumb' => '00000001',
          'formType' => '10401',
          'coName' => 'NON EXISTENT LTD.',
          'orddtetme' => '20130605',
        },
        {
          'language' => 'en',
          'status' => '2',
          'docSeq' => undef,
          'subnumber' => '000-053403',
          'authID' => '9342',
          'attachmentID' => '0',
          'docFilename' => undef,
          'coNumb' => '00000001',
          'formType' => '10401',
          'coName' => 'NON EXISTENT LTD.',
          'orddtetme' => '20130604'
        },
    ];
}

# Expected return value from filings() method
#
sub expected_filings {
    return [
        bless( {
#                 '_flagless_form_type' => undef,
                 'attachment_id' => '',
                 'document_filename' => '',
                 'company_number' => '00000001',
                 'order_date_time' => bless( {
                                               'hour' => 0,
                                               'minute' => 0,
                                               'second' => 0,
                                               'month' => 6,
                                               'day' => 5,
                                               'year' => 2013
                                             }, 'DateTime::Tiny' ),
                 'status' => '2',
                 'company_name' => 'NON EXISTENT LTD.',
                 'document_sequence' => '',
                 'form_type' => '10401',
                 'submission_number' => '000-002983',
               }, 'ChGovUk::Models::User::Transaction' ),
        bless( {
#                 '_flagless_form_type' => undef,
                 'attachment_id' => '',
                 'document_filename' => '',
                 'company_number' => '00000001',
                 'order_date_time' => bless( {
                                               'hour' => 0,
                                               'minute' => 0,
                                               'second' => 0,
                                               'month' => 6,
                                               'day' => 4,
                                               'year' => 2013
                                             }, 'DateTime::Tiny' ),
                 'status' => '2',
                 'company_name' => 'NON EXISTENT LTD.',
                 'document_sequence' => '',
                 'form_type' => '10401',
                 'submission_number' => '000-053403',
               }, 'ChGovUk::Models::User::Transaction' )
    ];
}
