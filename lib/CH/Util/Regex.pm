package CH::Util::Regex;

use CH::Perl;
use charnames ':full';
use HTML::Entities qw(encode_entities_numeric);

use vars qw( $regex $xml_regex );

# Note: XML regexes are for use in XSD context. 
# As such they do not use anchors ( ^ $ ), are encoded to entities ( &amp; ) and are not precompiled ( qr() ) 

#------------------------------

# Character sets for use in creating regular expressions

my $numeral = qq(\N{DIGIT ZERO}-\N{DIGIT NINE});

my $basic_punctuation = qq(\N{HYPHEN-MINUS}\N{COMMA}\N{FULL STOP}\N{COLON}\N{SEMICOLON});

my $space = qq(\N{SPACE}); # not mentioned in spec but added to chips

my $latin_capital_a_to_z = qq(\N{LATIN CAPITAL LETTER A}-\N{LATIN CAPITAL LETTER Z});

my $latin_small_a_to_z = qq(\N{LATIN SMALL LETTER A}-\N{LATIN SMALL LETTER Z});

my $schedule1table1 = q() .
                      $latin_capital_a_to_z .
                      qq(\N{AMPERSAND}\N{COMMERCIAL AT}\N{DOLLAR SIGN}\N{POUND SIGN}\N{YEN SIGN}\N{EURO SIGN});

my $schedule1table2 = q() . 
                      qq(\N{APOSTROPHE}\N{QUOTATION MARK}) . 
                      qq(\N{LEFT-POINTING DOUBLE ANGLE QUOTATION MARK}\N{RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK}) . # GUILLEMET
#                      qq(\N{SINGLE LEFT-POINTING ANGLE QUOTATION MARK}\N{SINGLE RIGHT-POINTING ANGLE QUOTATION MARK}) . # GUILLEMET - not reqd
                      qq(\N{LEFT SINGLE QUOTATION MARK}\N{RIGHT SINGLE QUOTATION MARK}) . 
                      qq(\N{LEFT DOUBLE QUOTATION MARK}\N{RIGHT DOUBLE QUOTATION MARK}) . 
                      qq(\N{QUESTION MARK}\N{EXCLAMATION MARK}) . 
                      qq(\N{SOLIDUS}\\\N{REVERSE SOLIDUS}) . 
                      qq(\N{LEFT PARENTHESIS}\N{RIGHT PARENTHESIS}) . 
                      qq(\\\N{LEFT SQUARE BRACKET}\\\N{RIGHT SQUARE BRACKET}) . 
                      qq(\N{LEFT CURLY BRACKET}\N{RIGHT CURLY BRACKET}) . 
#                      qq(\N{LEFT-POINTING ANGLE BRACKET}\N{RIGHT-POINTING ANGLE BRACKET}) . # real angle brackets
                      qq(\N{LESS-THAN SIGN}\N{GREATER-THAN SIGN}) . # probably what they mean by angle brackets
                      q();

# schedule 1 table 3
my $schedule1table3 = qq(\N{ASTERISK}\N{EQUALS SIGN}\N{NUMBER SIGN}\N{PERCENT SIGN}\N{PLUS SIGN});

# all LATIN characters as defined by Unicode
my $latin = q(\p{LATIN}); 

# additional official EU LATIN characters as accepted by CHIPS
my $chips_eu_latin = q() .
                     qq(\N{LATIN CAPITAL LETTER A WITH GRAVE}-\N{LATIN CAPITAL LETTER O WITH DIAERESIS}) .
                     qq(\N{LATIN CAPITAL LETTER O WITH STROKE}-\N{LATIN SMALL LETTER LONG S}) .
                     qq(\N{LATIN SMALL LETTER F WITH HOOK}) . 
                     qq(\N{LATIN CAPITAL LETTER A WITH RING ABOVE AND ACUTE}-\N{LATIN SMALL LETTER O WITH STROKE AND ACUTE}) .
                     qq(\N{LATIN CAPITAL LETTER W WITH GRAVE}-\N{LATIN SMALL LETTER W WITH DIAERESIS}) .
                     qq(\N{LATIN CAPITAL LETTER Y WITH GRAVE}\N{LATIN SMALL LETTER Y WITH GRAVE}) . 
                     q();

