package ChGovUk::Controllers::User::Transactions::SubmittedData;

use Mojo::Base 'Mojolicious::Controller';
use CH::Perl;
use Moose;
use POSIX qw(strftime);


#-------------------------------------------------------------------------------

sub show_registered_office_address {
    my ($self) = @_;

    $self->render_later;
    $self->ch_api->transactions($self->stash('transaction_number'))->registered_office_address->get->on(
        failure => sub {
            my ($api, $tx) = @_;
            my ($error_message, $error_code) = ($tx->error->{message}, $tx->error->{code});
                my $message = 'Failed to fetch existing registered office address for transaction '.$self->stash('transaction_number').': '.$error_code.' '.$error_message;
                error "%s", $message [API];
                $self->reply->exception($message);
        },
        error => sub {
            my ($api, $error) = @_;

                my $message = 'Failed to fetch registered office address for transaction '.$self->stash('transaction_number').': '.$error;
                error "%s", $message [ROUTING];
                $self->reply->exception($message);
        },
        success => sub {
            my ($api, $tx) = @_;

                my $address = $tx->success->json;
                $self->get_transaction;
                $self->stash( address_data => $address);
        }
    )->execute;

};

#-------------------------------------------------------------------------------

sub get_transaction {
    my ($self) = @_;

    $self->render_later;
    $self->ch_api->transactions($self->stash('transaction_number'))->get->on(
        failure => sub {
            my ($api, $tx) = @_;
            my ($error_message, $error_code) = ($tx->error->{message}, $tx->error->{code});
                my $message = 'Failed to fetch transaction '.$self->stash('transaction_number').': '.$error_code.' '.$error_message;
                error "%s", $message [API];
                $self->reply->exception($message);
        },
        error => sub {
            my ($api, $error) = @_;
                my $message = 'Failed to fetch transaction '.$self->stash('transaction_number').': '.$error;
                error "%s", $message [ROUTING];
                $self->reply->exception($message);
        },
        success => sub {
            my ($api, $tx) = @_;
                my $transaction = $tx->success->json;

                $transaction->{closed_at_date} = CH::Util::DateHelper->isodate_as_string($transaction->{closed_at});
                $transaction->{closed_at_time} = CH::Util::DateHelper->isotime_as_string($transaction->{closed_at})->strftime('%r');

                $self->stash( transaction_data => $transaction);
                $self->render;
        }
    )->execute;
};
#-------------------------------------------------------------------------------
1;
