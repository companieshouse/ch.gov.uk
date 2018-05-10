package ChGovUk::Plugins::FormHelpers;

use CH::Perl;
use Mojo::Base 'Mojolicious::Plugin';
use Try::Tiny;
use Text::Xslate qw/ mark_raw /;
use Mojo::Util qw( decamelize );
use CH::Util::CountryCodes;

has 'app';
has 'controller';
has 'model';
has 'labels'         => sub { {} };
has 'errors'         => sub { [] };
has 'blocks'         => sub { [] };

# ========================================================| MOJO INTERFACE |====

sub register {
    my ($self, $app) = @_;

    $self->app($app);
    $app->helper( form => sub {
        my ($controller, %args) = @_;
        # Return a new instance of this plugin which encapsulates
        # the controller and model
        return $self->new( app        => $app,
                           controller => $controller,
                           model      => $args{model},
                         );
    });

    return;
}

# -----------------------------------------------------------------------------

sub errors_count {
    my ($self) = @_;

    my $count = scalar @{ $self->errors };
    trace "There are %s errors", $count [VALIDATION];
    return $count;
}

# -----------------------------------------------------------------------------

sub _render_template {
    my ($self, $args) = @_;

    my $xs = $MojoX::Renderer::Xslate::PLUGIN->xslate;
    my $html = $xs->render($args->{template} . '.html.tx', $args);

    return mark_raw($html);
}

# -----------------------------------------------------------------------------

sub hidden_field {
    my ($self, %args) = @_;

    my $field = $args{name};
    my $model = $self->model;

    $self->labels->{$field} = $args{label} // $field;

    my @errors = $self->_get_errors_for_field( $model, $field );

    return $self->_render_template({
        template   => 'includes/forms/hidden_field',
        id         => $self->_field_name_to_id($field),
        errors     => \@errors,
        has_errors => scalar @errors,
        %args,
    });
}

# -----------------------------------------------------------------------------

sub tabs {
    my ($self, %args) = @_;

    my $field = $args{name};
    my $model = $self->model;

    $self->labels->{$field} = $args{label} // $field;

    my $value;
    if ($model && $model->values && exists $model->values->{$field}) {
        $value = $model->values->{$field};
    } elsif ($self->controller->param($field) ) {
        $value = $self->controller->param($field);
    }

    if(my $new_value = $self->controller->req->url->query->param($field)) {
        $value = $new_value;
    }

    my $active_tab;
    for my $tab (@{$args{tabs}}) {
        $active_tab = $tab and last if $value && $tab->{value} && $tab->{value} eq $value;
    }
    $active_tab = $args{tabs}->[0] if !$active_tab && scalar @{$args{tabs}};
    $args{active_tab} = $active_tab;

    return $self->_render_template({
        template => 'includes/forms/tabs',
        include => $active_tab ? $active_tab->{include} : '',
        form => $self,
        value => $active_tab->{value},
        %args,
        %{$self->controller->stash}, # TODO seems wrong, but needed for registered office address data etc.
    });
}

# -----------------------------------------------------------------------------

sub date_field {
    my ($self, %args) = @_;

    my $field = $args{name};
    my $model = $self->model;

    my $value;
    my @errors;

    $self->labels->{$field} = $args{label};

    @errors = $self->_get_errors_for_field( $model, $field );

    if ($model && $model->values && exists $model->values->{$field}) {
        $value = $model->values->{$field};
    } elsif ($self->controller->param($field) ) {
        $value = $self->controller->param($field);
    }

    my $id = $self->_field_name_to_id($field);

    if($args{maximum_age}) {
        $args{year_start} = ((localtime)[5] + 1900) - $args{maximum_age};
    }
    if($args{minimum_age}) {
        $args{year_end} = ((localtime)[5] + 1900) - $args{minimum_age};
    }

    my $year_start = $args{year_start} // 1900;
    my $year_end = $args{year_end} // ((localtime)[5] + 1900);
    my @years = map { { $_ => $_ } } reverse ( $year_start .. $year_end );

    my $has_postback = $self->controller->stash('transaction')->has_postback;

    return $self->_render_template({
            template    => 'includes/forms/date_field',
            errors      => \@errors,
            has_errors  => scalar @errors,
            has_postback => $has_postback,
            value       => $value,
            id          => $id,
            form        => $self,
            years       => \@years,
            %args
    });
}

