use strict;

use Test::More;
use CH::Test;
use Test::Exception;

use 5.16.0;

use CH::Util::CVConstants;
use CH::Util::CompanyRecord qw/ list_records_matching chips_record_to_ef chips_record_to_title /;

use Readonly;
Readonly my $MODULE => 'CH::Util::CompanyRecord';

my %LTD_LIMIT = ( valid_for => $CV::ESCOMPANYTYPE::BYSHR );
my %PLC_LIMIT = ( valid_for => $CV::ESCOMPANYTYPE::PLC );
my %LLP_LIMIT = ( valid_for => $CV::ESCOMPANYTYPE::LLP );

my %SCO_LIMIT = ( valid_in => $CV::JURISDICTION::SCOTLAND );
my %WAL_LIMIT = ( valid_in => $CV::JURISDICTION::WALES );

# ------------------------------------------------------------------------------

use_ok $MODULE;

test_module();

for my $combo_ref (
            { 'subtest' => 'Scottish LTD', expect_between => [9, 15], limit => { %LTD_LIMIT, %SCO_LIMIT }, },
            { 'subtest' => 'Scottish PLC', expect_between => [9, 15], limit => { %PLC_LIMIT, %SCO_LIMIT }, },
            { 'subtest' => 'Welsh LTD',    expect_between => [9, 15], limit => { %LTD_LIMIT, %WAL_LIMIT }, },
            { 'subtest' => 'Welsh PLC',    expect_between => [9, 15], limit => { %PLC_LIMIT, %WAL_LIMIT }, },
            { 'subtest' => 'Welsh LLP',    expect_between => [3, 5],  limit => { %LLP_LIMIT, %WAL_LIMIT }, },
            { 'subtest' => 'Scottish LLP', expect_between => [3, 5],  limit => { %LLP_LIMIT, %SCO_LIMIT }, },
        ) {
    test_module_limits($combo_ref);
}


done_testing();

# ------------------------------------------------------------------------------

sub test_module {

    subtest "Generic module tests" => sub {
        is    (chips_record_to_ef('doesnotexist'), undef, 'Ensure chips_to_ef fails');
        is    (chips_record_to_ef('5002'),         3,     'Ensure chips_to_ef succeeds');

        my $match = $MODULE . "::match_list";
        no strict;
        ok    (  $match->('A', [ qw /  A  B C / ]), 'Prove match_list simple inclusion');
        ok    (  $match->('B', [ qw /  A  B C / ]), 'Prove match_list simple inclusion');
        ok    (! $match->('X', [ qw /  A  B C / ]), 'Prove match_list simple inclusion');
        ok    (  $match->('A', [ qw /  A !B C / ]), 'Prove match_list simple exclusion');
        ok    (! $match->('B', [ qw /  A !B C / ]), 'Prove match_list simple exclusion');
        ok    (! $match->('X', [ qw /  A !B C / ]), 'Prove match_list simple exclusion');
        ok    (  $match->('B', [ qw /  A !B B / ]), 'Prove match_list simple exclusion');
        ok    (! $match->('A', [ qw / !A  B C / ]), 'Prove match_list initial exclusion');
        ok    (  $match->('B', [ qw / !A  B C / ]), 'Prove match_list initial exclusion');
        ok    (  $match->('X', [ qw / !A  B C / ]), 'Prove match_list initial exclusion');
    };
}

# ------------------------------------------------------------------------------

sub test_module_limits {
    my($combo_ref) = @_;

    subtest "Module limit tests for $combo_ref->{subtest}" => sub {
        my $is_llp    = ($combo_ref->{limit}->{valid_for} == $CV::ESCOMPANYTYPE::LLP);
        my $is_scot   = ($combo_ref->{limit}->{valid_in}  == $CV::JURISDICTION::SCOTLAND);
        my @chips_ids = list_records_matching(%{ $combo_ref->{limit} });

        note "limits ", join(',', map { $_ .'='. $combo_ref->{limit}->{$_} } keys $combo_ref->{limit}), " got @chips_ids";

        if (defined $combo_ref->{expect_between}) {
            cmp_ok(scalar(@chips_ids), '>=', $combo_ref->{expect_between}->[0], 'Ensure sufficient number of records');
            cmp_ok(scalar(@chips_ids), '<=', $combo_ref->{expect_between}->[1], 'Ensure sufficient limit to number of records');
        }

        # count ef_id in list
        my %count_ef_ids = ();

        for my $chips_id (@chips_ids) {
            my $ef_id = chips_record_to_ef($chips_id);
            my $title = chips_record_to_title($chips_id);

            $count_ef_ids{ $ef_id }++;

            like  ( $title,  qr/^\w+( [\w ]+)*$/,  "Test title sanity for $chips_id" );

            my $expected_chips_id;
            if ($ef_id == 8) {
                $expected_chips_id = ($is_llp ? 5015 : 5007);
                isnt ( $combo_ref->{limit}->{valid_in}, $CV::JURISDICTION::SCOTLAND, 'Ensure jurisdiction matches non-Scotland');
            } elsif ($ef_id == 9) {
                $expected_chips_id = ($is_llp ? 5016 : 5012);
                is   ( $combo_ref->{limit}->{valid_in}, $CV::JURISDICTION::SCOTLAND, 'Ensure jurisdiction matches Scotland');
            }
            if (defined $expected_chips_id) {
                is( $chips_id, $expected_chips_id, "ef_id $ef_id <$title> is for correct jurisdiction (" . ($is_llp ? '' : 'non-') . 'LLP)');
            }

        }

        is( join(',', grep({$count_ef_ids{$_}>1} @chips_ids)), '',    'Ensure there are never two instances of any ef_id');

        if ($is_scot) {
            is ( $count_ef_ids{9} // 0, 1, 'Ensure has one CHARGES for LLP ' .     join(',',keys %count_ef_ids));
        } else {
            is ( $count_ef_ids{8} // 0, 1, 'Ensure has one CHARGES for non-LLP ' . join(',',keys %count_ef_ids));
        }
    };
}

# ==============================================================================
1;
