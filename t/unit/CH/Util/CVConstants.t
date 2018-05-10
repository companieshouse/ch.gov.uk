use Test::More;
use CH::Test;
use 5.10.0;

use Readonly;
use CH::Util::CVConstants;

Readonly my $CLASS => 'CH::Util::CVConstants';

use_ok $CLASS;

    isa_ok $CLASS, 'Mojolicious::Plugin';

    methods_ok $CLASS, qw(
                    import
                );

    test_global_constants();
    test_method_lookup();
    #test_method_lookupByValue();

done_testing();
exit(0);

# ==============================================================================

sub test_global_constants {
    is($CH::Util::CVConstants::compiled, 1, 'CV constants are compiled');

    subtest "Test globally namespaced constants" => sub {
        is($CV::DSTAT::COMPLETE, 3,  'CV constant ID is returned');
        is($CV::CLASS::DSTAT,    13, 'CV class ID is returned');
    };

    return;
}

# ==============================================================================

sub test_method_lookup {
    %CH::Util::CVConstants::lookup_data = (
        55 => {
            1 => "Example company type"
        },
        company_type => {
            ltd => "Private Limited Company"
        }
    );
    my $result = CH::Util::CVConstants::lookup(get_fake_app(), 55, 1);
    is_deeply($result,  'Example company type' , 'Lookup returns correct result');

    $result = CH::Util::CVConstants::lookup(get_fake_app(), 'company_type', 'ltd');
    is_deeply($result,  'Private Limited Company' , 'Lookup using class name returns correct result');
}

# ============================================================================== 

# TODO
#sub test_method_lookupByValue {
#    my $result = CH::Util::CVConstants::lookupByValue(get_fake_app(), 'companytype', 3, 'en');
#    is_deeply($result, { description => 'PLC' }, 'Interface is ok');
#}

# ==============================================================================

__END__
