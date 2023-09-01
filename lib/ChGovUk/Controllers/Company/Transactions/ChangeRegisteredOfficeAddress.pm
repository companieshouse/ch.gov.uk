package ChGovUk::Controllers::Company::Transactions::ChangeRegisteredOfficeAddress;

use CH::Perl;
use Moose;
extends 'ChGovUk::Controllers::Company::Transactions::AbstractController';

use ChGovUk::Models::Address;

#-------------------------------------------------------------------------------

sub get {
    my ($self) = @_;

    debug "In forms-ad01#get" [GET];
    my $ecct = $self->config->{feature}->{ecct};

    my $country_list = ChGovUk::Models::Address->get_country_name_list( list_type => 'restricted' );
    $self->stash(country_list => $country_list);

    $self->ch_api->transactions($self->stash('transaction_number'))->registered_office_address->get->on(
        failure => sub {
            my ($api, $tx) = @_;
            my ($error_message, $error_code) = ($tx->error->{message}, $tx->error->{code} // 0);

            if ($error_code == 401) {
                my $return_to = $self->req->url->to_string;
                warn "Company (%s) unauthorised. Redirecting to company login, with return_to: %s", $self->stash('company_number'), $return_to [ROUTING];
                $self->redirect_to('/company/'.$self->stash('company_number').'/authorise?return_to='.$return_to);
                return 0;
            }
            else {
                my $message = 'Failed to fetch existing registered office address for company '.$self->stash('company_number').': '.$error_code.' '.$error_message;
                error "%s", $message [API];
                $self->render_exception($message);
            }
        },
        error => sub {
            my ($api, $error) = @_;
            my $message = 'Failed to fetch registered office address for company '.$self->stash('company_number').': '.$error;
            error "%s", $message [ROUTING];
            $self->render_exception($message);
        },
        success => sub {
            my ($api, $tx) = @_;
            my $addr = ChGovUk::Models::Address->new->from_api_hash($tx->success->json);
            $self->stash(old_address => $addr->as_string, po_box => $addr->po_box, care_of => $addr->care_of, disable_header_search => 1, etag => $addr->etag, po_box_enabled => !$ecct);
            $self->render(template => 'company/transactions/change_registered_office_address');
        }
    )->execute;

    $self->render_later;
};

#-------------------------------------------------------------------------------
1;
