#
# perl module for supporting the requirements of a web application
# 

package PLM::Web::Patch;

@ISA    = qw( Exporter PLM::Object );
@EXPORT =
  qw( patch_search_report content_search content_patch_info content_patch_delete );

use strict;
use Exporter;
use CGI qw/:standard/;
use CGI::Cookie;
use CGI::Carp qw(fatalsToBrowser);
use PLM::Util;

use PLM::Web::General;
use PLM::Web::Session;
use PLM::Web::User;
use PLM::Web::Software;

use PLM::PLM::Filter;
use PLM::RPC::Filter;
use PLM::RPC::Patch;
use PLM::RPC::User;

my @results;    # Place where we hold the results of any searches
my $result_next      = 0;     # Next result to return
my $more_results     = 0;     # Total number of results returned
my $results_per_page = 20;    # Total number of results per page in a report

my $log = getLog( "PLM::Web::Patch" );

#
# Create the XML object for $patch
#
sub new {
    my $self = {};
    my $type = shift;
    bless $self, $type;

    $self->{ data }        = {};
    $self->{ elementName } = "patch";

    $self->addElement( "id",                 "" );
    $self->addElement( "created",            "" );
    $self->addElement( "plm_user_id",        "" );
    $self->addElement( "plm_user_name",      "" );
    $self->addElement( "plm_software_id",    "" );
    $self->addElement( "plm_software_name",  "" );
    $self->addElement( "name",               "" );
    $self->addElement( "private_flag",       "" );
    $self->addElement( "submit_flag",        "" );
    $self->addElement( "content",            "" );
    $self->addElement( "content_format",     "" );
    $self->addElement( "applies_tree",       "" );
    $self->addElement( "md5sum",             "" );
    $self->addElement( "reverse",            "" );
    $self->addElement( "plm_applies_id",     "" );

    return $self;
}

# 
# Create the XML object for a Filter Request
#

#sub new_filter_request {
#    my $self = {};
#    my $type = shift;
#    bless $self, $type;
#
#    $self->{ data }        = {};
#    $self->{ elementName } = "filter_request";
#
#    $self->addElement( "id",                       "" );
#    $self->addElement( "plm_filter_id",            "" );
#    $self->addElement( "plm_filter",               "" );
#    $self->addElement( "plm_patch",                "" );
#    $self->addElement( "plm_user",                 "" );
#    $self->addElement( "priority",                 "" );
#    $self->addElement( "plm_filter_request_state", "" );
#    $self->addElement( "started",                  "" );
#    $self->addElement( "completed",                "" );
#    $self->addElement( "result",                   "" );
#    $self->addElement( "result_detail",            "" );
#    $self->addElement( "state_code",               "" );
#    $self->addElement( "state_detail",             "" );
#    $self->addElement( "output",                   "" );
#
#    return $self;
#}

# 
# Print a unit of table data or a empty unit of data 
#

sub table_data {
    my $data = shift;

    if ( $data ) {
        print "<td>$data</td>\n";
    } else {
        print "<td> </td>\n";
    }
}

#
# Encase data in <center> HTML tags
#

sub center {
    my $data = shift;

    return "<center>$data</center>";
}

#
# Actual Patch functions
#

sub search {
    my $self = shift;

    @results =
      PLM::RPC::Patch->patch_search( $SESSION{ username }, $SESSION{ password }, @_ );

    return 0 unless ( @results );
    return 0 unless $results[ 0 ];

    if ( ( @results ) == ( $results_per_page ) ) {
        $more_results = 1;
    }

    $log->msg( 2, "PLM::RPC->patch_search returned " . @results . " results" );

    return \@results;
}

#
# Create the query array based on search state information
# 
# We support the following param() search designators:
#   search_user ID or Name of the user who creted the patch
#   search_patch Name of the patch
#   search_created Patches newer than time()
#   search_software ID or Name of the software the patch is in 
#   search_private If true, includes search of private patches

