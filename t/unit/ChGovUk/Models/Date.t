use strict;
use Test::More;
use CH::Test;
use ChGovUk::Models::DataAdapter;

use Readonly;
Readonly my $MODEL => 'ChGovUk::Models::Date';

use_ok $MODEL;

set_constructor_args $MODEL, [ data_adapter => ChGovUk::Models::DataAdapter->new ];

    new_ok $MODEL;

    methods_ok $MODEL, qw(to_date);

    test_method_to_date();

done_testing();

# ------------------------------------------------------------------------------

sub test_method_to_date {
    subtest "Test method - to date" => sub {
        
        my $model = new_inst $MODEL;

        $model->day(6);
        $model->month(2);
        $model->year(1978);

        my $date = $model->to_date;
        isa_ok($date, "DateTime::Tiny", "Correct type returned");
        is(CH::Util::DateHelper->as_string($date), "6 February 1978","Correct date");

    };
    return;
}

# ------------------------------------------------------------------------------ 
__END__