# -----------------------------------------------------------------------------

sub country_for_code {
    my ($self, $country_code) = @_;
    my $country = CH::Util::CountryCodes->new->country_for_code( $country_code );
    debug "Country for code [%s] is [%s]", $country_code, $country [VALIDATION];
    return $country;
}

# -----------------------------------------------------------------------------

sub text_field {
    my ($self, %args) = @_;

    my $field = $args{name};
    my $model = $self->model;

    my $value;
    my @errors;

    $self->labels->{$field} = $args{label};

    @errors = $self->_get_errors_for_field( $model, $field );

    if ( $args{as} && $args{as} eq "postcode"  ) {
        push @errors, $self->_get_errors_for_postcode_lookup( $field );
    }

    if ($model && $model->values && exists $model->values->{$field}) {
        $value = $model->values->{$field} || $args{default};
    } elsif ($self->controller->param($field) ) {
        $value = $self->controller->param($field);
    }

    my $id = $self->_field_name_to_id($field);

    return $self->_render_template({
            template    => 'includes/forms/' . ($args{as}?$args{as} : 'text') . '_field',
            errors      => \@errors,
            has_errors  => scalar @errors,
            value       => $value,
            id          => $id,
            maxlength   => ($model && $model->rules->{$field}->{maxlength})
                           ? $model->rules->{$field}->{maxlength}
                           : undef,
            %args
    });
}

# -----------------------------------------------------------------------------

sub textarea {
    my ($self, %args) = @_;

    my $field = $args{name};
    my $model = $self->model;

    my $value;
    my @errors;

    $self->labels->{$field} = $args{label};

    @errors = $self->_get_errors_for_field( $model, $field );

    if ($model && $model->values && exists $model->values->{$field}) {
        $value = $model->values->{$field};
    } elsif ($self->controller->param($field) ) {
        $value = $self->controller->param($field);
    }

    my $id = $self->_field_name_to_id($field);

    my $has_postback = $self->controller->stash('transaction')->has_postback;

    return $self->_render_template({
            template   => 'includes/forms/textarea',
            errors     => \@errors,
            has_errors => scalar @errors,
            has_postback => $has_postback,
            value      => $value,
            id         => $id,
            maxlength  => $model ? $model->rules->{$field}->{maxlength} ? $model->rules->{$field}->{maxlength} : undef : undef,
            %args
    });
}

# -----------------------------------------------------------------------------

sub submit_button {
    my ($self, %args) = @_;

    $self->labels->{$args{name}} = $args{label};

    return $self->_render_template({
        template => 'includes/forms/submit_button',
        id       => $self->_field_name_to_id($args{name}),
        %args
    });
}

# -----------------------------------------------------------------------------

sub radio {
    my ($self, %args) = @_;

    my $field = $args{name};
    my $model = $self->model;

    $self->labels->{$field} = $args{label};

    my @errors = $self->_get_errors_for_field( $model, $field, 'radio', );

    my $value;
    if ($model && $model->values && exists $model->values->{$field}) {
        $value = $model->values->{$field};
    } elsif ($self->controller->param($field) ) {
        $value = $self->controller->param($field);
    }

    for my $opt (@{ $args{options} }) {
        my $id = $self->_field_name_to_id($field) . '-' . $opt->{value};
        $opt->{id} = $id;
    }

    return $self->_render_template({
       template     => 'includes/forms/radio',
       errors       => \@errors,
       has_errors   => scalar @errors,
       value        => $value,
       model        => $self->model,
       %args
    });
}

