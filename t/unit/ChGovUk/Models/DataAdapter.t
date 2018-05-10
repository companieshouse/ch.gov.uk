use strict;
use Test::More;
use Test::Exception;
use CH::Test;

use Readonly;
Readonly my $CLASS => 'ChGovUk::Models::DataAdapter';

use Mojolicious::Controller;

use_ok $CLASS;

    my $inst = new_ok $CLASS;

    restore_methods;

done_testing();

# =============================================================================