sub design_query {
    my %option;
    my @query;

    if ( param( 'sort_field' ) ) {
        $option{ order } = param( 'sort_field' );
    } else {
        $option{ order } = "id";
    }

    if ( param( 'search_page' ) && param( 'search_page' ) > 0 ) {
        $option{ limit } = $results_per_page * ( param( 'search_page' ) - 1 );
        $option{ limit } .= "," . ( $results_per_page );
    } else {
        $option{ limit } = $results_per_page;
    }

    my $token = shift;
    my $key   = shift;

    while ( $token && defined $key ) {
        if ( $token eq "limit" ) {
            $results_per_page = $key;
            delete $option{ limit };
        }

        if ( $token eq "order" ) {
            delete $option{ order };
        }

        push @query, ( $token, $key );

        $token = shift;
        $key   = shift;
    }

    for ( keys %option ) {
        push @query, $_;
        push @query, $option{ $_ };
    }

    $log->msg( 3, "Patch Search Query: @query" );

    return @query;
}

#
# Prints out a line of the form in correct table format
#
sub form_line {
    my ( $name, $field ) = @_;

    print "<tr>";
    print "<td width=150>$name</td>";
    print "<td>$field</td>";
    print "</tr>";
}

#
# Parses the Applies tree and builds Patch_info links
#
sub parse_applies_tree {
    my $p         = shift;
    my $list_len  = shift;
    my $link_base = "<a href=\"/$CGI/$SCRIPT?module=patch_info";
    my $break =0;

    my @tree = split ( /<br>/, $p->getValue( 'applies_tree' ) );
    my @new_tree;

    for ( @tree ) {
        if ($list_len ne 'all'){
            $break++;
            if ($break > $list_len ){
                push @new_tree, '(... )';
                last;
            }
        }
        if ( $_ =~ /baseline/ ) {
            push @new_tree, $_;
        } else {
            $_ =~ /(.*)\s\((.*)\)/;
            my $link = $link_base . "&patch_id=$2\">$1</a>";
            push @new_tree, $link;
        }
    }

    $p->setValue( 'applies_tree', ( join "<br>", @new_tree ) );
}

#
# Prints the html for the patch search form
#

sub patch_search_form {
    my @dates = [
                  "Anytime",       "Last 24 Hours",
                  "Last 7 Days",   "Last 30 Days",
                  "Last 3 Months", "Last 6 Months",
                  "Last 12 Months"
    ];

    print "<p>";

    print start_multipart_form();
    print "<table width=$TABLE_WIDTH border=0>\n";

    my @repos = software_list();
    if ( @repos > 1 ) {
        my $default;
        if ( param( 'software_type' ) ) {
             $default=param( 'software_type' );
        } else {
             $default=software_default();
        }
        form_line(
		"Software Repository",
		popup_menu( -name=>'search_software', -values=>[ @repos ], -default=>$default)
        );
    }

    form_line( "Patch Name or ID",
               textfield( -name => 'search_patch', -maxlength => 254 ) );

    # form_line( "Applies to Name or ID",
    #           textfield( -name=>'search_applies', -maxlength=>254 ) );

    form_line( "User Name",
               textfield( -name => 'search_user', -maxlength => 254 ) );

    # FIXME
    #form_line( "Created",
    #           popup_menu('search_created', @dates, "Anytime") ); 
    form_line( "Created", popup_menu( 'search_created', @dates, "Anytime" ) );

    print hidden( -name => "search_private", -value => "0" );
    print hidden( -name => "module",         -value => "search" );
    print hidden( -name => "action",         -value => "run_patch_search" );
    print hidden( -name => "sort_field",     -value => "idDESC" );
    print hidden( -name => "search_page",    -value => 1 );
    print hidden( -name => "search_format",  -value => "detailed" );

    print "</table>";
    print "<br><p>", submit(), "<p>";
    print endform();

    print "Patch Name searches support * to match any.<br>";
    print "Example: linux-2.4.*-ac<p>";

    # print "Applies and User search require exact matches.";
}

#
# Build a bookmarkable link tot he current search
#

