#
# perl module for supporting the requirements of a web application
# 

package PLM::Web::Userpage;

@ISA = qw( Exporter );

@EXPORT = qw(content_userpage);

use strict;
use Exporter;
use CGI qw/:standard/;
use CGI::Cookie;
use CGI::Carp qw(fatalsToBrowser);
use PLM::Util;

use PLM::Web::General;
use PLM::Web::Session;
use PLM::Web::User;
use PLM::Web::Patch;

#
# MODULE ( userpage )
#

sub content_userpage {
    my ( $username, $password ) = get_user_credentials();

    new_html_page();
    page_select( "userpage" );

    my ( $header, $footer ) = seperate_html();

    print $header;

    print h3( "Summary" );

    # Table 1 Start
    print '<table width="$TABLE_WIDTH" border=0><tr>' . "\n";

    # Contents of Table 1 Column 1
    print '<td width="345">' . "\n";
    print "Account: $username<br>\n";
    print "</td>\n";

    # Contents of Table 1 Column 2
    print '<td width="200">' . "\n";
    printf "Email: %s<br>\n", user_get_email();
    print "</td>\n";

    # Closing of Table 1
    print "</tr></table>\n", p();

    print h3( "Recent Patch Activity" );

    param( -name => 'search_user',    -value => user_get_id() );
    param( -name => 'search_private', -value => "1" );
    param( -name => 'search_limit',   -value => '10' )
      unless param( 'search_limit' );
    param( -name => 'sort_field', -value => 'idDESC' )
      unless param( 'sort_field' );

    patch_search_report();

    webapp_debug() if ( param( 'debug' ) && param( 'debug' ) eq 'on' );
    print $footer;

    exit( 0 );
}

1;
