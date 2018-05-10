package CH::Util::CompanyRecord;

use CH::Perl;
use CH::Util::CVConstants;

require Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(
    list_records_matching
    chips_record_to_ef
    chips_record_to_title
);

# ==============================================================================

# see match_list
my @valid_for_llp     = (     $CV::ESCOMPANYTYPE::LLP,  );
my @valid_for_non_llp = ( '!'.$CV::ESCOMPANYTYPE::LLP,  );
my @valid_for_byshr   = (     $CV::ESCOMPANYTYPE::BYSHR, $CV::ESCOMPANYTYPE::BYSHREXEMPT );
my @valid_for_plc     = (     $CV::ESCOMPANYTYPE::PLC   );

# ------------------------------------------------------------------------------

my @record_types = (
     {
        chips_id    => 5000,
        ef_id       => 1,
        mnemonic    => 'MEMBER',
        title       => 'Register of members',
        valid_for   => [ @valid_for_non_llp, ],
     },
     {
        chips_id    => 5001,
        ef_id       => 2,
        mnemonic    => 'DIR',
        title       => 'Register of directors',
        valid_for   => [ @valid_for_non_llp, ],
     },
     {
        chips_id    => 5002,
        ef_id       => 3,
        mnemonic    => 'DIRCONTRACT',
        title       => 'Directors service contracts',
        valid_for   => [ @valid_for_non_llp, ],
     },
     {
        chips_id    => 5003,
        ef_id       => 4,
        mnemonic    => 'DIRINDEM',
        title       => 'Directors indemnities',
        valid_for   => [ @valid_for_non_llp, ],
     },
     {
        chips_id    => 5004,
        ef_id       => 5,
        mnemonic    => 'SEC',
        title       => 'Register of secretaries',
        valid_for   => [ @valid_for_non_llp, ],
     },
     {
        chips_id    => 5005,
        ef_id       => 6,
        mnemonic    => 'RESMEET',
        title       => 'Records of resolutions and meetings',
        valid_for   => [ @valid_for_non_llp, ],
     },
     {
        chips_id    => 5006,
        ef_id       => 7,
        mnemonic    => 'DEB',
        title       => 'Register of debenture holders',
        valid_for   => [ @valid_for_non_llp, ],
     },
     {
        chips_id    => 5007,
        ef_id       => 8,
        mnemonic    => 'CHARGEEWNI',
        title       => 'Instruments creating charges and register of charges',
        valid_for   => [ @valid_for_non_llp, ],
        valid_in    => [ '!'.$CV::JURISDICTION::SCOTLAND, ],
     },
     {
        chips_id    => 5008,
        ef_id       => 10,
        mnemonic    => 'OWNSHRPURCH',
        title       => 'Contracts relating to purchases of own shares',
        valid_for   => [ @valid_for_byshr, @valid_for_plc  ],
     },
     {
        chips_id    => 5009,
        ef_id       => 11,
        mnemonic    => 'OWNSHRCAP',
        title       => 'Documents relating to redemption or purchase of own shares out of capital by private company',
        valid_for   => [ @valid_for_byshr, ],
     },
     {
        chips_id    => 5010,
        ef_id       => 12,
        mnemonic    => 'INVEST',
        title       => 'Reports to members on the outcome of investigations by public company into interests in its shares',
        valid_for   => [ @valid_for_plc, ],
     },
     {
        chips_id    => 5011,
        ef_id       => 13,
        mnemonic    => 'INTEREST',
        title       => 'Register of interests in shares disclosed to public company',
        valid_for   => [ @valid_for_plc, ],
     },
     {
        chips_id    => 5012,
        ef_id       => 9,
        mnemonic    => 'CHARGESC',
        title       => 'Instruments creating charges and register of charges',
        valid_for   => [ @valid_for_non_llp, ],
        valid_in    => [ $CV::JURISDICTION::SCOTLAND, ],
     },
     {
        chips_id    => 5013,
        ef_id       => 14,
        mnemonic    => 'LLPMEMBERS',
        title       => 'Register of LLP members',
        valid_for   => [ @valid_for_llp, ],
     },
     {
        chips_id    => 5014,
        ef_id       => 7,
        mnemonic    => 'DEB',
        title       => 'Register of debenture holders',
        valid_for   => [ @valid_for_llp, ],
     },
     {
        chips_id    => 5015,
        ef_id       => 8,
        mnemonic    => 'CHARGEEWNI',
        title       => 'Instruments creating charges and register of charges',
        valid_for   => [ @valid_for_llp, ],
        valid_in    => [ '!'.$CV::JURISDICTION::SCOTLAND, ],
     },
     {
        chips_id    => 5016,
        ef_id       => 9,
        mnemonic    => 'CHARGESC',
        title       => 'Instruments creating charges and register of charges',
        valid_for   => [ @valid_for_llp, ],
        valid_in    => [ $CV::JURISDICTION::SCOTLAND, ],
     },
);

