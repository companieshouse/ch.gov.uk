package ChGovUk::Controllers::CustomerFeedback;

use CH::Perl;
use Mojo::Util qw(trim);
use Mojo::UserAgent;
use Mojo::Base 'Mojolicious::Controller';

#-------------------------------------------------------------------------------
# record_feedback - save the feedback and forward via email to customer support
sub record_feedback {

    my ($self) = @_;    

    $self->render_later();

    # set up the feedback for recording
    my $feedback = {
        kind                => 'feedback',
        customer_name       => $self->_sanitize_param('customer_name'),
        customer_email      => $self->_sanitize_param('customer_email'),
        customer_feedback   => $self->_sanitize_param('customer_feedback'),
        source_url          => $self->_sanitize_param('source_url'),
    };

    # check the feedback looks ok?
    return $self->_render_json_error('No feedback entered. Please enter some feedback.', 1)
        unless $feedback->{customer_feedback};

    # limit feedback size to 300 characters or less
    return $self->_render_json_error('Too much feedback entered. Please limit your feedback to 300 characters or less.', 1)
        if length($feedback->{customer_feedback}) > 300;    

    return $self->_render_json_error('Invalid email address. Please enter a valid email address.', 1)
        if $feedback->{customer_email} and $feedback->{customer_email} !~ /\@/;

    # set default values if none provided
    if (not $feedback->{customer_email}) {
        $feedback->{customer_email} = '(not provided)';
    }
    if (not $feedback->{customer_name}) {
        $feedback->{customer_name} = '(not provided)';
    }
    
    my $currentUrl = $feedback->{source_url};
    my ( $previousUrl ) = $currentUrl=~ /(\=.*)\s*$/;

    debug 'Writing customer FEEDBACK to ['.$self->ch_api->admin->customer_feedback->path.']';

    $self->ch_api->admin->customer_feedback->create({
        kind                => $feedback->{kind},
        customer_name       => $feedback->{customer_name},
        customer_email      => $feedback->{customer_email},
        customer_feedback   => $feedback->{customer_feedback},
        source_url          => $previousUrl,
    })->on(
        success => sub {
            my ( $api, $tx ) = @_;
            return $self->render(json => { message => 'Feedback saved OK' });
        },
        error => sub {
            my ($api, $error) = @_;
            return $self->_render_json_error('Invalid API response: ' . $error, 0);
        },
        failure => sub {
            my ($api, $error) = @_;
            return $self->_render_json_error('Failed to create customer feedback: ' . $error, 0);
        }
    )->execute;
}

#-------------------------------------------------------------------------------

sub _log_error {

    my ($self, $error_message, $data_error) = @_;

    # don't log anything if this is a user data entry error
    return if $data_error;

    # there is a problem on our side - log it!
    $self->app->log->error('Error while saving customer feedback: ' . $error_message);

}

#-------------------------------------------------------------------------------

sub _render_json_error {

    my ($self, $error_message, $data_error) = @_;    

    $self->_log_error($error_message, $data_error);
    
    my $error_record = {
        message     => $error_message
    };
    
    return $self->render_exception(json => $error_record);        
}

#-------------------------------------------------------------------------------

sub _sanitize_param {

    my ($self, $param) = @_;    

    return '' unless my $value = $self->req->param($param);
    return trim($value);
    
}

1;
