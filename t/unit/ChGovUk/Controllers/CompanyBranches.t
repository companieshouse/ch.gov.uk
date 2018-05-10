use strict;
use Test::More;
use CH::Test;

use Readonly;
Readonly my $CLASS => 'ChGovUk::Controllers::Company::Branches';

use_ok $CLASS;

    new_ok $CLASS;

    methods_ok $CLASS, qw(view);

done_testing();