# -----------------------------------------------------------------------------

sub checkbox {
    my ($self, %args) = @_;

    my $field = $args{name};
    my $model = $self->model;

    $self->labels->{$field} = $args{label};

    my @errors = $self->_get_errors_for_field( $model, $field );

    my $value;
    if ($model && $model->values && exists $model->values->{$field}) {
        $value = $model->values->{$field};
    }
    elsif ($self->controller->param($field) ) {
        $value = $self->controller->param($field);
    }

    my $id = $self->_field_name_to_id($field);

    return $self->_render_template({
            template => 'includes/forms/checkbox',
            errors   => \@errors,
            has_errors => scalar @errors,
            value    => $value,
            id       => $id,
            %args
    });
}

# -----------------------------------------------------------------------------

sub select_field {
    my ($self, %args) = @_;

    my $field = $args{name};
    my $model = $self->model;

    my $value;
    my @errors;

    $self->labels->{$field} = $args{label};

    @errors = $self->_get_errors_for_field( $model, $field );

    if ($model && $model->values && exists $model->values->{$field}) {
        $value = $model->values->{$field};
    } elsif ($self->controller->param($field) ) {
        $value = $self->controller->param($field);
    }

    my $id = $self->_field_name_to_id($field);

    return $self->_render_template({
            template => 'includes/forms/select_field',
            model    => $self->model,
            has_errors => scalar @errors,
            errors   => \@errors,
            value    => $value,
            id       => $id,
            %args
    });
}

# -----------------------------------------------------------------------------

sub file_field {
    my ($self, %args) = @_;
    my $field = $args{name};
    my $model = $self->model;

    my $value;
    my @errors;

    $self->labels->{$field} = $args{label};

    @errors = $self->_get_errors_for_field( $model, $field );

    push @errors, $self->_get_errors_for_file_upload( $model, $field );

    if ($model && $model->values && exists $model->values->{$field}) {
        $value = $model->values->{$field};
    } elsif ($self->controller->param($field) ) {
        $value = $self->controller->param($field);
    }

    my $filesize;
    my $units;

    #If value is a number then the upload button was pressed, so we
    #need to turn it into the file_upload hash.
    if ( !ref($value) && $value ){
        #Value is an index initially and is then turned into a hash ref.
        $value = $self->controller->session->{file_upload}->[$value - 1];
    }
    if ( ref $value eq "HASH" ){
        $filesize = $value->{filesize};
        $units = 'bytes';
        if ($filesize < 1024){
            # default
        }
        elsif( $filesize < 1048576 ){
            $filesize = sprintf("%.2f", $filesize / 1024 );
            $units = "KB";
        }
        elsif( $filesize < 1073741824 ){
            $filesize = sprintf("%.2f", $filesize / (1024 * 1024));
            $units = "MB";
        }
        debug "File size: %s %s", $filesize, $units [FILE];
    }
    my $id = $self->_field_name_to_id($field);

    return $self->_render_template(
        {
            template   => 'includes/forms/file_field',
            model      => $self->model,
            has_errors => scalar @errors,
            errors     => \@errors,
            value      => $value,
            filesize   => $filesize,
            units      => $units,
            %args
        }
    );
}

# -----------------------------------------------------------------------------

sub start {
    my ($self, %args) = @_;

    push $self->blocks, $self->_render_template({ template => 'includes/forms/end' });;
    return $self->_render_template({ template => 'includes/forms/start', %args, action => $self->controller->url_for });
}

# -----------------------------------------------------------------------------

sub end {
    my ($self, %args) = @_;
    return pop $self->blocks;
}

# -----------------------------------------------------------------------------

