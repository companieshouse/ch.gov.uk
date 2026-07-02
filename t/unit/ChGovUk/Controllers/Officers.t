use CH::Perl;
use CH::Test;
use Test::More;
use Readonly;

use ChGovUk::Controllers::Company::Officers;

my $officers_controller = ChGovUk::Controllers::Company::Officers->new;

#-------------------------------------------------------------------------------

subtest "\$view_officers_event is 'View officers' for a non-Limited Partnership company" => sub {
    plan tests => 1;
    $officers_controller->stash(company => {
        company_number => "00006400",
        type           => "ltd",
    });
    $officers_controller->stash_view_officers_event();
    is $officers_controller->stash->{view_officers_event}, "View officers", "\$view_officers_event should be 'View officers'";
};

#-------------------------------------------------------------------------------

subtest "\$view_officers_event is 'View Limited Partnership partners' for a Limited Partnership company" => sub {
    plan tests => 1;
    $officers_controller->stash(company => {
        company_number => "LP123456",
        type           => "limited-partnership",
    });
    $officers_controller->stash_view_officers_event();
    is $officers_controller->stash->{view_officers_event}, "View Limited Partnership partners", "\$view_officers_event should be 'View Limited Partnership partners'";
};

#-------------------------------------------------------------------------------

done_testing();
