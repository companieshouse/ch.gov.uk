package CH::Util::Pager;

use Moose;
use Readonly;
use CH::Perl;

Readonly my $DEFAULT_ENTRIES_PER_PAGE => 10;
Readonly my $DEFAULT_CURRENT_PAGE     => 1;
Readonly my $DEFAULT_PAGES_PER_SET    => 10;

has total_entries    => ( is => 'rw', isa => 'Int', default => 0);
has scroll_flag      => ( is => 'rw', isa => 'Int', default => 0);
has entries_per_page => ( is => 'rw', isa => 'Int', default => $DEFAULT_ENTRIES_PER_PAGE);
has current_page     => ( is => 'rw', isa => 'Int', default => $DEFAULT_CURRENT_PAGE);

has pages_per_set    => ( is => 'rw', isa => 'Int', default => $DEFAULT_PAGES_PER_SET, predicate => 'has_pages_per_set' ); # PAGE_SET_PAGES_PER_SET
has previous_set     => ( is => 'ro', isa => 'Int', init_arg => undef, writer => '_set_previous_set');       # PAGE_SET_PREVIOUS
has next_set         => ( is => 'ro', isa => 'Int', init_arg => undef, writer => '_set_next_set');       # PAGE_SET_NEXT
has pages_in_set     => ( is => 'ro', isa => 'ArrayRef', init_arg => undef, writer => '_set_pages_in_set');  # PAGE_SET_PAGES

around 'current_page' => sub {
    my $orig = shift;
    my $self = shift;

    if (@_){
        $self->$orig(@_);         # Set the current page number
        $self->pages_per_set($self->pages_per_set());
        return $self->$orig();    # return the current page number
    }

    # Return the current page number
    return $self->first_page unless defined $self->{current_page};
    return $self->first_page if $self->{current_page} < $self->first_page;

    return $self->{current_page};
};

before 'pages_in_set' => sub {
    my $self = shift;

    if ($self->has_pages_per_set){
        my $max_pages_per_set = $self->pages_per_set;
        if ( $max_pages_per_set == 1 ) {
            # Only have one page in the set, must be page 1
            $self->_set_previous_set( $self->current_page() - 1 ) if $self->current_page != 1;
            $self->_set_pages_in_set([1]);
            $self->_set_next_set ($self->current_page() + 1) if $self->current_page() < $self->last_page();
        } else {

            # See if we have enough pages to slide
            my $scroll_flag = $self->scroll_flag;
            
            if ( $max_pages_per_set >= $self->last_page() ) {
                # No sliding, no next/prev pageset
                # print "create page set 1 .. ", $self->last_page, "\n";

                $self->_set_pages_in_set([ '1' .. $self->last_page() ]);
            }
            elsif($max_pages_per_set < $self->last_page() && $scroll_flag == 1){
            
                my $last_page = $self->last_page();
                if ($last_page > 10) { $last_page = 10 };
                $self->_set_pages_in_set([ '1' .. $last_page ]);

            }
            else {
                # Find the middle rounding down - we want more pages after, than before
                my $middle = int( $max_pages_per_set / 2 );

                # offset for extra value right of center on even numbered sets
                my $offset = 1;
                if ( $max_pages_per_set % 2 != 0 ) {
                    # must have been an odd number, add one
                    $middle++;
                    #$offset = 1;
                }

                my $starting_page = $self->current_page() - $middle + 1;
                $starting_page = 1 if $starting_page < 1;
                my $end_page = $starting_page + $max_pages_per_set - 1;
                $end_page = $self->last_page()
                    if $self->last_page() < $end_page;

                if ( $self->current_page() <= $middle ) {
                    #print "current page in middle, create page set 1 .. $max_pages_per_set\n";
                    #print "next set = ($max_pages_per_set, $middle, $offset) = ", $max_pages_per_set + $middle - $offset + 1, "\n";

                    # near the start of the page numbers
                    $self->_set_next_set( $max_pages_per_set + $middle - $offset + 1);
                    $self->_set_pages_in_set([ '1' .. $max_pages_per_set ]);
                } elsif ( $self->current_page()
                    > ( $self->last_page() - $middle - $offset ) )
                {
                    # near the end of the page numbers
                    $self->_set_previous_set( $self->last_page()
                        - $max_pages_per_set
                        - $middle + 1);
                    $self->_set_pages_in_set(
                        [ ( $self->last_page() - $max_pages_per_set + 1 )
                        .. $self->last_page() ]);
                } else {
                    # Start scrolling
                    # print "start scrolling\n";
                    # print "create page set $starting_page .. $end_page\n";
                    $self->_set_pages_in_set([ $starting_page .. $end_page ]);
                    $self->_set_previous_set( $starting_page - $middle - $offset);
                    # print "previous set ($starting_page, $middle, $offset) ", $starting_page - $middle - $offset, "\n";
                    $self->_set_previous_set( 1 ) if $self->previous_set < 1;
                    #print "next set = ($end_page, $middle) = ", $end_page + $middle, "\n";
                    $self->_set_next_set( $end_page + $middle);
                }
            }
        }
        return $self;
    }

    return ;
};


sub first_page {
    return 1;
}

sub last_page {
    my $self = shift;

    my $pages = $self->total_entries / $self->entries_per_page;
    if ($pages > 10 && $self->scroll_flag == 1 ) { $pages = 10 }; 
    my $last_page;

    if ($pages == int $pages){
        $last_page = $pages;
    }
    else {
        $last_page = 1 + int($pages);
    }

    $last_page = 1 if $last_page < 1;


    return $last_page;
}

sub first {
    my $self = shift;

    return (( $self->current_page - 1) * $self->entries_per_page );
}


sub last {
    my $self = shift;

    if ($self->current_page == $self->last_page){
        return $self->total_entries;
    }
    return ($self->current_page * $self->entries_per_page) - 1;
}


sub previous_page {
    my $self = shift;

    if ($self->current_page > 1){
        return $self->current_page - 1;
    }

    return undef;
}

sub next_page {
    my $self = shift;
    
    return $self->current_page < $self->last_page ? $self->current_page  + 1 : undef;
}

sub skipped {
    my $self = shift;

    my $skipped = $self->first -1;

    return 0 if $skipped < 0;
    return $skipped;
}

1;

