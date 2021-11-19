use strict;
use warnings;

use Test::More;

use ChGovUk::Controllers::Company::ViewAllSpy;

use_ok 'ChGovUk::Controllers::Company::ViewAllSpy';
my $view_all_ctrl = ChGovUk::Controllers::Company::ViewAllSpy->new;
isa_ok $view_all_ctrl, 'ChGovUk::Controllers::Company::ViewAllSpy';

#-------------------------------------------------------------------------------

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
    is $view_all_ctrl->stash->{show_snapshot}, 1, "Snapshots should be orderable";
    is $view_all_ctrl->stash->{show_certificate}, 1, "Certificates should be orderable";
    is $view_all_ctrl->stash->{show_certified_document}, 1, "Certified documents should be orderable";
    is $view_all_ctrl->stash->{show_dissolved_certificate}, 0, "Dissolved certificates should not be orderable";
};

#-------------------------------------------------------------------------------

subtest "Render not found view if snapshots cannot be generated, company is neither active nor dissolved, has no associated filing history collection and company type is valid" => sub {
    plan tests => 5;
    $view_all_ctrl->stash(company => {
        type           => "uk-establishment",
        company_status => "closed",
        links          => {
            filing_history => '/company/BR123456/filing-history'
        }
    });
    $view_all_ctrl->expect(sub {
        my %args = @_;
        is $args{template}, 'not_found.production', "Expected template is rendered";
    });
    $view_all_ctrl->view();
    is $view_all_ctrl->stash->{show_snapshot}, 0, "Snapshots should not be orderable";
    is $view_all_ctrl->stash->{show_certificate}, 0, "Certificates should not be orderable";
    is $view_all_ctrl->stash->{show_certified_document}, 0, "Certified documents should not be orderable";
    is $view_all_ctrl->stash->{show_dissolved_certificate}, 0, "Dissolved certificates should not be orderable";
};

#-------------------------------------------------------------------------------

subtest "Hide snapshots link if not supported for company type" => sub {
    plan tests => 5;
    $view_all_ctrl->stash(company => {
        type           => "eeig",
        company_status => "active",
        links          => {
            filing_history => '/company/GS123456/filing-history'
        }
    });
    $view_all_ctrl->expect(sub {
        my %args = @_;
        is $args{template}, 'company/view_all/view', "Expected template is rendered";
    });
    $view_all_ctrl->view();
    is $view_all_ctrl->stash->{show_snapshot}, 0, "Snapshots should not be orderable";
    is $view_all_ctrl->stash->{show_certificate}, 0, "Certificates should not be orderable";
    is $view_all_ctrl->stash->{show_certified_document}, 1, "Certified documents should be orderable";
    is $view_all_ctrl->stash->{show_dissolved_certificate}, 0, "Dissolved certificates should not be orderable";
};

#-------------------------------------------------------------------------------

subtest "Hide certified document link if filing history link absent" => sub {
    plan tests => 5;
    $view_all_ctrl->stash(company => {
        type           => "ltd",
        company_status => "active",
        links          => {
            filing_history => ''
        }
    });
    $view_all_ctrl->expect(sub {
        my %args = @_;
        is $args{template}, 'company/view_all/view', "Expected template is rendered";
    });
    $view_all_ctrl->view();
    is $view_all_ctrl->stash->{show_snapshot}, 1, "Snapshots should be orderable";
    is $view_all_ctrl->stash->{show_certificate}, 1, "Certificates should be orderable";
    is $view_all_ctrl->stash->{show_certified_document}, 0, "Certified documents should not be orderable";
    is $view_all_ctrl->stash->{show_dissolved_certificate}, 0, "Dissolved certificates should not be orderable";
};

#-------------------------------------------------------------------------------

subtest "Show dissolved certified certificate link if company is dissolved" => sub {
    plan tests => 5;
    $view_all_ctrl->stash(company => {
        type           => "ltd",
        company_status => "dissolved",
        links          => {
            filing_history => '/company/12345678/filing-history'
        }
    });
    $view_all_ctrl->expect(sub {
        my %args = @_;
        is $args{template}, 'company/view_all/view', "Expected template is rendered";
    });
    $view_all_ctrl->view();
    is $view_all_ctrl->stash->{show_snapshot}, 1, "Snapshots should be orderable";
    is $view_all_ctrl->stash->{show_certificate}, 0, "Certificates should not be orderable";
    is $view_all_ctrl->stash->{show_certified_document}, 1, "Certified documents should be orderable";
    is $view_all_ctrl->stash->{show_dissolved_certificate}, 1, "Dissolved certificates should be orderable";
};