sub bookmark_link {
    my $link = "Create a <a href=\"/$CGI/$SCRIPT?module=search";

    $link .= "&search_software=" . param( 'search_software' )
      if param( 'search_software' );

    $link .= "&search_patch=" . param( 'search_patch' )
      if param( 'search_patch' );

    $link .= "&search_user=" . param( 'search_user' ) if param( 'search_user' );

    # $link .= "&search_private=" . param( 'search_private' )
    #  if param( 'search_private' );

# $link .= "&search_page=" . param( 'search_page' ) if param( 'search_page' );

    $link .= "&search_created=" . param( 'search_created' )
      if param( 'search_created' );

    $link .= "&search_format=" . param( 'search_format' )
      if param( 'search_format' );

    $link .= "&action=" . param( 'action' ) if param( 'action' );

    $link .= "&sort_field=" . param( 'sort_field' ) if param( 'sort_field' );

    $link .= "\">Bookmarkable URL</a> for this search.";

    return $link;
}

#
# Build a link to change the sort order
#

sub sort_field_link {
    my ( $text, $field ) = @_;

    my $link = "<a href=\"/$CGI/$SCRIPT?module=" . param( 'module' );

    $link .= "&search_software=" . param( 'search_software' )
      if param( 'search_software' );
    $link .= "&search_patch=" . param( 'search_patch' )
      if param( 'search_patch' );
    $link .= "&search_user=" . param( 'search_user' ) if param( 'search_user' );
    $link .= "&search_created=" . param( 'search_created' )
      if param( 'search_created' );
    $link .= "&search_private=" . param( 'search_private' )
      if param( 'search_private' );
    $link .= "&search_page=1";
    $link .= "&search_format=" . param( 'search_format' )
      if param( 'search_format' );
    $link .= "&action=" . param( 'action' ) if param( 'action' );

    if ( param( 'sort_field' ) && $field eq param( 'sort_field' ) ) {
        $link .= "&sort_field=$field" . "DESC";
    } else {
        $link .= "&sort_field=$field";
    }

    $link .= "\">$text</a>";

    return "<strong>$link</strong>";
}

#
# Build a link to change the page number
#

sub search_page_link {
    my ( $text, $page ) = @_;

    my $link = "<a href=\"/$CGI/$SCRIPT?module=" . param( 'module' );

    $link .= "&search_software=" . param( 'search_software' )
      if param( 'search_software' );
    $link .= "&search_patch=" . param( 'search_patch' )
      if param( 'search_patch' );
    $link .= "&search_user=" . param( 'search_user' ) if param( 'search_user' );
    $link .= "&search_private=" . param( 'search_private' )
      if param( 'search_private' );
    $link .= "&search_created=" . param( 'search_created' )
      if param( 'search_created' );
    $link .= "&sort_field=" . param( 'sort_field' ) if param( 'sort_field' );
    $link .= "&search_format=" . param( 'search_format' )
      if param( 'search_format' );
    $link .= "&action=" . param( 'action' ) if param( 'action' );

    $link .= "&search_page=$page";

    $link .= "\">$text</a>";

    return "$link";
}

#
# Print out one row in the Patch List Report
#

sub basic_report_line {
    my ( $id, $name, $applies, $date ) = @_;
    my $link =
      "<a href=\"/$CGI/$SCRIPT?module=patch_info&patch_id=$id\">$id</a>";

    print "<tr>\n";
    print "<td valign=\"top\">$link</td>\n";
    print "<td valign=\"top\">$name</td>\n";
    print "<td>$applies</td>\n";
    print "<td valign=\"top\">$date</td>\n";
    print "</tr>\n";
}

# 
# Create a report of the type "simple"
#

