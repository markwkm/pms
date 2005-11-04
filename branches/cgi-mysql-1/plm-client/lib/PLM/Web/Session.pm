#
# perl module for supporting the requirements of a web application
# 

package PLM::Web::Session;

@ISA = qw( Exporter );

@EXPORT = qw(   detect_access_state
  get_user_credentials
  handle_login
  content_login
  content_logout
  force_authentication
  force_encryption
);

use strict;
use Exporter;
use CGI qw/:standard/;
use CGI::Cookie;
use CGI::Carp qw(fatalsToBrowser);
use PLM::Util;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use PLM::Web::General;
use PLM::Web::User;

my $ACCESS_STATE_DIR = $cfg->get( 'access_state_dir' ) || "/var/plm/access";

#
# Detect the current state of the session (logged in / logged out)
# 
sub detect_access_state {
    my $session = get_cookie( 'session_id' );

    return 1 if $SESSION{ valid };

    $SESSION{ valid } = 0;

    return 0 unless $session;
    return 0 unless ( -f "$ACCESS_STATE_DIR/$session" );

    open( FILE, "$ACCESS_STATE_DIR/$session" ) || return 0;
    chomp( $SESSION{ username }    = <FILE> );
    chomp( $SESSION{ password }    = <FILE> );
    chomp( $SESSION{ client_addr } = <FILE> );
    close FILE;

    # Make sure it's from the same host
    if ( $ENV{ REMOTE_ADDR } ne $SESSION{ client_addr } ) {
        warn(
            "SECURITY: $SESSION{username} attempting session from changed host "
            . "$SESSION{client_addr}->$ENV{REMOTE_ADDR}" );
        system "rm -f $ACCESS_STATE_DIR/$session";
        my $cookie =
          new CGI::Cookie( -name => 'session_id', -expires => '-1M' );
        add_cookie( $cookie );
        return 0;
    }

    $SESSION{ valid } = 1;

    return 1;
}

sub get_user_credentials {
    return ( "", "" ) unless $SESSION{ valid };

    return ( $SESSION{ username }, $SESSION{ password } );
}

#
# MODULE ( handle_login )
#

sub handle_login {
    return unless ( param( 'action' ) && param( 'action' ) eq "handle_login" );
    return unless ( param( 'username' ) && param( 'password' ) );
    return unless ( http_is_encrypted() );

    my $username = param( 'username' );
    my $password = param( 'password' );

    return unless ( user_login( $username, $password ) );

    my $attempts = 9;
    my $tmp      = 0;
    while ( $attempts && !$tmp ) {
        my $hash = time() . $ENV{ REMOTE_ADDR } . $username . $attempts;
        $hash = md5_base64( $hash );
        $hash =~ s/\///g;
        $hash = "$ACCESS_STATE_DIR/$hash" . "XXXXXX";
        if ( $hash =~ /(.*)/ ) {
            $hash = $1;
        }
        $tmp = `mktemp $hash`;
        if ( $tmp =~ /(.*)/ ) {
            $tmp = $1;
        }
        if ( !$tmp ) {
            warn "problem creating temp file, trying again...";
            $attempts--;

            # sleep(1);
        }
    }
    panic( "Error in attempt to make temp file: [$tmp]" ) unless $tmp;

    $tmp =~ /$ACCESS_STATE_DIR\/(.*)$/;
    my $cookie = new CGI::Cookie( -name => 'session_id', -value => $1 );

    add_cookie( $cookie );

    open( FILE, ">$tmp" ) || panic( "Unable to open local state file" );
    print FILE "$username\n";
    print FILE "$password\n";
    print FILE $ENV{ REMOTE_ADDR } . "\n";
    close( FILE );

    if ( param( 'next_module' ) ) {
        param( -name => 'module', -value => param( 'next_module' ) )
          if param( 'next_module' );
        Delete( 'next_module' );
    }

    $SESSION{ username } = $username;
    $SESSION{ password } = $password;
    $SESSION{ valid }    = 1;

    Delete( 'username' );
    Delete( 'password' );
    Delete( 'action' );
}

#
# MODULE ( logout )
# 

sub content_logout {
    my $cookie = new CGI::Cookie( -name => 'session_id', -expires => '-1M' );
    add_cookie( $cookie );

    # This may get reset elsewhere, but we need it now.
    $SESSION{ valid }    = 0;
    new_html_page();
    page_select( "logout" );

    my ( $header, $footer ) = seperate_html();

    print $header;

    print h3( "You have been logged out of the PLM." ), p();
    print "Please click "
      . link_to_module( "login", "here" )
      . " to log in again.";
    print p();

    webapp_debug() if ( param( 'debug' ) && param( 'debug' ) eq 'on' );
    print $footer;

    exit( 0 );
}

#
# MODULE ( login )
# 

sub content_login {
    new_html_page();
    page_select( "login" );

    my ( $header, $footer ) = seperate_html();
    $header =~ s/logout/login/g;

    print $header;
    print h3( 'Please Login' ), p();
    print start_multipart_form();
    print "Username: ", textfield( 'username' ), p;
    print "Password: ", password_field( -name => 'password', -maxlength => 80 ),
      p;

    # Hidden state information
    print hidden( -name => 'module', -value => param( 'next_module' ) )
      if param( 'next_module' );
    print hidden( -name => 'debug', -value => param( 'debug' ) )
      if param( 'debug' );
    print hidden( -name => 'action', -value => 'handle_login' );

    print submit( -value => 'Login' ), end_form();

    print "<p><br><p>";
    my $signup_link = $cfg->get( "new_account_link" ) || "broken";
    print "<h4>To sign up for a new account, please click ";
    print "<a href=\"$signup_link\">here</a>.</h4><p>";

    webapp_debug() if ( param( 'debug' ) && param( 'debug' ) eq 'on' );
    print $footer;

    exit( 0 );
}

#
# module force_encryption
#
# Require the user switch to a SSL encrypted session to proede
# 

sub force_encryption {
    if ( ( !$ENV{ REQUEST_URI } =~ /next_module/ )
         && ( $ENV{ REQUEST_URI } =~ /module/ ) )
    {
        $ENV{ REQUEST_URI } =~ s/module=/next_module=/;
    }

    my $url = "https://" . $SERVER . $ENV{ REQUEST_URI };

    print redirect( $url );

    exit( 0 );
}

#
# MODULE ( force_authentication ) 
#
# Make the user login before proceding
#
# Saves the state of the next_module the user was originaly going for ( if needed )
# We do NOT overwrite next_module here if it's already present.
# 

sub force_authentication {

    # Switch the user to an encrypted session
    force_encryption() unless http_is_encrypted();

    # Kick back if we are already authenticated
    return if ( detect_access_state() );

    # Two different authentication paths depending on where we are going next
    if ( param( 'next_module' ) || ( param( 'module' ) eq 'login' ) ) {
        content_login();
    } else {
        param( -name => 'next_module', -value => param( 'module' ) )
          if param( 'module' );
        content_login();
    }
}

1;
