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
    
    my $encoded_id = $self->param('id');
    
    $self->ch_api->transactions($self->stash('transaction_number'))->get->on(
        success => sub {
            my ($api, $tx) = @_;
            
            my $transaction = $tx->success->json;
            
            my $resume_link = $transaction->{links}->{resume};
            
            if (encode_base64url($resume_link) ne $encoded_id) {
                my $message = "The transaction resume link does not match the encoded id";
                error "%s", $message;
                $self->render_exception($message);
            }
            
            my $base_url = quotemeta($self->config->{base}->{url});
            
            if ($resume_link !~ /^$base_url.*/) {
                my $message = "The transaction resume link does not begin with the expected protocol or domain: " . $resume_link;
                error "%s", $message;
                $self->render_exception($message);
            }
            
            $self->redirect_to($resume_link);
        },
        failure => sub {
            my ($api, $tx) = @_;
            
            my ($error_message, $error_code) = ($tx->error->{message}, $tx->error->{code});
                my $message = 'Failed to fetch transaction ' . $self->stash('transaction_number') . ': ' . $error_code . ' ' . $error_message;
                error "%s", $message [API];
                $self->render_exception($message);
        },
        error => sub {
            my ($api, $error) = @_;
            
            my $message = 'Error when fetching transaction ' . $self->stash('transaction_number') . ': ' . $error;
            error "%s", $message [ROUTING];
            $self->render_exception($message);
        }
   )->execute;
}

# ------------------------------------------------------------------------------
1;
