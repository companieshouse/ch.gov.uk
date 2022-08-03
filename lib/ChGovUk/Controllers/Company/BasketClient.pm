package ChGovUk::Controllers::Company::BasketClient;

use Moose;

has 'user_agent' => (is => 'ro', isa => 'Object');
has 'access_token' => (is => 'ro', isa => 'Str');
has 'basket_url' => (is => 'ro', isa => 'Str');
has 'append_item_url' => (is => 'ro', isa => 'Str');

sub get_basket {
    my $self = shift;
    my $tx = $self->user_agent->get($self->basket_url => { Authorization => "Bearer ".$self->access_token });

    if ($tx->success) {
        my $body = $tx->success->json;
        my $hasDeliverableItems = 0;

        for my $item (@{$body->{items} || []}) {
            if ($item->{kind} eq 'item#certificate' || $item->{kind} eq 'item#certified-copy') {
                $hasDeliverableItems = 1;
                last;
            }
        }

        return { enrolled => ${$body->{enrolled} || \0}, hasDeliverableItems => $hasDeliverableItems };
    }

    return undef;
}

sub append_item_to_basket {
    my ($self, $request) = @_;

    my $tx = $self->user_agent->post($self->append_item_url => { Authorization => 'Bearer ' . $self->access_token } => json => $request);

    if ($tx->success) {
        return { status => 0 };
    } else {
        return { status => 1 };
    }
}

1;

