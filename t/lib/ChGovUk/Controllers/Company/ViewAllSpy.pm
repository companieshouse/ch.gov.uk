package ChGovUk::Controllers::Company::ViewAllSpy;

use parent qw(ChGovUk::Controllers::Company::ViewAll);
use CH::Perl;

my @verifications;

sub render {
    my ($self, %args) = @_;

    $_->(%args) for @verifications;
}

#-------------------------------------------------------------------------------

sub expect {
    my ($self, $verification) = @_;

    push(@verifications, $verification);
}

#-------------------------------------------------------------------------------

1;