#-------------------------------------------------------------------------------

subtest "Hide dissolved certified certificate link if not orderable for company type" => sub {
    plan tests => 5;
    $view_all_ctrl->stash(company => {
        type           => "eeig",
        company_status => "dissolved",
        links          => {
            filing_history => '/company/GS123456/filing-history'
        }
    });
    $view_all_ctrl->expect(sub {
        my %args = @_;
        is $args{template}, 'company/view_all/view', "Expected template is rendered";
    });
    $view_all_ctrl->view();
    is $view_all_ctrl->stash->{show_snapshot}, 0, "Snapshots should not be orderable";
    is $view_all_ctrl->stash->{show_certificate}, 0, "Certificates should not be orderable";
    is $view_all_ctrl->stash->{show_certified_document}, 1, "Certified documents should be orderable";
    is $view_all_ctrl->stash->{show_dissolved_certificate}, 0, "Dissolved certificates should not be orderable";
};

#-------------------------------------------------------------------------------

subtest "Render view if company is in liquidation and company type is valid and feature enabled" => sub {
    plan tests => 5;
    $view_all_ctrl->stash(company => {
        type           => "ltd",
        company_status => "liquidation",
        links          => {
            filing_history => '/company/T1234567/filing-history'
        }
    });
    $view_all_ctrl->expect(sub {
        my %args = @_;
        is $args{template}, 'company/view_all/view', "Expected template is rendered";
    });
    $view_all_ctrl->config->{feature}{order_liquidation_certificate} = 1;
    $view_all_ctrl->view();
    is $view_all_ctrl->stash->{show_snapshot}, 1, "Snapshots should be orderable";
    is $view_all_ctrl->stash->{show_certificate}, 1, "Certificates should be orderable";
    is $view_all_ctrl->stash->{show_certified_document}, 1, "Certified documents should be orderable";
    is $view_all_ctrl->stash->{show_dissolved_certificate}, 0, "Dissolved certificates should not be orderable";
};

#-------------------------------------------------------------------------------

subtest "Certificate not orderable for liquidated companies if feature disabled" => sub {
    plan tests => 5;
    $view_all_ctrl->stash(company => {
        type           => "ltd",
        company_status => "liquidation",
        links          => {
            filing_history => '/company/T1234567/filing-history'
        }
    });
    $view_all_ctrl->expect(sub {
        my %args = @_;
        is $args{template}, 'company/view_all/view', "Expected template is rendered";
    });
    $view_all_ctrl->config->{feature}{order_liquidation_certificate} = 0;
    $view_all_ctrl->view();
    is $view_all_ctrl->stash->{show_snapshot}, 1, "Snapshots should be orderable";
    is $view_all_ctrl->stash->{show_certificate}, 0, "Certificates should not be orderable";
    is $view_all_ctrl->stash->{show_certified_document}, 1, "Certified documents should be orderable";
    is $view_all_ctrl->stash->{show_dissolved_certificate}, 0, "Dissolved certificates should not be orderable";
};

#-------------------------------------------------------------------------------

subtest "Certificate not orderable for liquidated limited partnership" => sub {
    plan tests => 5;
    $view_all_ctrl->stash(company => {
        type           => "limited-partnership",
        company_status => "liquidation",
        links          => {
            filing_history => '/company/T1234567/filing-history'
        }
    });
    $view_all_ctrl->expect(sub {
        my %args = @_;
        is $args{template}, 'company/view_all/view', "Expected template is rendered";
    });
    $view_all_ctrl->config->{feature}{order_liquidation_certificate} = 1;
    $view_all_ctrl->view();
    is $view_all_ctrl->stash->{show_snapshot}, 1, "Snapshots should be orderable";
    is $view_all_ctrl->stash->{show_certificate}, 0, "Certificates should not be orderable";
    is $view_all_ctrl->stash->{show_certified_document}, 1, "Certified documents should be orderable";
    is $view_all_ctrl->stash->{show_dissolved_certificate}, 0, "Dissolved certificates should not be orderable";
};

#-------------------------------------------------------------------------------

done_testing();