sub _get_errors_for_field {
    my ($self, $model, $field, $field_type) = @_;
    my @errors;

    my $rules_failed = $model->errors_for($field) if $model;

    if ( $rules_failed ) {
        my $error_config_for_field = $self->_get_error_config_for_field( $model, $field );
        my $label = $self->labels->{$field};
        my $value = $model->values->{$field};

        foreach my $rule ( keys %$rules_failed ){
            my $error;
            if (   defined $error_config_for_field
                && exists $error_config_for_field->{$rule} ) {
                $error = $error_config_for_field->{$rule};
            }
            else {
                my $error_config = $self->app->config->{errors}->{default};
                if (    $field_type
                     && exists $error_config->{$field_type}
                     && exists $error_config->{$field_type}->{$rule} ) {
                    $error = $error_config->{$field_type}->{$rule};
                }
                elsif ( exists $error_config->{$rule} && $error_config->{$rule} ) {
                    $error = $error_config->{$rule};
                }
                else {
                    error "Missing error message text for rule [%s]", $rule [VALIDATION];
                    $error = "Field has an error - no description available [$rule]";
                }
            }

            my %error_args;
            $error_args{field} = $self->_label_for_error($label);
            $error_args{value} = $value;
            if (ref $rules_failed->{$rule} eq ref {}) {
                %error_args = ( %error_args , %{$rules_failed->{$rule}} );
            }

            $error = Locale::Simple::l($error, { %error_args } );
            my $error_id = $self->_field_name_to_id($field) . '-' . $rule . '-error';
            push @errors, { text => $error, id => $error_id };

            # Add error to global error array
            my %error_hash;
            $error_hash{name} = $field;
            $error_hash{text} = $error;

            # Does the controller have a corresponding field?
            if ( defined $self->labels->{$field} ) {
                $error_hash{id}   = $error_id;
                push $self->errors, \%error_hash;
            }
        }
    }

    return @errors;
}

# -----------------------------------------------------------------------------

sub _get_errors_for_postcode_lookup {
    my ($self, $field) = @_;

    my @errors;

    my $rule;
    if (   $self->controller->stash('postcode_error')
        && $self->controller->stash('postcode_error') eq $field ) {
        $rule = 'postcode_error';
    }
    elsif ( $self->controller->stash('postcode_lookup_nomatch')
        && $self->controller->stash('postcode_lookup_nomatch') eq $field ) {
        $rule = 'postcode_lookup_nomatch';
    }
    elsif ( $self->controller->stash('postcode_lookup_failure')
        && $self->controller->stash('postcode_lookup_failure') eq $field ) {
        $rule = 'postcode_lookup_failure';
    }

    if ( $rule ) {

        my $error_config_for_field = $self->_get_error_config_for_field( undef, $field );
        my $label = $self->labels->{$field};
        my $value = $self->app->param($field);

            my $error;
            if (   defined $error_config_for_field
                && exists $error_config_for_field->{$rule} ) {
                $error = $error_config_for_field->{$rule};
            } else {
                $error = $self->app->config->{errors}->{default}->{$rule};
            }

            $error = Locale::Simple::l($error, { field => $label, value => $value } );
            my $error_id = $self->_field_name_to_id($field) . '-' . $rule . '-error';
            push @errors, { text => $error, id => $error_id };

            # Add error to global error array
            my %error_hash;
            $error_hash{name} = $field;
            $error_hash{text} = $error;
            $error_hash{id}   = $error_id;
            push $self->errors, \%error_hash;
    }

    return @errors;
}

# -----------------------------------------------------------------------------

sub _get_errors_for_file_upload {
    my ($self, $model, $field) = @_;

    my @errors;

    if (  $self->controller->stash('file_upload_required')
       && $self->controller->stash('file_upload_required') eq $field ) {

        my $error_config_for_field = $self->_get_error_config_for_field( $model, $field );
        my $label = $self->labels->{$field};
        my $value = $self->controller->param($field);

            my $error;
            my $rule = 'required';
            if (   defined $error_config_for_field
                && exists $error_config_for_field->{$rule} ) {
                $error = $error_config_for_field->{$rule};
            } else {
                $error = $self->app->config->{errors}->{default}->{$rule};
            }

            $error = Locale::Simple::l($error, { field => $label, value => $value } );
            my $error_id = $self->_field_name_to_id($field) . '-' . $rule . '-error';
            push @errors, { text => $error, id => $error_id };

            # Add error to global error array
            my %error_hash;
            $error_hash{name} = $field;
            $error_hash{text} = $error;
            $error_hash{id}   = $error_id;
            push $self->errors, \%error_hash;
    }

    return @errors;
}

