package ChGovUk::Plugins::TransactionMap;

use CH::Perl;
use Mojo::Base 'Mojolicious::Plugin';
use CH::Util::CVConstants;

# =============================================================================

our %transaction_map = (
    'change-registered-office-address' => {
        prescreen   => undef,
        data        => ['RegisteredOffice'],
        formtype    => $CV::FORMTYPE::AD01,
        controller  => 'company-transactions-change_registered_office_address',
        model_class => 'ChGovUk::Models::Company::Transactions::ChangeRegisteredOfficeAddress',
        template    => 'company/transactions/change_registered_office_address',
    }, 
);

our %formtype_transaction_map = ();
for my $endpoint (keys %transaction_map) {
    # Store the transaction endpoint inside the hash
    $transaction_map{$endpoint}->{endpoint} = $endpoint;

    # Create a section map (for fast section lookups)
    if(exists $transaction_map{$endpoint}->{sections}) {
        my $next_section = 'summary'; # pseudo section - whole form closed.
        map { 
            $transaction_map{$endpoint}->{section_map}->{$_} = {
                next_section => $next_section
            };
            $next_section = $_; 
        } reverse @{$transaction_map{$endpoint}->{sections}};
    }

    # Invert the map by form type constant (for fast form type lookups)
    $formtype_transaction_map{$transaction_map{$endpoint}->{formtype}} = $transaction_map{$endpoint};
}

# =============================================================================

sub register {
    my ($self, $app) = @_;
  
    $app->helper(get_transaction_metadata => sub {
            return $self->_get_transaction_metadata(@_); # Not shifting controller off
    });

    $app->helper(get_transaction_map => sub {
            return \%transaction_map;
    });

}

# -----------------------------------------------------------------------------

sub _get_transaction_metadata {
    my ($self, $controller, %args) = @_;

    return $formtype_transaction_map{$args{formtype}} if $args{formtype};
    return $transaction_map{$args{endpoint}};
}

# ------------------------------------------------------------------------------ 

1;


=head1 NAME

ChGovUk::Plugins::TransactionMap

=head1 SYNOPSIS

    package MyApp;

    use Mojo::Base 'Mojolicious';

    sub startup {
        my $self = shift;

        $self->plugin( 'ChGovUk::Plugins::TransactionMap' );
    }


=head1 DESCRIPTION

Plugin helpers and definitions for transaction map operations.

For an explanation of how transactions work, see
L<ChGovUk::Guides::Transactions>.


=head1 METHODS


=head2 register

Called to register the plugin with the mojolicious framework. See L</"EXPORTED HELPERS">
for helpers registered by this plugin.

    @param   app  [mojolicious app]   app to register to

Example

    $transaction_map->register($app);


=head1 EXPORTED HELPERS

=head2 get_transaction_map

Get the raw I<transaction map>

    @returns hash ref containing all transaction map data

Example

    my $map = $controller->get_transaction_map;


=head2 mark_section_complete

Mark a form section as having been completed in the session map.
Also stores the next section as the "first incomplete" section.

    @param this_section [string]    current section name
    @param next_url     [string]    url of what should be the next section

Example

    $controller->mark_section_complete( 'directors-name', $controller->next_section_url );


=head2 next_section_url

Given a section, will determine what the next section should be. Takes into
account "next section" stored in session (if exists) and the section map
from the current node metadata.

    @param   section [string]    the current section name
    @returns the url of the next section

Example

    my $url = $controller->next_section_url( 'date-of-birth' );

=head2 get_transaction_metadata

Get the transaction metadata given either an C<endpoint> or C<formtype> (must
supply one or the other - if you give both you'll get the metaadta for C<formtype> and the C<endpoint> will be ignored).

    @param  args        [hash]      named args
    @named  endpoint    [string]    (optional) get map by endpoint
    @named  formtype    [int(CV)]   (optional) get map by formtype CV Value

Example

    # By formtype
    my $meta = $controller->get_transaction_map( formtype => $CV::FORMTYPE::AP01 );

    # By endpoing
    my $meta = $controller->get_transaction_map( endpoint => 'appoint-director' );

=head1 SEE ALSO

L<ChGovUk::Guides::Transactions>

=cut
