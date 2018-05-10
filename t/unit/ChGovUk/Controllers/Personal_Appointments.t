use CH::Perl;
use CH::Test;
use Test::More;
use Readonly;

Readonly my $CLASS => 'ChGovUk::Controllers::PersonalAppointments';

use_ok $CLASS;
new_ok $CLASS;
methods_ok $CLASS, qw(get);

done_testing;