# additional Welsh and Gaelic LATIN characters as accepted by CHIPS
my $chips_celtic_latin = q() . 
                         qq(\N{LATIN SMALL LETTER A WITH GRAVE}-\N{LATIN SMALL LETTER A WITH CIRCUMFLEX}) .
                         qq(\N{LATIN SMALL LETTER A WITH DIAERESIS}) .
                         qq(\N{LATIN SMALL LETTER E WITH GRAVE}-\N{LATIN SMALL LETTER I WITH DIAERESIS}) .
                         qq(\N{LATIN SMALL LETTER O WITH GRAVE}-\N{LATIN SMALL LETTER O WITH CIRCUMFLEX}) .
                         qq(\N{LATIN SMALL LETTER O WITH DIAERESIS}) .
                         qq(\N{LATIN SMALL LETTER U WITH GRAVE}-\N{LATIN SMALL LETTER U WITH DIAERESIS}) .
                         qq(\N{LATIN CAPITAL LETTER A WITH GRAVE}-\N{LATIN CAPITAL LETTER A WITH CIRCUMFLEX}) .
                         qq(\N{LATIN CAPITAL LETTER A WITH DIAERESIS}) .
                         qq(\N{LATIN CAPITAL LETTER E WITH GRAVE}-\N{LATIN CAPITAL LETTER I WITH DIAERESIS}) .
                         qq(\N{LATIN CAPITAL LETTER O WITH GRAVE}-\N{LATIN CAPITAL LETTER O WITH CIRCUMFLEX}) .
                         qq(\N{LATIN CAPITAL LETTER O WITH DIAERESIS}) .
                         qq(\N{LATIN CAPITAL LETTER U WITH GRAVE}-\N{LATIN CAPITAL LETTER U WITH DIAERESIS}) .
                         qq(\N{LATIN CAPITAL LETTER W WITH CIRCUMFLEX}-\N{LATIN SMALL LETTER Y WITH CIRCUMFLEX}) .
                         q();

#------------------------------

# CH character set 1: type=company_name_string

# Applies to new company names on registration, change of name etc
# Based on the Company and Business Names Regulations

# Schedule 1 Regulation 2: http://www.opsi.gov.uk/si/si2009/uksi_20091085_en_2

my $set1_anywhere = $basic_punctuation . $space . $numeral . $schedule1table1 . $schedule1table2;
my $set1_all      = $set1_anywhere . $schedule1table3;

my $company_name_string = qq|^(?!.{0,2}?[$schedule1table3])(?:[$set1_all]{1,160})\$|;
$regex->{company_name_string} = qr($company_name_string);

my $xml_company_name_string = qq|[$set1_anywhere]{3}[$set1_all]{0,157}|;
$xml_regex->{company_name_string} = encode_entities_numeric( $xml_company_name_string );

#------------------------------

# CH character set 2: type=name_address_string

# Applies to name and address data other than new names for which use set 1 above
# Based on the Registrar of Companies and Applications for Striking Off Regulations
# Extended for official EU countries except Bulgarian and Greek ( non-Latin ), plus Icelandic, Norwegian, Welsh and Gaelic

# Schedule Regulation 8(3): http://www.opsi.gov.uk/si/si2009/draft/ukdsi_9780111479520_en_2

my $set2_all = q() .
               $set1_all .
               $latin_small_a_to_z .
               $chips_eu_latin .  # in an ideal world $latin would replace $chips_eu_latin
               q();

my $name_address_string = qq|^(?:[$set2_all]*)\$|;
$regex->{name_address_string} = qr($name_address_string);

my $xml_name_address_string = qq|[$set2_all]*|;
$xml_regex->{name_address_string} = encode_entities_numeric( $xml_name_address_string );

#------------------------------

# CH character set 3
# Applies to all data not covered by set 1 and set 2 above
# Based on the Registrar of Companies and Applications for Striking Off Regulations
# Extend for Welsh

my $set3_all = q() .
               $set1_all .
               $latin_small_a_to_z .
               $chips_celtic_latin .  # in an ideal world $latin would replace $chips_celtic_latin
               q();

my $other_data_string = qq|^(?:[$set3_all]*)\$|;
$regex->{other_data_string} = qr($other_data_string);

my $xml_other_data_string = qq|[$set3_all]*|;
$xml_regex->{other_data_string} = encode_entities_numeric( $xml_other_data_string );

#------------------------------

# Dump compiled patterns

