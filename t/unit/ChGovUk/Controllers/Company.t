use strict;
use Test::More;
use CH::Test;

use Readonly;
Readonly my $CLASS => 'ChGovUk::Controllers::Company';

use_ok $CLASS;

    new_ok $CLASS;

    methods_ok $CLASS, qw(view authorise);

done_testing();

