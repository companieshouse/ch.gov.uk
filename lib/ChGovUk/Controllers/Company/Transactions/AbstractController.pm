package ChGovUk::Controllers::Company::Transactions::AbstractController;

use Moose;
extends 'MojoX::Moose::Controller';

use CH::Perl;
use Mojo::Util qw( camelize );
use Data::Dumper;

#-------------------------------------------------------------------------------

sub get {
    my ($self) = @_;

    $self->app->log->debug("In FormBase#get [GET]");

    # TODO need to get data from API

    # Call a hook on the controller after preparing model but before rendering
    my $class = camelize($self->stash('transaction')->metadata->{controller});
    $class = "ChGovUk::Controllers::".$class;
    if( $class->can('before_render') ){
        $class->before_render($self);
    }

    $self->render($self->stash('transaction')->metadata->{template});

    return;
}

#-------------------------------------------------------------------------------

sub post {
    my ($self) = @_;

    $self->app->log->debug("In FormBase#post [POST]");

    my $transaction = $self->stash('transaction');

    $transaction->model->populate( controller => $self );
    $self->pre_process_post($transaction->model) if $self->can('pre_process_post');

    if ($self->param('submit')) {
        $self->_submit_transaction;
    } elsif ($self->param('cancel')) {
        $self->redirect_to($self->url_for('company_profile'));
    } else {
        $self->get;
    }

    return;
}

#-------------------------------------------------------------------------------

sub _submit_transaction {
    my ($self) = @_;

    $self->render_later;

    $self->stash('transaction')->submit(
        on_success => sub {
            my $transaction_number = $self->stash('transaction_number');
            if ( $self->session('file_upload_keys')
                && exists $self->session('file_upload_keys')->{$transaction_number} ){
                my $index = $self->session('file_upload_keys')->{$transaction_number};
                $self->session('file_upload')->[$index - 1] = undef;
                delete $self->session('file_upload_keys')->{$transaction_number};

                $self->app->log->trace("File upload keys session variable looks like this after deletion:\n" . Dumper($self->session('file_upload_keys')) . " [FILE]");
            }

            $self->redirect_to($self->url_for('confirmation'));
        },
        on_failure => sub {
            return $self->get;
        },
    );
}

# ------------------------------------------------------------------------------

1;

=head1 NAME

ChGovUk::Controllers::Company::Transactions::AbstractController

=head1 SYNOPSIS

    package ChGovUk::Controllers::Company::Transactions::SomeForm;

    use Moose;
    extends 'ChGovUk::Controllers::Company::Transactions::AbstractController';


=head1 DESCRIPTION

Abstract base for forms.


=head1 METHODS

=head2 get

GET handler

Example

    $controller->get();


=head2 post

POST handler. If POST action is not a I<form submit> then also
calls L<get|/"get">, otherwise will call L<submit_form|/"submit_form">.

Example

    $controller->post();


=head2 submit_form

Submit and perform validation on model.

    @param   model    [object]  model object
    @returns 1=valid, 0=invalid

Example

    my $ret = $controller->submit_form($model);

=head2 model_preload

    @param   model    [object]  model object
    @returns $self

This method, if created in the parent controller, is run after the model is first created.
C<model_preload> can pre-process (e.g. pre-populate/verify) the model
when a given form is initially loaded.

Example (usage in parent controller)

    sub model_preload {
        my ($self, $model) = @_;

        $model->load($self->config, { shuttle_id => $self->stash('transaction')->{form_header}->get_dataID, } );
        $self->store_model($model);
        $model->validate();
        return $self;
    }

=head2 pre_process_post

    @param   model    [object]  model object
    @returns $self

This method, if created in the parent controller, is run during form submission.
C<pre_process_post> can process the model prior to L<submit_form|/submit_form>.

Example (usage in parent controller)

    sub pre_process_post {
        my ($self, $model) = @_;

        $model->home_address_linked( $self->param('home_address_change') eq 'L' ? 'Y' : 'N' );
        return $self;
    }

=cut