sub simple_search_report {
    my $ary = shift;
    my $patch;

    print "<table width=$TABLE_WIDTH border=1><tr>\n";

    print "<td>", center( sort_field_link( "ID",         "id" ) ),   "</td>\n";
    print "<td>", center( sort_field_link( "Patch Name", "name" ) ), "</td>\n";
    print "<td>", center( "Applies Tree" ), "</td>\n";
    print "<td>", center( sort_field_link( "Created Date", "created" ) );
    print "</td>\n</tr>\n";

    #while ( $patch->get_next_result() ) {
    foreach $patch ( @{$ary} ) {
        bless $patch, "PLM::Object::Patch";
        parse_applies_tree($patch, '5');

        my $id   = $patch->getValue( "id" )           || "-1";
        my $name = $patch->getValue( "name" )         || "missing";
        my $tree = $patch->getValue( "applies_tree" ) || "broken";
        my $date = localtime( $patch->getValue( "created" ) );

        basic_report_line( $id, $name, $tree, $date );
    }

    print "</table><center>\n";

    if ( param( 'search_page' ) && param( 'search_page' ) > 1 ) {
        print search_page_link( "Previous Page",
                                ( param( 'search_page' ) - 1 ) );
        if ( $more_results ) {
            print " | "
              . search_page_link( "Next Page", ( param( 'search_page' ) + 1 ) );
        }
    } else {
        if ( $more_results ) {
            print search_page_link( "Next Page", 2 );
        }
    }
    print "</center>";

    print "<p>Select a <strong>Patch ID#</strong> for detailed "
      . "information and a download link<p>";
}

#
# Create a report of the type "detailed"
#
sub detailed_search_report {
    simple_search_report( @_ );
}

#
# Print out the Patch Search results
#

sub patch_search_report {
    my @query = ( "rsf", 1 );
    my $patch   = param( 'search_patch' )   || "";
    my $user    = param( 'search_user' )    || "";
    my $created = param( 'search_created' ) || "";

    $user =~ s/\*//g;

    if ( param( 'search_software' ) ) {
        push @query,
          ( "plm_software_id", software_resolve( param( 'search_software' ) ) );
    }

    if ( $patch ) {
        if ( $patch =~ /^\d+$/ ) {
            push @query, ( "id", $patch );
        } else {
            $patch =~ s/^\*//;
            $patch =~ s/\*$//;
            $patch =~ s/(.*)/\*$1\*/;
            push @query, ( "name", $patch );
        }
    }

    if ( $user ) {
        if ( $user =~ /^\d+$/ ) {
            push @query, ( "plm_user_id", $user );
        } else {
            my @data = PLM::RPC::User->user_verify( $user );
            push @query, ( "plm_user_id", $data[ 0 ] );
        }
    }

    if ( $created && $created ne "Anytime" ) {
        my $d;    # Holds the time count
        if ( $created eq "Last 24 Hours" ) {
            $d = `date -d"-24 hours" +\%s`;
        }
        if ( $created eq "Last 7 Days" ) {
            $d = `date -d"-7 days" +\%s`;
        }
        if ( $created eq "Last 30 Days" ) {
            $d = `date -d"-30 days" +\%s`;
        }
        if ( $created eq "Last 3 Months" ) {
            $d = `date -d"-3 months" +\%s`;
        }
        if ( $created eq "Last 6 Months" ) {
            $d = `date -d"-6 months" +\%s`;
        }
        if ( $created eq "Last 12 Months" ) {
            $d = `date -d"-12 months" +\%s`;
        }
        chomp $d;
        warn "SECURITY: Invalid Created string: $created" unless $d;
        push @query, ( "created", ">$d" );
    }

    my $p = new PLM::Web::Patch();
    my $ary = $p->search( design_query( @query ));
    if ( $ary == 0 ) {
        print "<h3>Sorry, no patches available</h3>";
        return;
    }

    if ( param( 'search_format' ) && param( 'search_format' ) eq "detailed" ) {
        detailed_search_report( $ary );
        return;
    }

    simple_search_report( $ary );
}

#
# MODULE ( search )
#

sub content_search {
    new_html_page();
    page_select( "search" );

    my ( $header, $footer ) = seperate_html();

    print $header;

    if ( param( 'action' ) && ( param( 'action' ) eq "run_patch_search" ) ) {
        print "<p>";
        patch_search_report();
    } else {
        patch_search_form();
    }

    print p(), bookmark_link(), p();

    webapp_debug() if ( param( 'debug' ) && param( 'debug' ) eq 'on' );
    print $footer;

    exit( 0 );
}