# -----------------------------------------------------------------------------

sub _get_error_config_for_field {
    my ($self, $model, $field) = @_;

    my $model_name = ref($model);

    my @model_name_parts = map { decamelize($_) } split (/::/, $model_name);

    my @error_nodes = (@model_name_parts, $self->_field_name_parts($field));

    debug "Looking for errors: %s", join ('.', @error_nodes) [VALIDATION];

    my $error_config = $self->app->config->{errors};

    foreach my $node (@error_nodes) {
        $error_config = $error_config->{$node} // undef;
        last if !defined $error_config;
    }

    return $error_config;
}

# -----------------------------------------------------------------------------

sub _label_for_error {
    my ($self, $label) = @_;

    # We naively remove the last set of brackets from the label
    $label = $1 if $label =~ /(^.*) \(.*\)$/;

    return $label;
}

# -----------------------------------------------------------------------------

sub _field_name_parts {
    my ($self, $field) = @_;

    my @field_name_parts = ();
    my $child;
    do {
        # field = name[child1][child2]
        # becomes: name.child1.child2
        ($field, $child) = $field =~ /^(\w+)(\[.*\])?$/;

        push @field_name_parts, decamelize $field if $field;

        # now convert child [c1][c2] to c1[c2]
        $child =~ s/^\[(\w+)\]/$1/ if $child;
        $field = $child;
    } while defined $child;

    return @field_name_parts;
}

# -----------------------------------------------------------------------------

sub _field_name_to_id  {
    my ($self, $field) = @_;
    return join( '-', $self->_field_name_parts($field) ) // undef;
}

# -----------------------------------------------------------------------------


1;

=head1 NAME

ChGovUk::Plugins::FormHelpers

=head1 SYNOPSIS

    use Mojo::Base 'Mojolicious';

    sub startup {
        ...
        $self->plugin('ChGovUk::Plugins::FormHelpers');
        ...
    }


=head1 DESCRIPTION

Provides helper functions to templates for form rendering. These functions are
exposed via the C<form()> method.

The form helpers provide helper methods to generate forms HTML from a template,
and take care of maintaining form data between requests and automatic postcode
lookups when necessary.

Calling the helpers renders the related template and inlines the generated HTML
into the parent template. See L</TEMPLATES>.

From an Xslate template:

    % my $form = $c.form( model => $model_obj );
    % $form.start ( name => 'ap01', action => $c.url_for );
    %    $form.text_field    ( label => 'Your name', name => 'name'   );
    %    $form.submit_button ( label => 'Submit',    name => 'submit' );
    %    ...
    % $form.end;

This will render a basic form with an input text field and a submit button.

The model passed into the form method is optional, but without it the form fields
can only be populated from the request parameters.

Any arguments provided to the helper methods are passed to the helper template.

=head1 METHODS

=head2 register

Called to register the plugin with the mojolicious framework. Registers the
helper C<form> which returns an object on which further methods become available.
See L<FORM METHODS>.

	@param   app  [object]     mojolicious application


=head1 EXPORTED HELPERS

=head2 form

Provides access to a set of L<form methods|/"FORM METHODS">.

    @named   model  [model object]  an instantiated model (optional)
    @returns form object

Example

    % my %form = $c.form( model => $model_obj );

See L</FORM METHODS> for the methods exposed from the C<form> object.


=head1 FORM METHODS

=head2 get_all_errors

Return all the current errors.

    @returns an array ref containing the errors.

