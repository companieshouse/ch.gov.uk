use strict;
use warnings;

use Test::More;

use ChGovUk::Controllers::Company::ViewAllSpy;

use_ok 'ChGovUk::Controllers::Company::ViewAllSpy';
my $view_all_ctrl = ChGovUk::Controllers::Company::ViewAllSpy->new;
isa_ok $view_all_ctrl, 'ChGovUk::Controllers::Company::ViewAllSpy';

subtest "Render view if company is active and company type is valid" => sub {
    plan tests => 5;
    $view_all_ctrl->stash(company => {
        type           => "ltd",
        company_status => "active",
        links          => {
            filing_history => '/company/T1234567/filing-history'
        }
    });
    $view_all_ctrl->expect(sub {
        my %args = @_;
        is $args{template}, 'company/view_all/view', "Expected template is rendered";
    });
    $view_all_ctrl->view();
    is $view_all_ctrl->stash->{show_snapshot}, 1;
    is $view_all_ctrl->stash->{show_certificate}, 1;
    is $view_all_ctrl->stash->{show_certified_document}, 1;
    is $view_all_ctrl->stash->{show_dissolved_certificate}, 0;
};

done_testing();
