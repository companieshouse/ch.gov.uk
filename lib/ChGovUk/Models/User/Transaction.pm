package ChGovUk::Models::User::Transaction;

use CH::Perl;
use Mouse;

use DateTime::Tiny;
use CH::Util::CVConstants;

# Public attributes
#
has 'submission_number'      => ( is => 'ro', isa => 'Str',            lazy => 0, required => 1, );
has 'status'                 => ( is => 'ro', isa => 'Str',            lazy => 0, required => 1, );
has 'form_type'              => ( is => 'ro', isa => 'Str',            lazy => 0, required => 1, );
has 'order_date_time'        => ( is => 'ro', isa => 'DateTime::Tiny', lazy => 0, required => 1, );
has 'company_number'         => ( is => 'ro', isa => 'Str',            lazy => 0, required => 1, );
has 'company_name'           => ( is => 'ro', isa => 'Str',            lazy => 0, required => 1, );
has 'document_sequence'      => ( is => 'ro', isa => 'Str',            lazy => 0, required => 1, );
has 'document_filename'      => ( is => 'ro', isa => 'Str',            lazy => 0, required => 1, );
has 'attachment_id'          => ( is => 'ro', isa => 'Str',            lazy => 0, required => 1, );

has 'has_downloads'          => ( is => 'ro', isa => 'boolean', lazy => 1, builder => '_build_has_downloads' );

# attachment types
has 'has_memorandum'             => ( is => 'ro', isa => 'Bool',           lazy => 1, builder => '_build_memorandum', );
has 'has_deed'                   => ( is => 'ro', isa => 'Bool',           lazy => 1, builder => '_build_deed', );
has 'has_certificate'            => ( is => 'ro', isa => 'Bool',           lazy => 1, builder => '_build_certificate', );

# form categories
has 'is_incorporation'          => ( is => 'ro', isa => 'Bool',           lazy => 1, builder => '_build_incorporation', );
has 'is_charge'                 => ( is => 'ro', isa => 'Bool',           lazy => 1, builder => '_build_charge', );
has 'is_change_of_name'         => ( is => 'ro', isa => 'Bool',           lazy => 1, builder => '_build_change_of_name', );
has 'is_ixbrl_accounts'         => ( is => 'ro', isa => 'Bool',           lazy => 1, builder => '_build_ixbrl_accounts', );
has 'is_adobe_accounts'         => ( is => 'ro', isa => 'Bool',           lazy => 1, builder => '_build_adobe_accounts', );


# Private attributes
#
has '_flagless_form_type'    => ( is => 'ro', isa => 'Str',            lazy => 1, builder => '_build_flagless_form_type', );

# Builder methods
#

sub _build_has_downloads {
    my ($self) = @_;
    return $self->document_sequence ? true : false;
}

# Clear CYM flag
sub _build_flagless_form_type { 
    my ( $self ) = @_;
    return $self->form_type; 
}

# Form categories
#

# Incorporation form types
sub _build_incorporation { 
    my ( $self ) = @_;
    my $form_type = $self->_flagless_form_type;

    return $form_type == $CV::FORMTYPE::EINC     ||
           $form_type == $CV::FORMTYPE::SDEINC   ||
           $form_type == $CV::FORMTYPE::LLEINC   ||
           $form_type == $CV::FORMTYPE::LLSDEINC;
}

# Charge form types
sub _build_charge { 
    my ( $self ) = @_;
    my $form_type = $self->_flagless_form_type;

    return $form_type == $CV::FORMTYPE::MR01     ||
           $form_type == $CV::FORMTYPE::MR02     ||
           $form_type == $CV::FORMTYPE::LLMR01   ||
           $form_type == $CV::FORMTYPE::LLMR02;
}

# Change of name form types
sub _build_change_of_name { 
    my ( $self ) = @_;
    my $form_type = $self->_flagless_form_type;

    return $form_type == $CV::FORMTYPE::NM01     ||
           $form_type == $CV::FORMTYPE::NM04     ||
           $form_type == $CV::FORMTYPE::LLNM01   ||
           $form_type == $CV::FORMTYPE::SDNM01   ||
           $form_type == $CV::FORMTYPE::LLSDNM01;
}

# Adobe Accounts form types
sub _build_adobe_accounts { 
    my ( $self ) = @_;
    my $form_type = $self->_flagless_form_type;

    return $form_type == $CV::FORMTYPE::UAACCOUNT    ||
           $form_type == $CV::FORMTYPE::DCACCOUNT    ||
           $form_type == $CV::FORMTYPE::ABBRVACCOUNT ||
           $form_type == $CV::FORMTYPE::AUDITACCOUNT;
}

# IXBRL Accounts form types
sub _build_ixbrl_accounts { 
    my ( $self ) = @_;
    my $form_type = $self->_flagless_form_type;

    return $form_type == $CV::FORMTYPE::AA02         ||
           $form_type == $CV::FORMTYPE::AAABBR;
# TODO Add when available in CVConstants
#           $form_type == $CV::FORMTYPE::MICROACCOUNT;
}

# Attachment types
#

# Certificate download
sub _build_certificate {
    my ( $self ) = @_;
    my $attach_cert = 0;

    if ( $self->is_incorporation || $self->is_charge || $self->is_change_of_name ) {
        # TODO certificates
    }

    return $attach_cert;
}

# Memorandum download
sub _build_memorandum { 
    my ( $self ) = @_;
    return $self->is_incorporation; 
}

# Deed download
sub _build_deed { 
    my ( $self ) = @_;
    return $self->is_charge; 
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

ChGovUk::Models::User::Transaction

=head1 SYNOPSIS

    use ChGovUk::Models::User::Transaction;

    my $transaction = ChGovUk::Models::User::Transaction->new();

=head1 DESCRIPTION

Data model for a user transaction

=head1 METHODS

=cut
