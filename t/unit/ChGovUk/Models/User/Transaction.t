use strict;
use Test::More;
use CH::Test;
use CH::Util::DateHelper;
use CH::MojoX::Plugin::Config;

use Readonly;
Readonly my $CLASS => 'ChGovUk::Models::User::Transaction';

use_ok( $CLASS );

    methods_ok(
        $CLASS,
        qw( 
            submission_number status form_type order_date_time company_number company_name
        ),
    );

    my $app = get_fake_app();   # Fake::Mojolicious::App
    $app->plugin('CH::MojoX::Plugin::Config');

    my $test_data = constructor_arguments();

    my $filing = $CLASS->new(
        %$test_data,
    );

    isa_ok( $filing, $CLASS );

    # Test all method calls
    for my $field ( keys %$test_data ) {
        if ( my $ref = ref( $test_data->{$field} ) ) {
            # Test method call that returns a reference
            my $result = isa_ok( $filing->$field, $ref );
            if ( $ref eq 'DateTime::Tiny' ) {
                # Test method call that returns a date object
                for my $sub_field ( keys %{$test_data->{$field}} ) {
                    is( $filing->$field->{$sub_field}, $test_data->{$field}{$sub_field}, "Get field value for '$field/$sub_field'" );
                }
            }
        }
        else {
            # Test method call that returns a scalar value
            is( $filing->$field, $test_data->{$field}, "Get value for '$field'" );
        }
    }
    
    # Similar but not identical to above loop ( doesn't handle differences in time )
    is_deeply( $filing, $test_data, 'Checking filing data structure' );

done_testing( );

#------------------------------------------------------------------------------

# Data setup methods
#

# Normal set of arguments to new()

sub constructor_arguments {
    return {
        submission_number => '000-002983',
        status            => '39',
        form_type         => '10401',
        order_date_time   => CH::Util::DateHelper->from_internal( '20130605' ),
        company_number    => '00000001',
        company_name      => 'NON EXISTENT LTD.',
        document_sequence => '',
        document_filename => '',
        attachment_id     => '',
        _flagless_form_type => '10401',
    };
}