Example

    % my $errors_r = $form.get_all_errors


=head2 start

Render a opening C<form> tag. Uses the C<start.html.tx> L<template|/TEMPLATES>.

Can be used for a full form or section of a split form view and should be paired with
C<L<end|/end>> to ensure a correct matching closing tag.

    @param   args   [hash] template args (available: name[required], action[required], section)
    @returns a raw html formatted string

Will detect the context which it's currently (full form, open section, closed section)
and render/suppress itself as appropriate.

For sections, if you're using C<L<section>> you won't need to call this manually as it will
have been done automatically for you.

Example

    % # Full form
    % $form.start( name => 'my_form', action => $c.url_for );

    % # Sectional form
    % $form.start( name => 'my_form', action => $c.url_for, section => 'directors-name' );



=head2 end

Render a closing C<form> tag. Uses the C<end.html.tx> L<template|/TEMPLATES>.

Automatically matches with the correct opening tag created with C<L<start|/start>>

For sections, if you're using C<L<section>> you won't need to call this manually as it will
have been done automatically for you.

    @returns a raw html formatted string

Example

    % $form.start( name => 'my_form', action => $c.url_for );
    %   ...
    %   $form.start( name => 'my_form', action => $c.url_for, section => 'directors-name' );
    %   ...
    %   $form.end; # matches the 'directors-name' form start
    %   ...
    % $form.end; # matches full form start


=head2 sections

Automatically render the sections of a form as defined in the section map.

Sections are built using the L<section|/section> method.

    @param   args   [hash]   named args
    @returns a raw html formatted string of sections

Example

  % $form.start( ... );
  %
  %     $form.sections( name => 'appoint-natural-director' );
  %
  % $from.submit_button( ... );
  % $form.end( ... );


=head2 section

Renders a section for a split form. Uses the C<section.html.tx> L<template|/TEMPLATES>.

Automatically includes calls to C<L<$form.start|/start>> and C<L<$form.end|/end>> to delimit
the form and a call to C<L<$form.section_hidden_field|/section_hidden_field>> to embed field names.

B<NB> Requires C<section> and C<node> are in the stash.

    @param   args   [hash]  template args(available: name[required])
    @returns a raw html formatted string

Example

    % %form.section( name => 'date-of-birth' );


=head2 section_hidden_field

Renders a "special" hidden input field containing comma delimited names of the fields
in the associated section. It gets the names from the C<labels> array generated internally
to C<FormHelpers> as each field is rendered.

Normally if you're using C<L<section>> you won't need to call this manually as it will
have been done automatically for you.

    @returns a raw html formatted string

Example

    % $form.section_hidden_field;


=head2 tabs

Renders a tab bar which automatically supports server round-trip tab switching,
and should be a drop-in replacement for a radio field (i.e. model attributes don't
need to change).

    @param  args   [hash]  template args(available: name[required], tabs[required],
                            label)
    @returns a raw html formatted string

Example

    % $form.tabs(
    %    name => 'home_address_linked',
    %    label => 'Home address',
    %    tabs => [
    %        {
    %            label => 'Enter an address',
    %            value => 'N',
    %            id => 'enter-an-address',
    %            include => 'company/transactions/appoint-natural-director/home-address-enter-address.tx'
    %        },
    %        {
    %            label => 'Link to the correspondence address',
    %            value => 'Y',
    %            id => 'link-to-correspondence-address',
    %            include => 'company/transactions/appoint-natural-director/home-address-link-to-correspondence-address.tx'
    %        }
    %    ]
    % )


=head2 hidden_field

Renders a hidden input field. Uses the C<hidden_field.html.tx> L<template|/TEMPLATES>.

Autogenerates an C<id> if one is not supplied in the args.

    @param   args   [hash]  template args (available: name[required], id, value)
    @returns a raw html formatted string

Example

    % $form.hidden_field( name => 'my_field', value => 'some_things' );