#
# Prints out a single row of the patch info report
#
sub patch_info_row {
    my ( $f1, $f2, $f3 ) = @_;

    print "<tr><td width=100 valign=\"top\">$f1</td>";
    print "<td width=250>$f2</td>";

    if ( $f3 ) {
        print "<td>$f3</td>";
    }

    print "<tr>";
}

#
# Builds a list of applies_tree links for redirecting to correct patch info pages
#
sub build_applies_link_tree {
    my @list = @_;
}

#
# MODULE ( patch_info )
#

sub print_patch_info_basic {
    my $p    = shift;
    my $user = shift;

    print "<table>";
    patch_info_row( "Patch ID: ",   $p->getValue( 'id' ) );
    patch_info_row( "Patch Name: ", $p->getValue( 'name' ) );

    my $md5sum = $p->getValue( 'md5sum' );
    if ( $md5sum ) {
        patch_info_row( "md5sum: ", $md5sum );
    }

    my @software = software_list();
    if ( @software > 1 ) {
        patch_info_row( "Repository: ", $p->getValue( 'plm_software_name' ) );
    }

    print "</table><p><table>";

    patch_info_row( "Created By: ", $user, "( Select user for quick search )" );

    my $date = localtime( $p->getValue( "created" ) );
    patch_info_row( "Created On: ", $date );

    print "</table><p><table>";

    if ( $p->getValue( 'reverse') ){
        patch_info_row( "Type: ", "Reverse" );
    }
    patch_info_row( "Applies Tree: ", $p->getValue( 'applies_tree' ) );

    print "</table><p>";
}

sub filter_result_link {
    my $filter = shift;
    my $text   = shift;
    my $id     = $filter->getValue( "id" );

    return "<a href=\"/$CGI/$SCRIPT?module=filter_output&id=$id\">$text</a>";
}

sub print_patch_info_filter {
    my $patch_id = shift;

    print "<br><p>";

    my $data = PLM::RPC::Filter->filter_request_by_patch( $patch_id );

    unless ( $data && $data->[ 0 ] ) {
        print "<h3>There are no filter requests for this patch.</h3><p>";
        return;
    }

    print "<table border=1>";

    print "<tr>";
    print "<td width=100>" . center( strong( "Filter Name" ) ) . "</td>";
    print "<td width=400>" . center( strong( "Detailed Result" ) ) . "</td>";
    print "<td width=80>" . center( strong( "Status" ) ) . "</td>";
    print "</tr>\n";

    my $filter;
    my $iter;
    foreach $iter ( @{ $data } ) {
        #$filter = new_filter_request PLM::Web::Patch();
        #$filter->parseXMLData( $_ );
        $filter = $iter;
        bless $filter, 'PLM::PLM::Filter';

        print "<tr>";

        my $state = $filter->getValue( "state_code" );

        table_data( $filter->getValue( "plm_filter" ) );
        table_data( $filter->getValue( "result_detail" ) );

        my $result = $filter->getValue( "result" );
        $result = ( font_color( $result, "green" ) ) if ( $result eq "PASS" );
        $result = ( font_color( $result, "red" ) )   if ( $result eq "FAIL" );

        if ( $state eq "Completed" || $state eq "Failed" ) {
            $result = filter_result_link( $filter, $result );
            table_data( center( $result ) );
        } else {
            table_data( center( $state ) );
        }

        print "</tr>";
    }

    print "</table>";

    if ( scalar( @{ $data } ) ) {
        print "<p>Select a completed filter's Status to view the output ";
        print "of the run log.";
    }
}

sub print_patch_info_delete {
    my $p        = shift;
    my $patch_id = $p->getValue( "id" );

    my ( $user, $pass ) = get_user_credentials();

    return unless ( $user && $pass );

    my $ret = PLM::RPC::Patch->patch_can_delete( $user, $pass, $patch_id );

    return unless ( $ret );

    my $link =
      "<a href=\"/$CGI/$SCRIPT?module=patch_delete&"
      . "patch_id=$patch_id\">here</a>";
    print "<p>To <strong>delete</strong> this patch from the system, ";
    print "click $link.<br>";
}

