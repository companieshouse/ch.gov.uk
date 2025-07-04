package ChGovUk::Controllers::Company::Transactions;

use Mojo::Base 'Mojolicious::Controller';

use CH::Perl;
use Digest::SHA1 qw/ sha1_hex /;
use CH::Util::CVConstants;
use CH::Util::CompanyPrefixes;
use ChGovUk::Transaction;

use MIME::Base64 qw(encode_base64url decode_base64url);
use Time::HiRes qw(tv_interval gettimeofday);
use Scalar::Util qw(refaddr);

#-------------------------------------------------------------------------------

# TODO rename? doesn't always create
sub create {
    my ($self) = @_;

    $self->render_later();

    my $transaction = ChGovUk::Transaction->new( controller => $self );

    # Display pre-screen if required
    if( $transaction->metadata->{prescreen} && !$self->param('start')) {
        my $show = 1;
        if(exists $transaction->metadata->{prescreen}->{mode} && $transaction->metadata->{prescreen}->{mode} eq 'once-per-session') {
            $show = 0 if $self->session('prescreen') && $self->session('prescreen')->{$transaction->endpoint} == 1;
            $self->session('prescreen' => {}) if !$self->session('prescreen');
            $self->session('prescreen')->{$transaction->endpoint} = 1;
            trace "Prescreen for node %s is once-per-session, show = %s", $transaction->endpoint, $show [ROUTING];
        }
        if($show) {
            $self->render(template => $transaction->metadata->{prescreen}->{template});
            return;
        }
    }

    $transaction->create( callback => sub { $self->redirect_to( $transaction->get_start_url ) } );

    return;
}

#-------------------------------------------------------------------------------

# Transaction confirmation handler - called after form header is set to queued/awaiting payment
sub confirmation {
    my ($self) = @_;

    # TODO check formheader status

    $self->render_later;
    $self->get_transaction;

    return;
}

sub get_transaction {
    my ($self) = @_;

    my $start = [Time::HiRes::gettimeofday()];
    debug "TIMING transactions (transactions) '" . refaddr(\$start) . "'";
    $self->ch_api->transactions($self->stash('transaction_number'))->get->on(
        failure => sub {
            my ($api, $tx) = @_;
            debug "TIMING transactions (transactions) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
            my ($error_message, $error_code) = ($tx->error->{message}, $tx->error->{code});
                my $message = 'Failed to fetch transaction '.$self->stash('transaction_number').': '.$error_code.' '.$error_message;
                error "%s", $message [API];
                $self->render_exception($message);
        },
        error => sub {
            my ($api, $error) = @_;
            debug "TIMING transactions (transactions) error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                my $message = 'Failed to fetch transaction '.$self->stash('transaction_number').': '.$error;
                error "%s", $message [ROUTING];
                $self->render_exception($message);
        },
        success => sub {
            my ($api, $tx) = @_;
            debug "TIMING transactions (transactions) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
                my $transaction = $tx->success->json;

                $self->stash(transaction => $transaction);
                $self->render;
        }
    )->execute;
};

#-------------------------------------------------------------------------------

1;
