package ChGovUk::Controllers::User::Transactions::Resume;

use Mojo::Base 'Mojolicious::Controller';

use CH::Perl;
use CH::Util::Pager;
use CH::Util::DateHelper;
use POSIX qw(strftime);
use Mojo::IOLoop::Delay;
use MIME::Base64 qw(encode_base64url);

#-------------------------------------------------------------------------------

sub resume {
    my ($self) = @_;
    
    $self->render_later;
    
    my $encoded_resume_link = $self->param('link');
    
    $self->ch_api->transactions($self->stash('transaction_number'))->get->on(
        success => sub {
            my ($api, $tx) = @_;
            
            my $transaction = $tx->success->json;
            
            my $resume_link = $transaction->{resume_journey_uri};
            
            if (encode_base64url($resume_link) ne $encoded_resume_link) {
                my $message = "The transaction resume link does not match the encoded link url";
                error "%s", $message;
                $self->reply->exception($message);
            }
            
            # TODO: When support is added for third party (i.e. external) resume links, a check will need
            # to be performed here to verify that the resume link matches a trusted domain for a given
            # software vendor. A mechanism will be needed for adding the vendor to the transaction resource
            # at creation time, and for registering one or more trusted domains that should be checked here.
            # All Companies House resume links should be relative (i.e. not include the protocol or domain).
            
            $self->redirect_to($resume_link);
        },
        failure => sub {
            my ($api, $tx) = @_;
            
            my ($error_message, $error_code) = ($tx->error->{message}, $tx->error->{code});
                my $message = 'Failed to fetch transaction ' . $self->stash('transaction_number') . ': ' . $error_code . ' ' . $error_message;
                error "%s", $message [API];
                $self->reply->exception($message);
        },
        error => sub {
            my ($api, $error) = @_;
            
            my $message = 'Error when fetching transaction ' . $self->stash('transaction_number') . ': ' . $error;
            error "%s", $message [ROUTING];
            $self->reply->exception($message);
        }
   )->execute;
}

# ------------------------------------------------------------------------------
1;