sub print_patch_info_download {
    my $p    = shift;
    my $user = shift;

    print "<p>";

    # Give download instrcutions based on baseline status
    my $id           = $p->getValue( 'id' );
    if ( $p->getValue( 'applies_tree' ) eq "[ none - baseline ]" ) {
        my $repo =
          $cfg->get( 'webapp_source_' . $p->getValue( 'plm_software_id' ) )
          || "missing";
        print
"Since this patch is a baseline version, you can only obtain the original source ";
        print "from the base repository at $repo.<p>";
    } else {
        my $patch_server = $cfg->get( 'webapp_patch_server' )
          || "http://cgi-bin";
        my $link = "<a href=\"$patch_server/getpatch?id=$id.bz2\">here</a>";
        print
"Select an entry in the Applies Tree to jump to another detailed report.<p>";
        print
"To <strong>download</strong> a bzip2 compressed copy of this patch, click $link.<br>";
        print
"To <strong>view</strong> this patch, click <a href=\"$patch_server/getpatch?id=$id \">here</a> once only. (May take a while for big patches.)<br>";
    }
    my $software_name=$p->getValue( 'plm_software_name');
    print "To <strong>view</strong> scripts for this patch, click <a href=\"/$CGI/$SCRIPT?module=build_info&patch_id=$id&software=$software_name\">build</a>, <a href=\"/$CGI/$SCRIPT?module=build_info&patch_id=$id&command_type=install&software=$software_name\">install</a> or <a href=\"/$CGI/$SCRIPT?module=build_info&patch_id=$id&command_type=validate&software=$software_name\">validate</a>.<br>";
}

sub content_patch_info {
    my $patch_id = param( 'patch_id' );
    my $p;
    my $data;
    my $link_base =
      "<a href=\"/$CGI/$SCRIPT?module=search&action=run_patch_search";

    $link_base .= "&sort_field=idDESC&search_format=detailed&search_private=0";

    new_html_page();
    page_select( "patchinfo" );

    my ( $header, $footer ) = seperate_html();

    print $header;

    # print h4( "Patch Information Report" );
    print "<p>";

    # Get the Patch XML parsed into our local object
    $data = PLM::RPC::Patch->patch_get_info( $patch_id );
    $p = $data;

    if (ref $p){
        # Special pre-output data munging
        my $user =
          $link_base . "&search_user=" . $p->getValue( 'plm_user_id' ) . "\">";
        $user .= $p->getValue( 'plm_user_name' ) . "</a>";

        # call in non-object way...
        parse_applies_tree($p, 'all');
    
        print_patch_info_basic( $p,    $user );
        print_patch_info_download( $p, $user );
        print_patch_info_delete( $p );
        print_patch_info_filter( $p->getValue( "id" ) );
    } else {
        print "<h3>There are no patches with the ID $patch_id.</h3><p>";
    }

    webapp_debug() if ( param( 'debug' ) && param( 'debug' ) eq 'on' );
    print $footer;

    exit( 0 );
}

sub content_patch_delete {
    my $patch_id = param( "patch_id" );
    my ( $user, $pass ) = get_user_credentials();

    my @data = PLM::RPC::Patch->patch_delete( $user, $pass, $patch_id );

    new_html_page();
    page_select( "patchinfo" );

    my ( $header, $footer ) = seperate_html();

    print $header;

    print "<p><h4>Deleting Patch ID# $patch_id</h4></p>";

    if ( @data && $data[ 0 ] ) {
        print "Patch deleted OK<p>";
    } else {
        print "Patch delete failed for unknown reason, see admin.";
        $log->msg( 0, "SECURITY: Patch delete failure, unknown reason" );
    }

    webapp_debug() if ( param( 'debug' ) && param( 'debug' ) eq 'on' );
    print $footer;

    exit( 0 );
}

1;