=head2 text_field

Create a text field. Required args are dependant on the template being used (see
L</TEMPLATES> for more information).

    @param   args   [hash]  template args
                            (available: name[required], id, as(see below),
                             label[required])
    @returns a raw html formatted string

Example

    # Standard text field
    % $form.text_field( label => 'Your name', id => 'forename', name => 'forename', maxlength => '5' );



=head4 Additional arguments

=over

=item * B<as> - overrides the default template used

=back

By default will use the C<text_field.html.tx> template to
render output. This can be overriden by using the named arg C<as> in the C<args>
hash. This will cause the template named C<B<$as>_field.html.tx> to be used instead.

Currently defined overrides: C<postcode>

Example


    # Use 'postcode_field.html.tx'
    % $form.text_field( id => 'postcode', as => 'postcode' );


=head2 submit_button

Renders a submit button. Uses the C<submit_button.html.tx> L<template|/TEMPLATES>.

    @param   args   [hash]  template args
                            (available: name[required], id)
    @returns a raw html formatted string

Example

    $form.submit_button( id => ,athenticate', name => 'athenticate', label => 'Authenticate me!' );



=head2 checkbox

Renders a checkbox. Uses the C<checkbox.html.tx> L<template|/TEMPLATES>.

    @param   args   [hash]  template args
                            (available: name[required], id, label[required])
    @returns a raw html formatted string

Example

    % $form.checkbox( name => 'sail_register_ABC', label => 'ABC' );



=head2 radio

Renders a radio. Uses the C<radio.html.tx> L<template|/TEMPLATES>.

	@param   args   [hash]  template args(available: name[required], id,
                            options[required])
    @returns a raw html formatted string

Example

    % $form.radio( id => 'my-radio', name => 'my-radio', label => 'really?',
    %              options => [
    %                    { label => 'yes', value => 1 },
    %                    { label => 'no',  value => 0 },
    %              ] );



=head2 select_field

Renders a select field. Uses the C<select_field.html.tx> L<template|/TEMPLATES>.

    @param   args   [hash]  any arguments required by the template (varies)
    @returns a raw html formatted string

Example

    % $form.select_field( id => 'country-of-residence', label => 'Where do you live?',
    %                     name => 'country',
    %                     list => [{ 'GB' => 'United Kingdom'}, {'US' => 'United States' }]
    %                   );


=head2 file_field

Renders a file field. Uses the C<file_field.html.tx> L<template|/TEMPLATES>.
Calculates the file size (to 2 decimal places) and unit used (bytes, Kb and Mb)
and passes those to the template.

    @param   args   [hash]  any arguments required by the template (varies)
    @returns a raw html formatted string

Example

    <% $form.file_field ( name => 'file_upload' ); %>


=head2 section_status

Determine a status class for a section depending on it's state - pending,
current, complete.

    @param   section_name    [string]    name of the section
    @returns "pending", "current", "complete"

Example

    <section id="my-section" class="<% $form.section_status($node.node) %>"


=head2 expand_form_link

Renders a link to move from sectional to full form view. Uses the C<expand_form_link.html.tx>
L<template|/TEMPLATES>.

    @param   args    [hash]      named args
    @named   text    [string]    text to display
    @named   target  [string]    mojolicious route target (used with url_for())
    @returns a raw html formatted string

=head1 TEMPLATES

Each of the L<form methods|"FORM METHODS"> renders it's output using a template.
These templates are found under:

    templates/includes/forms

All the methods have a standard default template which is used, but some
(such as L<text_field|/"text_field"> may be overriden. These templates for override
should be placed in the same folder as the others.

=head3 Comon arguments

All form helper templates accept the following arguments:

=over

=item * B<label> - defines the label text to display alongside the form field. Where
                   a label hasn't been defined one will usually be generated.

=item * B<name> - defines the HTML input name (which should match the model)

=item * B<id> - defines the ID for the HTML element

=back


=cut

