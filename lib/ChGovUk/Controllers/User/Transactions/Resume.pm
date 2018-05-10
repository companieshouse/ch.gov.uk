package ChGovUk::Controllers::User::Transactions::Resume;

use Mojo::Base 'Mojolicious::Controller';

use CH::Perl;
use CH::Util::Pager;
use CH::Util::DateHelper;
use POSIX qw(strftime);
use Mojo::IOLoop::Delay;
use Digest::SHA qw(sha1);
use MIME::Base64 qw(encode_base64url);
use Data::Dumper;

#-------------------------------------------------------------------------------
sub resume {
    my ($self) = @_;

    my $encoded_id = $self->param('id');

    $self->ch_api->transactions($self->stash('transaction_number'))->get->on(
        success => sub {
            my ($api, $tx) = @_;
                my $transaction = $tx->success->json;

                my $resource_and_id_match = 0;

                for my $resource (  keys %{$transaction->{resources}}) {
                    if ( encode_base64url(sha1($resource)) eq $encoded_id){ 
                        $resource_and_id_match = 1;
                        $self->_build_resume_link($transaction, $transaction->{resources}->{$resource} );
                        last;
                    }
                }
                if ( $resource_and_id_match eq  0) {
                    error "None of the resource keys could be matched with provided encoded id";
                    $self->render_not_found;
                }
        },
        failure => sub {
            my ($api, $tx) = @_;
            my ($error_message, $error_code) = ($tx->error->{message}, $tx->error->{code});
                my $message = 'Failed to fetch transaction '.$self->stash('transaction_number').': '.$error_code.' '.$error_message;
                error "%s", $message [API];
                $self->render_exception($message);
        },
        error => sub {
            my ($api, $error) = @_;
                my $message = 'Failed to fetch transaction '.$self->stash('transaction_number').': '.$error;
                error "%s", $message [ROUTING];
                $self->render_exception($message);
        }
   )->execute;
   $self->render_later;
};

#-------------------------------------------------------------------------------

sub _build_resume_link {
    my ($self, $transaction, $resource )= @_;
    
    my $company_number = $transaction->{company_number};
    my $transaction_id = $transaction->{id};
    my $kind = $resource->{kind};
    my $abridged_accounts_id;
    my $resume_link;

    my $resource_delay = Mojo::IOLoop::Delay->new;
    my $resource_delay_end;
    
    if ( $kind eq "accounts") {
        $resource_delay_end = $resource_delay->begin(0);
        $self->_get_accounts_document($resource->{links}->{resource}, $resource_delay_end);
    }

    $resource_delay->on(
        finish => sub {
            my ($delay, $resource_link, $accounts_id) = @_;
            
            if ( $resource_link && $kind eq "accounts" ){
                if ( $resource_link =~/abridged\/(.*)$/ ) {
                    $abridged_accounts_id = $1;
                }
                $resume_link = "/company/" . $company_number . "/transaction/" . $transaction_id . "/submit-abridged-accounts/" . $accounts_id ."/" . $abridged_accounts_id . "/accounting-reference-date";
            }
        
            $self->redirect_to($resume_link);
        },
        error => sub {
            my ($delay, $err) = @_;
        
            my $message = "Error getting accounts links : %s" . $err;
            error "Error getting accounts links : %s". $err;
            $self->render_exception($message);
        }
    );

}


# ------------------------------------------------------------------------------

sub _get_accounts_document {
    my ($self, $resource_link, $callback) = @_;
    
    $self->ch_api->uri($resource_link)->get->on(
             success => sub {
                 my ($api, $tx) = @_;

                 my $accounts = $tx->success->json;

                 if ( defined $accounts->{links}->{abridged_accounts} ){
                     $callback->($accounts->{links}->{abridged_accounts}, $accounts->{id});
                 }
                 return $callback->();
             },
             failure => sub {
                 my ($api, $tx) = @_;

                 my $error_code = $tx->error->{code} // 0;
                 my $error_message = $tx->error->{message};

                 if (defined $error_code and $error_code == 404) {
                    error " Resource [%s] not found", $resource_link;
                    $self->render_not_found;
                 }
                 my $message = "Error getting accounts links : %s". $resource_link;
                 error "Error getting accounts links : %s", $resource_link [ RESUME LINK ];
                 $self->render_exception($message);
             },
             error => sub {
                 my ($api, $error) = @_;

                 my $message = "Error getting accounts links : %s". $resource_link;
                 error "Error getting accounts links : %s", $resource_link [ RESUME LINK ];
                 $self->render_exception($message);
             }
         )->execute;
}

# ------------------------------------------------------------------------------
1;
