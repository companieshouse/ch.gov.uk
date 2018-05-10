use strict;

use Test::More;
use CH::Test;
use CH::MojoX::Plugin::Config;
use ChGovUk::Models::DataAdapter;

use Readonly;
Readonly my $CLASS => 'ChGovUk::Models::Company::Transactions::ChangeRegisteredOfficeAddress';

# ------------------------------------------------------------------------------
# basic tests

set_constructor_args $CLASS, [ data_adapter => new ChGovUk::Models::DataAdapter ];

use_ok $CLASS;

new_ok $CLASS;

methods_ok(
    $CLASS,
    qw(
        address
    ),
);

has_roles $CLASS, qw(
                     MooseX::Model::Role::Validate
                     MooseX::Model::Role::Populate
);

done_testing;

# ------------------------------------------------------------------------------
1;
