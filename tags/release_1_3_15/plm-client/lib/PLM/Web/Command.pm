#
# perl module for supporting the requirements of a web application
# 

package PLM::Web::Command;

@ISA    = qw( Exporter );
@EXPORT =
  qw( content_build_info );

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

use PLM::RPC::CommandSet;

my $log = getLog( "PLM::Web::Command" );

sub content_build_info {
    my $software = param( 'software' );
    my $patch_id = param( 'patch_id' );
    my $command_type = param( 'command_type' ) || "build";

    new_html_page();
    page_select( "buildinfo" );

    my ( $header, $footer ) = seperate_html();

    print $header;

    print "<H2>Type:  $software $command_type</H2>\n";

    # print h4( "Patch Information Report" );
    print "<p>";

    # Get the Patch XML parsed into our local object
    my $ref = PLM::RPC::CommandSet->command_set_get_content( $software, $patch_id, $command_type );
    panic( "Error retrieving patch details" ) unless ( ref $ref );

    _print_command_info( $ref );

    webapp_debug() if ( param( 'debug' ) && param( 'debug' ) eq 'on' );
    print $footer;

    exit( 0 );
}

sub _print_command_info{
    my ($ref)=shift;

    my $row;
    if ($#{$ref} == -1 ){
        print "<H3>No Commands Specified.</H3>\n"
    }
    print "<PRE>\n";
    foreach $row (@{$ref}){
        print "$row->{command}\n";
    }
    print '</PRE>' . "\n";
}


1;
