package ChGovUk::Controllers::Company::FilingHistory;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::IOLoop;
use Mojo::IOLoop::Delay;

use CH::Perl;
use CH::Util::Pager;
use CH::Util::DateHelper;
use POSIX qw/ceil/;
use JSON::XS;
use ChGovUk::Plugins::FilterHelper;
use DateTime;

# all categories (that can be filtered by)
# XXX temp: need decision on what categories we're going to display and where the
# canonical list should be (e.g. in here, hardwired in the template, in a YAML file,
# pulled from MongoDB &c.)
use constant AVAILABLE_CATEGORIES => {
    'accounts'               => 'Accounts',
    'confirmation-statement' => 'Confirmation statements / Annual returns',
    'capital'                => 'Capital',
    'mortgage'               => 'Charges',
    'incorporation'          => 'Incorporation',
    'officers'               => 'Officers',
};

#-------------------------------------------------------------------------------

# Company filing history page
sub view {
    my ($self) = @_;

    # Process the incoming parameters
    my $company_number   = $self->param('company_number');          # Mandatory
    my $page             = abs(int($self->param('page') || 1));     # Which page has been requested
    my $show_filing_type = $self->get_filter('fh_type');            # Show the filing-type column/containers
    my $category_filter  = $self->get_filter('fh');                 # List of categories to filter by (optional)
    my @filter_categories = split ',', $category_filter;

    my $unavailable_date = $self->config->{unavailable_date} || '2003-01-01';
    $unavailable_date = date_convert($unavailable_date);
    my $recently_filed = $self->config->{recently_filed_days} || 5;
    my $items_per_page = $self->config->{filing_history}->{items_per_page} || 25;

    # FIXME: vvv Remove this when Doc API goes live (and in template) vvv
    $self->stash->{image_service_active} = $self->can_view_images;
    # FIXME: ^^^ Remove this when Doc API goes live (and in template) ^^^

    # FIXME: vvv Remove this when XBRL is working (and in template) vvv
    my $disable_download_xhtml_link = $self->config->{disable_download_xhtml_link} || 0;
    $self->stash(disable_download_xhtml_link => $disable_download_xhtml_link);
    # FIXME: ^^^ Remove this when XBRL is working (and in template) ^^^

    # FIXME: remove this when confirmation-statement goes live - also in template
    my $confirmation_statement_available_date = $self->config->{confirmation_statement_available_date} || '2016-06-30';

    my $date_today = DateTime->now(time_zone => 'GMT');
    $date_today    = sprintf('%d-%02d-%02d', $date_today->year(), $date_today->month(), $date_today->day());
    if (date_convert($date_today) < date_convert($confirmation_statement_available_date)) {
        $self->stash(disable_confirmation_statement_filter => 1);
    }
    # FIXME remove this when confirmation-statement goes live - also in template

    trace "Get company filing history for %s, page %s, filter=[%s]", $self->stash('company_number'), $page, $category_filter [FILING_HISTORY];
    my $pager = CH::Util::Pager->new(entries_per_page => $items_per_page, current_page => $page);

    my $first = $pager->first;   # Get first filing history for this page

    trace "Call filing history api for company %s, start_index %s, items_per_page %s", $self->stash('company_number'),
        $first, $pager->entries_per_page [FILING_HISTORY];

    # Generate an arrayref containing hashrefs of category id's/name's, sorted by name
    my $categories = [
        sort { $a->{name} cmp $b->{name} }
        (map { {
            id   => $_,
            name => AVAILABLE_CATEGORIES->{$_},
        } } keys(%{AVAILABLE_CATEGORIES()}))
    ];

    my $selected_category_count = 0;

    # Iterate through categories setting checked flag and keeping a count of number checked
    for my $category (@$categories) {
        if (scalar(grep { $category->{id} eq $_ } @filter_categories)) {
            $category->{checked} = 1;
            $selected_category_count++;
        }
    }

    my $query = {
        start_index    => $first,
        items_per_page => $pager->entries_per_page
    };

    # encode the selected categories as a comma-separated list and add it as a parameter to the
    # filing-history query
    if ($selected_category_count) {
        $query->{category} = join(',', map { $_->{id} } grep($_->{checked}, @$categories));
    }
 
    my $xhtml_available_date = $self->config->{xhtml_available_date} || '2015-06-01';

    # Get the filing history for the company from the API
    $self->ch_api->company($self->stash('company_number'))->filing_history($query)->force_api_key(1)->get->on(
        success => sub {
            my ( $api, $tx ) = @_;
            my $fh_results = $tx->success->json;
            trace "filing history for %s: %s", $self->stash('company_number'), d:$fh_results [FILING_HISTORY];
            for my $doc (@{$fh_results->{items}}) {
                my $transaction_date = $doc->{date};
                my $formatted_transaction_date = date_convert($transaction_date);
                my $formatted_xhtml_available_date = date_convert($xhtml_available_date);
                if ( $formatted_transaction_date >= $formatted_xhtml_available_date) {
                  $doc->{_xhtml_is_available} = 1 ;
                }
   
		# Generate a missing message for documents before a defined unavailable date
                if ($unavailable_date > $formatted_transaction_date) {
                  $doc->{_missing_message} = 'unavailable';
                } else {
                  $transaction_date =~ s/-//g;
                    # Generate a missing message for recently filed unavailable documents
                    if (CH::Util::DateHelper->days_between(CH::Util::DateHelper->from_internal($transaction_date)) <= $recently_filed) {
                      $doc->{_missing_message} = 'available_in_5_days';
                    }
                }
                # Format date fields in the form of '01 Jan 2004'
                $self->format_filing_history_dates($doc);
            }

            # Work out the paging numbers
            $pager->total_entries( $fh_results->{total_count} // 0 );
            trace "filing history total_count %d entries per page %d",
            $pager->total_entries, $pager->entries_per_page() [FILING_HISTORY];

            $self->stash(current_page_number     => $pager->current_page);
            $self->stash(page_set                => $pager->pages_in_set());
            $self->stash(next_page               => $pager->next_page());
            $self->stash(previous_page           => $pager->previous_page());
            $self->stash(entries_per_page        => $pager->entries_per_page());

            $self->stash(show_filing_type        => $show_filing_type);
            $self->stash(company_filing_history  => $fh_results);
            $self->stash(categories              => $categories);
            $self->stash(selected_category_count => $selected_category_count);
            $self->stash(split_category_at       => ceil(@$categories / 2));

            if ($self->req->is_xhr) {
                $self->render(template => 'company/filing_history/view_content');
            }
            else {
                $self->render;
            }
        },
        failure => sub {
            my ( $api, $error ) = @_;
            error "Error retrieving company filing history for %s: %s",
              $self->stash('company_number'), $error;
            $self->render_exception("Error retrieving company: $error");
        }
      )->execute;

    $self->render_later;
}

sub date_convert {
  my ($original_date) = @_;
  my ($year, $month, $day) = $original_date =~ m/^(\d{4})-(\d{2})-(\d{2})$/;
  return DateTime->new(
          year  => $year,
          month => $month,
          day   => $day,
      );
}

#-------------------------------------------------------------------------------
# FIXME THIS SHOULD ALL BE DONE INSIDE THE TEMPLATE             FIXME
# FIXME IF WE CAN...........                                    FIXME
# FIXME IF WE CANNOT - THEN WHAT ARE API USERS GOING TO DO????? FIXME
sub _dates_to_strings {
    my ( $self, $description_values, ) = @_;

    for my $field ( grep { /date$/ } keys %{ $description_values // {} } ) {
        $description_values->{$field} = CH::Util::DateHelper->isodate_as_string( $description_values->{$field}, "%d %b %Y" );
    }
}

#-------------------------------------------------------------------------------

1;
