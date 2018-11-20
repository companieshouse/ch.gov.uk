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
use List::Util qw/first/;

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
                    if ( encode_base64url(sha1($resource)) eq $encoded_id) {
                        $resource_and_id_match = 1;
                        $self->_build_resume_link($transaction, $transaction->{resources}->{$resource});
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
}

#-------------------------------------------------------------------------------

sub _build_resume_link {
    my ($self, $transaction, $resource ) = @_;
    
    my $company_number = $transaction->{company_number};
    my $transaction_id = $transaction->{id};
    my $kind = $resource->{kind};
    my $resource_kind = $kind =~ s/#.*//r; # strip any hash delimited sub-resource suffix from the kind

    my $resource_delay = Mojo::IOLoop::Delay->new;
    my $resource_delay_end;
    
    my $supported_resource_kind = defined first { $resource_kind eq $_ } keys %{$self->_get_resource_mappings()};
    
    if ($supported_resource_kind) {
        $resource_delay_end = $resource_delay->begin(0);
        $self->_get_resource_document($resource->{links}->{resource}, $self->_get_resource_mappings()->{$resource_kind}, $resource_delay_end);
    } else {
        my $message = "Missing resource mapping for resource kind: " . $resource_kind;
        error "%s", $message;
        $self->render_exception($message);
    }
    
    $resource_delay->on(
        finish => sub {
            my ($delay, $resource_link, $accounts_id) = @_;
            
            if ($resource_link) {
                my $redirect = $self->_get_resource_mappings()->{$resource_kind}->{link_builder}->($company_number, $transaction_id, $resource_link);
                
                $self->redirect_to($redirect);
            } else {
                my $message = "No sub-resource link for: " . $self->_get_resource_mappings()->{$resource_kind}->{sub_resource};
                error "%s", $message [RESUME LINK];
                $self->render_exception($message);
            }
            
        },
        error => sub {
            my ($delay, $err) = @_;
        
            my $message = "Error retrieving links resource: " . $err;
            error "%s". $message [RESUME LINK];
            $self->render_exception($message);
        }
    );

}

# ------------------------------------------------------------------------------

sub _get_resource_document {
    my ($self, $resource_link, $resource_mapping, $callback) = @_;
    
    $self->ch_api->uri($resource_link)->get->on(
             success => sub {
                 my ($api, $tx) = @_;
                 
                 my $sub_resource = $resource_mapping->{sub_resource};
                 
                 my $resource_json = $tx->success->json;
                 
                 if (defined $resource_json->{links}->{$sub_resource}) {
                     $callback->($resource_json->{links}->{$sub_resource}, $resource_json->{id});
                 }
                 
                 return $callback->();
             },
             failure => sub {
                 my ($api, $tx) = @_;

                 my $error_code = $tx->error->{code} // 0;
                 my $error_message = $tx->error->{message};

                 if (defined $error_code and $error_code == 404) {
                    error "Resource [%s] not found", $resource_link;
                    $self->render_not_found;
                 }
                 
                 my $message = "Failure retrieving links resource: " . $resource_link;
                 error "%s", $message [RESUME LINK];
                 $self->render_exception($message);
             },
             error => sub {
                 my ($api, $error) = @_;

                 my $message = "Error retrieving links resource: " . $resource_link;
                 error "%s", $message [RESUME LINK];
                 $self->render_exception($message);
             }
         )->execute;
}

# ------------------------------------------------------------------------------

sub _get_resource_mappings {
    
    my $mappings = {
        'accounts' => {
            sub_resource => 'abridged_accounts',
            link_builder => sub {
                my ($company_number, $transaction_id, $resource_link) = @_;
                
                my @params = $resource_link =~ /\/transactions\/.*\/accounts\/(.*)\/abridged\/(.*)/;
            
                return '/company/' . $company_number . '/transaction/' . $transaction_id . '/submit-abridged-accounts/' . $params[0] . '/' . $params[1] . '/accounting-reference-date';
            },
        },
        'company-accounts' => {
            sub_resource => 'small_full_accounts',
            link_builder => sub {
                my ($company_number, $transaction_id, $resource_link) = @_;
                
                my @params = $resource_link =~ /\/transactions\/.*\/company-accounts\/(.*)\//;
                
                return '/company/' . $company_number . '/transaction/' . $transaction_id . '/company-accounts/' . $params[0] . '/small-full/balance-sheet';
            },
        }
    };
    
    return $mappings;
}

# ------------------------------------------------------------------------------
1;
