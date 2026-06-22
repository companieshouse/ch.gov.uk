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
subtest "get_company_scope returns oversea-company URL for FC with 6 digits" => sub {
    plan tests => 1;
    my $scope = $company_ctrl->get_company_scope('FC123456');
    is $scope, 'https://api.companieshouse.gov.uk/oversea-company/FC123456',
        'FC with 6 digits should return oversea-company scope';
};

#-------------------------------------------------------------------------------

subtest "get_company_scope returns oversea-company URL for NF with 6 digits" => sub {
    plan tests => 1;
    my $scope = $company_ctrl->get_company_scope('NF654321');
    is $scope, 'https://api.companieshouse.gov.uk/oversea-company/NF654321',
        'NF with 6 digits should return oversea-company scope';
};

#-------------------------------------------------------------------------------

subtest "get_company_scope returns oversea-company URL for SF with 6 digits" => sub {
    plan tests => 1;
    my $scope = $company_ctrl->get_company_scope('SF999999');
    is $scope, 'https://api.companieshouse.gov.uk/oversea-company/SF999999',
        'SF with 6 digits should return oversea-company scope';
};

#-------------------------------------------------------------------------------

subtest "get_company_scope returns company URL for regular company numbers" => sub {
    plan tests => 3;
    
    my $scope1 = $company_ctrl->get_company_scope('99999999');
    is $scope1, 'https://api.companieshouse.gov.uk/company/99999999',
        'Standard 8-digit company number should return company scope';
    
    my $scope2 = $company_ctrl->get_company_scope('12345678');
    is $scope2, 'https://api.companieshouse.gov.uk/company/12345678',
        'Regular company number should return company scope';
    
    my $scope3 = $company_ctrl->get_company_scope('OE000002');
    is $scope3, 'https://api.companieshouse.gov.uk/company/OE000002',
        'Overseas entity number should return company scope';
};

#-------------------------------------------------------------------------------

done_testing();