# $ perl -MCH::Util::Regex -wle 'use utf8;binmode STDOUT, ":encoding(utf8)"; use charnames q(:full); $r=$CH::Util::Regex::regex;for $p (keys %{$r} ) { print "\nPATTERN $p\n$r->{$p}";}'
# 
# PATTERN company_name_string
# (?^u:^(?!.{0,2}?[*=#%+])(?:[-,.:; 0-9A-Z&@$£¥€'"«»‘’“”?!/\\()\[\]{}<>*=#%+]{1,160})$)
# 
# PATTERN name_address_string
# (?^u:^(?:[-,.:; 0-9A-Z&@$£¥€'"«»‘’“”?!/\\()\[\]{}<>*=#%+a-zÀ-ÖØ-ſƒǺ-ǿẀ-ẅỲỳ]*)$)
# 
# PATTERN other_data_string
# (?^u:^(?:[-,.:; 0-9A-Z&@$£¥€'"«»‘’“”?!/\\()\[\]{}<>*=#%+a-zà-âäè-ïò-ôöù-üÀ-ÂÄÈ-ÏÒ-ÔÖÙ-ÜŴ-ŷ]*)$)

#-----

#  $ perl -MCommon::regex -wle 'use HTML::Entities;use utf8;binmode STDOUT, ":encoding(utf8)"; use charnames q(:full); $r=$Common::regex::xml_regex;for $p (keys %{$r} ) { $t=decode_entities($r->{$p});print "\nPATTERN $p\nENCODED ",($r->{$p}),"\nDECODED ",$t;}'
 
# PATTERN company_name_string
# ENCODED [-,.:; 0-9A-Z&#x26;@$&#xA3;&#xA5;&#x20AC;&#x27;&#x22;&#xAB;&#xBB;&#x2018;&#x2019;&#x201C;&#x201D;?!/\\()\[\]{}&#x3C;&#x3E;]{3}[-,.:; 0-9A-Z&#x26;@$&#xA3;&#xA5;&#x20AC;&#x27;&#x22;&#xAB;&#xBB;&#x2018;&#x2019;&#x201C;&#x201D;?!/\\()\[\]{}&#x3C;&#x3E;*=#%+]{0,157}
# DECODED [-,.:; 0-9A-Z&@$£¥€'"«»‘’“”?!/\\()\[\]{}<>]{3}[-,.:; 0-9A-Z&@$£¥€'"«»‘’“”?!/\\()\[\]{}<>*=#%+]{0,157}
 
# PATTERN name_address_string
# ENCODED [-,.:; 0-9A-Z&#x26;@$&#xA3;&#xA5;&#x20AC;&#x27;&#x22;&#xAB;&#xBB;&#x2018;&#x2019;&#x201C;&#x201D;?!/\\()\[\]{}&#x3C;&#x3E;*=#%+a-z&#xC0;-&#xD6;&#xD8;-&#x17F;&#x192;&#x1FA;-&#x1FF;&#x1E80;-&#x1E85;&#x1EF2;&#x1EF3;]*
# DECODED [-,.:; 0-9A-Z&@$£¥€'"«»‘’“”?!/\\()\[\]{}<>*=#%+a-zÀ-ÖØ-ſƒǺ-ǿẀ-ẅỲỳ]*

# PATTERN other_data_string
# ENCODED [-,.:; 0-9A-Z&#x26;@$&#xA3;&#xA5;&#x20AC;&#x27;&#x22;&#xAB;&#xBB;&#x2018;&#x2019;&#x201C;&#x201D;?!/\\()\[\]{}&#x3C;&#x3E;*=#%+a-z&#xE0;-&#xE2;&#xE4;&#xE8;-&#xEF;&#xF2;-&#xF4;&#xF6;&#xF9;-&#xFC;&#xC0;-&#xC2;&#xC4;&#xC8;-&#xCF;&#xD2;-&#xD4;&#xD6;&#xD9;-&#xDC;&#x174;-&#x177;]*
# DECODED [-,.:; 0-9A-Z&@$£¥€'"«»‘’“”?!/\\()\[\]{}<>*=#%+a-zà-âäè-ïò-ôöù-üÀ-ÂÄÈ-ÏÒ-ÔÖÙ-ÜŴ-ŷ]*

 
#------------------------------

#  Testing - see regex.t for full tests

#  perl -MCommon::regex -wle 'use utf8;binmode STDOUT, ":encoding(utf8)"; use charnames q(:full); $r=$Common::regex::regex;for $p (keys %{$r} ) { print "\n\nPATTERN $p\n$r->{$p}\n";for $s ("YEN\N{YEN SIGN}","EURO\N{EURO SIGN}","eu\x{00D8}",qw( XYZXYZ H#ASH CIRC^ abc123 EQ=UALS 123HIJ ROUND\)\( ABC123 DEF<!> SQUARE][ EURO€ "Help!")) { print $s,q( ),($s=~$r->{$p}?q(MATCH):q(NO MATCH)); } }'

#------------------------------

1;
