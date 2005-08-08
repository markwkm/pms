#
# perl module for supporting the requirements of a web application
# 

package PLM::Web::General;

@ISA = qw( Exporter );

@EXPORT =
  qw(webapp_debug get_cookie http_is_encrypted add_cookie new_html_page);
push @EXPORT, qw(print_data_file fix_source_links query_duplicate page_select);
push @EXPORT, qw(seperate_html link_to_module font_color);
push @EXPORT, qw(%SESSION $html $cfg $SERVER $CGI $SCRIPT $DATADIR $LANGUAGE);
push @EXPORT, qw($TABLE_WIDTH);

use strict;
use Exporter;
use CGI qw/:standard/;
use CGI::Cookie;
use CGI::Carp qw(fatalsToBrowser);
use PLM::Util;

my %Cookies = fetch CGI::Cookie();    # Internal list of cookies
                                      # methods will update these on the
                                      # clients computer
my @COOKIE_QUEUE   = ();       # Queue of cookies to send before the header
my $HTML_INIT_DONE = 0;        # Limits page to one header

our $cfg = getConfig();

our $DATADIR = $cfg->get( 'webapp_data_dir' ) || "./";
our $SERVER  = $ENV{ HTTP_HOST };
our $SCRIPT  = "plm";

our %SESSION  = ();
our $html     = load_branding( $DATADIR );
our $LANGUAGE = $cfg->get( 'webapp_language' ) || "en";
our $CGI      = $cfg->get( 'cgi_bin' ) || "cgi-bin";

# Global setting for the size of the inner table
our $TABLE_WIDTH = 615;

sub http_is_encrypted {
    return 1 if $ENV{ SSL_SESSION_ID };
    return 1 if $ENV{ HTTPS } && ( $ENV{ HTTPS } eq "on" );

    return 0;
}

sub webapp_debug {
    my @keys = param;

    warn( "WebApp::webapp_debug() called" );

    print "</center><p><pre>";

    if ( http_is_encrypted() ) {
        print "TRAFFIC IS ENCRYPTED\n";
    } else {
        print "TRAFFIC IS NOT ENCRYPTED\n";
    }

    printf "method: %s\n", request_method();

    if ( request_method() eq "POST" ) {
        printf "content_type: %s\n", content_type();
    }

    for ( @keys ) {
        print "query parameter [$_] => [" . param( $_ ) . "]\n";
    }

    for ( keys %ENV ) {
        print "ENV valiable [$_] => [" . $ENV{ $_ } . "]\n";
    }

    foreach ( keys %Cookies ) {
        print "cookie [$_] => [" . $Cookies{ $_ } . "]\n";
    }
}

sub load_branding {
    my $txt       = '';
    my $path      = shift;
    my $brand     = $cfg->get( 'webapp_brand' ) || "default_header.html";
    my $footer     = $cfg->get( 'webapp_brand_footer' ) || "default_footer.html";
    my $image_url = $cfg->get( 'webapp_image_url' ) || "images";

    panic( "Missing path to brand in load_branding" ) unless $path;
    panic( "Missing brand in load_branding" )         unless $brand;

    if ( -f "$path/$brand" ) {
        open( FILE, "$path/$brand" )
          || panic( "Unable to open brand [$brand]" );
        $txt .= $_ while ( <FILE> );
        close FILE;
    } else {
        warn( "Unable to find file for brand [$brand], returning empty" );
    }

    panic( "Empty html template from file $path/$brand" ) unless $txt;

    $txt =~ s/IMAGE_URL/$image_url/g;
    if ( -f "$path/$footer" ) {
        open( FILE, "$path/$footer" ) || panic( "Unable to open brand footer [$footer]" );
        $txt .= $_ while ( <FILE> );
        close FILE;
    } else {
        warn( "Unable to find file for brand footer [$footer], returning empty" );
    }

    return $txt;
}

sub get_cookie {
    my $token = shift || panic( "Missing token in get_cookie" );

    return $Cookies{ $token }->value() if ( $Cookies{ $token } );
    return undef;
}

sub add_cookie {
    for ( @_ ) {
        push @COOKIE_QUEUE, $_;
    }
}

sub new_html_page {
    return if $HTML_INIT_DONE;

    fix_source_links();

    $html =~ s/ogout/ogin/g if ( !$SESSION{ valid } );

    if ( @COOKIE_QUEUE ) {
        print header( -cookie => [ @COOKIE_QUEUE ], -expires => '-1M' );
    } else {
        print header( -expires => '-1M' );
    }

    $HTML_INIT_DONE = 1;
}

sub print_data_file {
    my $file = shift || panic( "Missing filename in print_data_file" );

    panic( "SECURITY: [$file] Attempt to load bad file" ) if $file =~ /!\w/;
    panic( "SECURITY: [$file] File does not exist" ) unless -f "$DATADIR/$file";

    print `cat $DATADIR/$file`;
}

sub fix_source_links {
    my $head;

    # Make the paths relative, it works the same
    $head = "/$CGI/$SCRIPT?module";

    my $extra = query_duplicate() || "";

    $html =~ s/index\.html/$head=home$extra/g;
    $html =~ s/userpage\.html/$head=userpage$extra/g;
    $html =~ s/search\.html/$head=search$extra/g;
    $html =~ s/addpatch\.html/$head=addpatch$extra/g;
    $html =~ s/logout\.html/$head=logout$extra/g;

}

sub query_duplicate {
    my $link = "";

    $link .= ( "&debug=" . param( 'debug' ) ) if ( param( 'debug' ) );
    $link .= ( "&next_module=" . param( 'next_module' ) )
      if param( 'next_module' );

    return $link;
}

sub page_select {
    my $name = shift || panic( "Missing name in page_select" );

    $html =~ s/CONTENT_INSERT/<P><H1>\u$name<\/H1><P>CONTENT_INSERT/g;
}

sub seperate_html {
    panic( "Missing HTML template" ) unless $html;

    $html =~ /^(.*)CONTENT_INSERT(.*)$/s;
    panic( "Unable to parse around CONTENT_INSERT" ) unless ( $1 && $2 );

    my ( $header, $footer ) = ( $1, $2 );

    return ( $header, $footer );
}

sub link_to_module {
    my ( $name, $link ) = @_;
    my $tmp = "<a href=\"";

    if ( http_is_encrypted() ) {
        $tmp .= "https://";
    } else {
        $tmp .= "http://";
    }

    $tmp .= $SERVER;
    $tmp .= "/$CGI/$SCRIPT";
    $tmp .= "?module=$name";

    $tmp .= query_duplicate();

    $tmp .= "\">$link</a>";

    return $tmp;
}

sub font_color {
    my ( $txt, $color ) = @_;

    return "<font color=\"$color\">$txt</font>";
}

1;
