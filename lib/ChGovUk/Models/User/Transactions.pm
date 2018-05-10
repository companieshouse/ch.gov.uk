package ChGovUk::Models::User::Transactions;

use CH::Perl;
use Mouse;

use CH::Util::DateHelper;
use CH::Util::CVConstants;

use ChGovUk::Models::User::Transaction;
use POSIX qw(strftime);

# Public attributes
#
has 'auth_id'          => ( is => 'ro', isa => 'Str',      lazy => 0, required => 1, );
has 'days'             => ( is => 'ro', isa => 'Int',      lazy => 1, builder  => '_build_days', );
has 'filings'          => ( is => 'ro', isa => 'ArrayRef[ChGovUk::Models::User::Transaction]', lazy => 1, builder  => '_build_filings', );

# Private attributes
#
has '_results'         => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder  => '_build_results', );

# Builder methods
#

# -----------------------------------------------------------------------------

sub _build_days { 
    my ($self, $days,) = @_;
    $days //= 10;
    debug "Number of days is [%s]", $days [GENERAL];
    return $days;
}

# -----------------------------------------------------------------------------

sub _build_filings {
    my ($self) = @_;
    my @filings = ();

    for my $result ( @{ $self->_results() } ) {
        my $filing = ChGovUk::Models::User::Transaction->new( 
            submission_number => $result->{subnumber},
            status            => $result->{status},
            form_type         => $result->{formType},
            order_date_time   => CH::Util::DateHelper->from_internal($result->{orddtetme}),
            company_number    => $result->{coNumb}       || '',
            company_name      => $result->{coName},
            document_sequence => $result->{docSeq}       || '',
            document_filename => $result->{docFilename}  || '',
            attachment_id     => $result->{attachmentID} || '',
        );
        # Issue #53 raised on github to do something about all the formheaders
        # showing in progress for non-resume forms.
        push @filings, $filing;
    }

    return \@filings;
}

# -----------------------------------------------------------------------------

sub _build_results {
    my ($self) = @_;
    # TODO from API
    return [];
}

# -----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

=head1 NAME

ChGovUk::Models::User::Transactions

=head1 SYNOPSIS

=head1 DESCRIPTION

Page model for 'Your recent filings'

=head1 METHODS

=cut
