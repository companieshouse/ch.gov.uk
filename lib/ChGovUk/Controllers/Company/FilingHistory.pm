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
use Time::HiRes qw(tv_interval gettimeofday);
use Scalar::Util qw(refaddr);

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

    my $unavailable_date = $self->config->{unavailable_date} || '2003-03-01';
    my $request_document_unavailable_date = '2003-03-01';
    $unavailable_date = date_convert($unavailable_date);
    my $recently_filed = $self->config->{recently_filed_days} || 5;
    my $items_per_page = $self->config->{filing_history}->{items_per_page} || 25;

    # FIXME: vvv Remove this when Doc API goes live (and in template) vvv
    $self->stash->{image_service_active} = $self->can_view_images;
    # FIXME: ^^^ Remove this when Doc API goes live (and in template) ^^^

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
    my $formatted_xhtml_available_date = date_convert($xhtml_available_date);

    my $zip_available_date = $self->config->{zip_available_date} || '2021-03-01';
    my $formatted_zip_available_date = date_convert($zip_available_date);

    my $delay = Mojo::IOLoop->delay;

    # Get the filing history for the company from the API
    my $start = [Time::HiRes::gettimeofday()];
    debug "TIMING company.filing_history (company filing history) '" . refaddr(\$start) . "'";
    $self->ch_api->company($self->stash('company_number'))->filing_history($query)->force_api_key(1)->get->on(
        success => sub {
            my ( $api, $tx ) = @_;
            debug "TIMING company.filing_history (company filing history) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
            my $fh_results = $tx->success->json;
            trace "filing history for %s: %s", $self->stash('company_number'), d:$fh_results [FILING_HISTORY];

            $delay->steps(
                sub {
                    my ($delay) = @_;
                    for my $doc (@{$fh_results->{items}}) {

                        my $transaction_date = $doc->{date};
                        my $formatted_transaction_date = date_convert($transaction_date);

                        # Get content_type for filing that could be a zip. Zip filings will always have 1 page and be type 'AA',
                        # and will also only be available if they are filed after the zip_available_date (2021-03-01 by default).
                        if (defined $doc->{links}->{document_metadata} && $doc->{type} eq 'AA' && $doc->{pages} == 1 &&
                            $formatted_transaction_date > $formatted_zip_available_date) {

                            my $delay_end = $delay->begin(0);
                            trace "Calling document API to retrieve content_type for possible zip filing [%s]", $doc->{links}->{document_metadata};
                            $self->_get_content_type_application_zip( $doc->{links}->{document_metadata}, $doc, $delay_end);
                        }

                        if ( $formatted_transaction_date >= $formatted_xhtml_available_date) {
                            $doc->{_xhtml_is_available} = 1;
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
                        $transaction_date =~ s/-//g;
                        $request_document_unavailable_date =~ s/-//g;
                        if ( $transaction_date >= $request_document_unavailable_date) {
                            $doc->{_missing_doc} = 1;
                        }

                        # Format date fields in the form of '01 Jan 2004'
                        $self->format_filing_history_dates($doc);
                    }
                }
            );
            $delay->wait;

            # Work out the paging numbers
            $pager->total_entries( $fh_results->{total_count} // 0 );
            trace "filing history total_count %d entries per page %d",
            $pager->total_entries, $pager->entries_per_page() [FILING_HISTORY];

            $delay->on(
                # Must wait for delay to finish before stashing data,
                # as all calls to the Document API must be complete.
                finish => sub {
                    $self->stash(current_page_number     => $pager->current_page);
                    $self->stash(page_set                => $pager->pages_in_set());
                    $self->stash(next_page               => $pager->next_page());
                    $self->stash(previous_page           => $pager->previous_page());
                    $self->stash(entries_per_page        => $pager->entries_per_page());
                    $self->stash(recently_filed          => $recently_filed);

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
                }
            );
        },
        failure => sub {
            my ( $api, $error ) = @_;
            debug "TIMING company.filing_history (company filing history) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
            error "Error retrieving company filing history for %s: %s",
            $self->stash('company_number'), $error;
            $self->render_exception("Error retrieving company: $error");
        }
    )->execute;

    $self->render_later;
}

#-------------------------------------------------------------------------------

# _get_content_type_application_zip calls the document API and retrieves a resources array of content_types for the provided filing.
# If a resources array is found, we will search the resources array for an 'application/zip' content_type and if found,
# set it on the '$doc' element for use in the frontend template.
sub _get_content_type_application_zip {
    my ( $self, $document_metadata_uri, $doc, $callback ) = @_;

    my $start = [Time::HiRes::gettimeofday()];
    debug "TIMING document.metadata (company filing history) '" . refaddr(\$start) . "'";
    $self->ch_api->document($document_metadata_uri)->metadata->get->on(
        failure => sub {
            my ($api, $tx) = @_;
            debug "TIMING document.metadata (company filing history) failure '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
            my $code = $tx->error->{code} // 0;
            $doc->{content_type} = 'unknown';
            if ($code == 404) {
                error "Content Type not found for %s: %s. Setting content_type to unknown", $document_metadata_uri, $code;
                return $callback->(0);
            }
            else {
                error "Error fetching Content Type for %s: %s. Setting content_type to unknown", $document_metadata_uri, $tx->error->{message};
                return $callback->(0);
            }
        },
        error => sub {
            my ($api, $err) = @_;
            debug "TIMING document.metadata (company filing history) error '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
            $doc->{content_type} = 'unknown';
            error "Error fetching Content Type for %s: %s. Setting content_type to unknown", $document_metadata_uri, $err;
            return $callback->(0);
        },
        success => sub {
            my ($api, $tx) = @_;
            debug "TIMING document.metadata (company filing history) success '" . refaddr(\$start) . "' elapsed: " . Time::HiRes::tv_interval($start);
            my $resources = $tx->res->json->{resources};
            if ($resources) {
                foreach my $content_type (keys $resources) {
                    if ($content_type eq 'application/zip') {
                        trace "ZIP filing found. Setting content_type on doc to application/zip [%s]", $document_metadata_uri;
                        $doc->{content_type} = $content_type;
                        last;
                    }
                }
            } else {
                trace "No content_type found for %s. Setting content_type to unknown", $document_metadata_uri;
                $doc->{content_type} = 'unknown';
            }
            return $callback->(0);
        }

    )->execute;
}

#-------------------------------------------------------------------------------

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
