use CH::Perl;
use CH::Test;
use Test::More;
use Readonly;

Readonly my $CLASS => 'ChGovUk::Controllers::Company::Pscs';

use_ok $CLASS;
new_ok $CLASS;
methods_ok $CLASS, qw(list);

done_testing;
