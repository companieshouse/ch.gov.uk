package ChGovUk::Controllers::Company::Insolvency;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::IOLoop;
use Mojo::IOLoop::Delay;

use CH::Perl;
use CH::Util::DateHelper;

#-------------------------------------------------------------------------------

# Company insolvency page
sub view {
    my ($self) = @_;

    # Process the incoming parameters
    my $company_number = $self->param('company_number');

    # Get the insolvency data for the company from the API
    $self->ch_api->company($self->stash('company_number'))->insolvency()->get->on(
        success => sub {
            my ( $api, $tx ) = @_;
            my $results = $tx->success->json;
            trace "insolvency for %s: %s", $self->stash('company_number'), d:$results [INSOLVENCY];

            # Format date fields in the form of '01 Jan 2004'
            for my $case (@{$results->{cases}}) {

                for my $case_date (@{$case->{dates}}) {
                    $self->_dates_to_strings( $case_date );
                }

                for my $practitioner (@{$case->{practitioners}}) {
                    $self->_dates_to_strings( $practitioner );
                    $practitioner->{address} = $self->_address_as_string( $practitioner->{address} );
                }
            }

            $self->stash(display_scottish_insolvency_msg => $self->_display_scottish_insolvency_msg($results->{cases}));
            $self->stash(insolvency => $results);
            $self->stash(company_number => $company_number);
            $self->render;
        },
        failure => sub {
            my ( $api, $error ) = @_;

            error "Error retrieving company insolvency for %s: %s",
              $self->stash('company_number'), $error;
            $self->render_exception("Error retrieving company: $error");
        }
      )->execute;

    $self->render_later;
}

#-------------------------------------------------------------------------------

sub _dates_to_strings {
    my ( $self, $description_values, ) = @_;

    for my $field ( grep { /date$/ | /^ceased_to_act_on$/ | /^appointed_on$/ } keys %{ $description_values // {} } ) {
        $description_values->{$field} = CH::Util::DateHelper->isodate_as_string( $description_values->{$field}, "%e %B %Y" );
    }
}

#-------------------------------------------------------------------------------

sub _address_as_string {
    my ( $self, $address ) = @_;

    return $address = join(
        ', ',
        grep { $_ && length $_ } (
            $address->{address_line_1},
            $address->{address_line_2},
            $address->{locality},
            $address->{region},
            $address->{country},
            $address->{postal_code}
        )
    );
}

#-------------------------------------------------------------------------------

# Display the Scottish AIB insolvency message for scottish only companies, which are not
# wholely in Administration, Administration Order and In Administration

sub _display_scottish_insolvency_msg {
    my ($self, $list_of_cases, $jurisdiction) = @_;

    for my $case (@{$list_of_cases}) {
        if (exists $case->{notes}){
            if (grep { $_ eq 'scottish-insolvency-info'} @{$case->{notes}}){
                return 'scottish-insolvency-info';
            }
        }
    }

    return ;
}

#-------------------------------------------------------------------------------

1;
