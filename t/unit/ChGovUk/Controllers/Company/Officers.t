use Locale::Simple qw(l_dir ltd l_lang);
use File::Spec;

l_dir( File::Spec->rel2abs('i18n') );
ltd('chgovuk');
l_lang('en');

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

subtest "build_company_appointments returns no officers message when officer count is zero" => sub {
    plan tests => 1;
    my $result = ChGovUk::Controllers::Company::Officers::build_company_appointments(
        { active_count => 0, inactive_count => 0, resigned_count => 0 }, 0, 0, 0, 0);
    is $result, "There are no officer details available for this company.", "should return no officers message when officer count is zero";
};

#-------------------------------------------------------------------------------

subtest "build_company_appointments returns officer and resignation counts (plural)" => sub {
    plan tests => 1;
    my $result = ChGovUk::Controllers::Company::Officers::build_company_appointments(
        { active_count => 3, inactive_count => 0, resigned_count => 2 }, 0, 0, 0, 0);
    is $result, " 5 officers / 2 resignations", "should return pluralised officer and resignation counts";
};

#-------------------------------------------------------------------------------

subtest "build_company_appointments returns singular officer and resignation labels when counts are 1" => sub {
    plan tests => 1;
    my $result = ChGovUk::Controllers::Company::Officers::build_company_appointments(
        { active_count => 1, inactive_count => 0, resigned_count => 1 }, 0, 0, 0, 0);
    is $result, " 2 officers / 1 resignation", "should return singular resignation label when resigned count is 1";
};

#-------------------------------------------------------------------------------

subtest "build_company_appointments uses 'cessation' label for overseas entities" => sub {
    plan tests => 1;
    my $result = ChGovUk::Controllers::Company::Officers::build_company_appointments(
        { active_count => 5, inactive_count => 0, resigned_count => 1 }, 0, 1, 0, 0);
    is $result, " 6 officers / 1 cessation", "should return singular cessation label for overseas entity";
};

#-------------------------------------------------------------------------------

subtest "build_company_appointments uses 'cessations' label for overseas entities with multiple cessations" => sub {
    plan tests => 1;
    my $result = ChGovUk::Controllers::Company::Officers::build_company_appointments(
        { active_count => 4, inactive_count => 0, resigned_count => 3 }, 0, 1, 0, 0);
    is $result, " 7 officers / 3 cessations", "should return plural cessations label for overseas entity";
};

#-------------------------------------------------------------------------------

subtest "build_company_appointments uses 'partners' label for Limited Partnerships with feature flag enabled" => sub {
    plan tests => 1;
    my $result = ChGovUk::Controllers::Company::Officers::build_company_appointments(
        { active_count => 3, inactive_count => 0, resigned_count => 2 }, 0, 0, 1, 1);
    is $result, " 5 partners / 2 resignations", "should return partners label for LPs when feature flag is enabled";
};

#-------------------------------------------------------------------------------

subtest "build_company_appointments uses 'officers' label for Limited Partnerships when feature flag is disabled" => sub {
    plan tests => 1;
    my $result = ChGovUk::Controllers::Company::Officers::build_company_appointments(
        { active_count => 3, inactive_count => 0, resigned_count => 2 }, 0, 0, 1, 0);
    is $result, " 5 officers / 2 resignations", "should return officers label for LPs when feature flag is disabled";
};

#-------------------------------------------------------------------------------

subtest "build_company_appointments returns no-current-officers message when active filter is set and active count is zero" => sub {
    plan tests => 1;
    my $result = ChGovUk::Controllers::Company::Officers::build_company_appointments(
        { active_count => 0, inactive_count => 0, resigned_count => 5 }, 1, 0, 0, 0);
    is $result, "There are no current officers available for this company.", "should return no-current-officers message when active filter set and no active officers";
};

#-------------------------------------------------------------------------------

subtest "build_company_appointments returns current officer count when active filter is set" => sub {
    plan tests => 1;
    my $result = ChGovUk::Controllers::Company::Officers::build_company_appointments(
        { active_count => 3, inactive_count => 0, resigned_count => 2 }, 1, 0, 0, 0);
    is $result, " 3 current officers ", "should return active officer count with current officers label when active filter is set";
};

#-------------------------------------------------------------------------------

subtest "build_company_appointments returns current partners count for LPs with feature flag when active filter is set" => sub {
    plan tests => 1;
    my $result = ChGovUk::Controllers::Company::Officers::build_company_appointments(
        { active_count => 2, inactive_count => 0, resigned_count => 0 }, 1, 0, 1, 1);
    is $result, " 2 current partners ", "should return active partner count with current partners label for LPs when active filter is set";
};

done_testing();
