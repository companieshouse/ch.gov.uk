package CH::Util::FormatNumber;

use CH::Perl;

# ------------------------------------------------------------------------------ 

sub format {
    my ($class, $number) = @_;
   
    $number = reverse $_[1];
    $number =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $number;
}
# ------------------------------------------------------------------------------ 
1;

