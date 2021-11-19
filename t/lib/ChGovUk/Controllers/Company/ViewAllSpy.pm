package ChGovUk::Controllers::Company::ViewAllSpy;

use strict;
use warnings;

use parent qw(ChGovUk::Controllers::Company::ViewAll);
use CH::Perl;

my @verifications;

sub render {
    my ($self, %args) = @_;

    my $verification;

    while(@verifications) {
        $verification = pop @verifications;
        $verification->(%args);
    }
}

#-------------------------------------------------------------------------------

sub expect {
    my ($self, $verification) = @_;

    push(@verifications, $verification);
}

#-------------------------------------------------------------------------------

1;