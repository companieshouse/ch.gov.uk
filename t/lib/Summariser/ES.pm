package Summariser::ES;

use CH::Perl;
use Moose;
use CH::Test;
use Mojo::URL;
use DateTime;
extends 'Summariser';

#-------------------------------------------------------------------------------------------

sub _build_url {
    my ( $self ) = @_;

    my $app = get_fake_app();
    $app->plugin('CH::MojoX::Plugin::Config');
    my $api = $app->config->{api};
    my $url = Mojo::URL->new( $api->{url} )->path( 'search/companies/' )->query( key => $api->{key} );
    return $url;
}

#-------------------------------------------------------------------------------------------

sub summary {
    my ( $self, $company_number, $delay, ) = @_;

    my $summary = $self->initial_summary;

    my $profile_url = $self->_url->query( [ q => $company_number ] );

    if ( defined $delay ) { # non-blocking
        my $end = $delay->begin(0);
        $self->_ua->get( $profile_url => sub {
            my ( $ua, $tx ) = @_;
            $self->_summarise( $company_number, $summary, $tx->res->json() );
            $end->( $summary );
        } );
    }
    else { # blocking
        my $tx = $self->_ua->get( $profile_url, );
        $self->_summarise( $company_number, $summary, $tx->res->json() );
    }

    return $summary;
}

#-------------------------------------------------------------------------------------------

sub _summarise {
    my ( $self, $company_number, $summary, $profile_json ) = @_;

    if ( defined $profile_json ) {
        if ( $profile_json->{errors} ) {
            $summary->{error} = $profile_json->{errors}[0]{error} // 'Error';
            warn "Error retrieving data from ElasticSearch for company %s: %s", $company_number, d:$profile_json [SANITY_CHECK];
        }
        else {
            my @companies = grep { $_->{number} eq $company_number } @{ $profile_json->{items} };
            if ( @companies ) {
                my $company = $companies[0];
                @$summary{qw(company_name company_number status date)} = @$company{qw(name number status date)};
                $summary->{date} =~ s/(\d+)\/(\d+)\/(\d+)/$3-$2-$1/; # Either incorporation date or dissolution date
            }
        }
    }

}
#-------------------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;
