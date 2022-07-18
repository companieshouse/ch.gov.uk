use strict;
use Test::More;
use CH::Test;

use Readonly;
use ChGovUk::Controllers::Company;
Readonly my $CLASS => 'ChGovUk::Controllers::Company';
my $company_ctrl = ChGovUk::Controllers::Company->new;

use_ok $CLASS;

    new_ok $CLASS;

    methods_ok $CLASS, qw(view authorise);

#-------------------------------------------------------------------------------

subtest "\$view_company_event is 'View non-ROE company' for a non-ROE company" => sub {
    plan tests => 1;
    $company_ctrl->stash(company => {
        company_number => "00006400",
        type           => "ltd",
    });
    $company_ctrl->view();
    is $company_ctrl->stash->{view_company_event}, "View non-ROE company", "\$view_company_event should be 'View non-ROE company'";
};

#-------------------------------------------------------------------------------

subtest "\$view_company_event is 'View ROE company' for a ROE company" => sub {
    plan tests => 1;
    $company_ctrl->stash(company => {
        company_number => "OE000002",
        type           => "registered-overseas-entity",
    });
    $company_ctrl->view();
    is $company_ctrl->stash->{view_company_event}, "View ROE company", "\$view_company_event should be 'View ROE company'";
};

#-------------------------------------------------------------------------------


done_testing();