# ==============================================================================

sub list_records_matching {
    my (%filter) = @_;
    my @found_ids = ();
    for my $record (@record_types) {
        my $is_match = 1;

        # filter by scalar keys
        for my $attr (qw/ ef_id chips_id mnemonic /) {
            if (defined $filter{$attr}) {
                if (not ref($filter{$attr})) {
                    $is_match = 0 if $record->{$attr} ne $filter{$attr};
                } else {
                    $is_match = 0 unless match_list($record->{$attr}, $filter{$attr});
                }
            }
            last unless $is_match;
        }
        next unless $is_match;

        # filter by list keys
        for my $attr (qw/ valid_in valid_for /) {
            if (defined $filter{$attr} and defined $record->{$attr}) {
                if (not match_list($filter{$attr}, $record->{$attr})) {
                    $is_match = 0;
                    last;
                }
            }
        }

        push @found_ids, $record->{chips_id} if $is_match;
    }
    return @found_ids;
}

# ------------------------------------------------------------------------------
# return ef_id from chips_id

sub chips_record_to_ef {
    my ($chips_id) = @_;

    my @recs = _recs_where_attr_val('chips_id', $chips_id, 'ef_id');
    return unless @recs;
    # return first element (assumes only one is returned, since chips_id is unique)
    return $recs[0];
}

# ------------------------------------------------------------------------------
# return title from chips_id

sub chips_record_to_title {
    my ($chips_id) = @_;

    my @recs = _recs_where_attr_val('chips_id', $chips_id, 'title');
    return unless @recs;
    # return first element (assumes only one is returned, since chips_id is unique)
    return $recs[0];
}

# ==============================================================================
# private methods

# ------------------------------------------------------------------------------
# return a list of $return_attr for records matching {$attr} eq $val

sub _recs_where_attr_val {
    my ($attr, $val, $return_attr) = @_;

    my @matches = ();
    for my $record_hash (@record_types) {
        push @matches, $record_hash if $record_hash->{$attr} eq $val;
    }
    return map { $_->{$return_attr} } @matches if defined $return_attr;
    return @matches;
}

# ------------------------------------------------------------------------------

sub match_list {
    my ($val, $list) = @_;

    # logic is (apply OR, '!' is an exclusion item, last option wins):
    #   $list = [ qw/  A  B  C / ];  # true iff $val is A or B or C
    #   $list = [ qw/  A !B  C / ];  # true iff $val is A, exclude any B, or is C
    #   $list = [ qw/ !A  B  C / ];  # true iff $val is anything excluding A, or is B or C

    # if first in list is a negative, default 'is_in_list' to true
    my $is_in_list = (@$list ? $list->[0] =~ /^!/ : 0);

    for my $list_item (@$list) {
        if ( $list_item =~ /^!/ ) {
            $is_in_list = 0 if '!' . $val eq $list_item;
        } else {
            $is_in_list = 1 if       $val eq $list_item;
        }
    }
    return $is_in_list;
}

# ------------------------------------------------------------------------------

1;

=head1 NAME

CH::Util::CompanyRecord - utilities to produce/filter company record/register information

=head1 SYNOPSIS

  use CH::Util::CompanyRecord qw/ list_records_matching chips_record_to_ef chips_record_to_title /;
  use CH::Util::CVConstants;

  @scottish_llp_chips_ids = list_records_matching(
        valid_for => $CV::ESCOMPANYTYPE::LLP,
        valid_in  => $CV::JURISDICTION::SCOTLAND,
  );

  for my $chips_id (@scottish_llp_chips_ids) {
      say "record with chips_id $chips_id has ef_id [", chips_record_to_ef($chips_id), "] ",
          "and title [", chips_record_to_title($chips_id), "]";
  }

=head1 DESCRIPTION

Utilities to filter and list company records.

Various exportable functions are available to list and detail available record types,
filtered by jurisdiction or company type.

=head1 METHODS

=head2 array[string] list_records_matching( valid_in => $cv_jurisdiction, valid_for => $co_type )

Return a list of chips_ids for company records. Optionally with valid_in and/or valid_for parameters
to filter the results.

  @param   valid_id   string   a CVConstants value representing a jurisdiction
  @param   valid_for  string   a CVConstants value represeting company type (for llp / plc / ltd)
  @returns array[string]       an array of chips_ids

=head2 string chips_record_to_ef(5001)

Return a string containing the ef identifier that corresponds with the specified
chips identifier.

  @param   string   the chips record identifier
  @returns string   the electronic filing identifier

=head2 string chips_record_to_title(5002)

Return the title matching the objects with the given chips ID

  @returns string  human readable title of record

=cut
