#
# perl module for supporting the requirements of a web application
# 

package PLM::Web::Addpatch;

@ISA = qw( Exporter );

@EXPORT = qw(content_addpatch content_addpatch_submission);

use strict;
use Exporter;
use CGI qw/-private_tempfiles :standard/;
use CGI::Cookie;
use CGI::Carp qw(fatalsToBrowser);
use PLM::Object::Patch;
use PLM::PLM::Patch;
use PLM::Util;

use PLM::Web::General;
use PLM::Web::Session;
use PLM::Web::User;
use PLM::Web::Patch;
use PLM::Web::Software;

use PLM::RPC::Patch;

#
# Print a row of the form table
#

sub form_row {
    my ( $name, $field ) = @_;

    #print "<tr><td width=90>$name";
    #print "</td><td width=100>$field";
    #print "</td></tr>\n";
    print "<tr><td>$name</td><td>$field</td></tr>\n";
}

#
# MODULE ( addpatch )
# 

sub content_addpatch {
    my $cfg = shift;
    Delete( 'module' );

    new_html_page();
    page_select( "addpatch" );

    my ( $header, $footer ) = seperate_html();

    print $header;

    print h3( "Adding a patch as user [ $SESSION{username} ]" ), p();

    print start_multipart_form();

    print '<table width=$TABLE_WIDTH border=0>';

    form_row(
              "Patch Name:",
              textfield(
                         -name      => 'patch_name',
                         -size      => '20',
                         -maxlength => '254'
              )
    );
    form_row(
              "Patch Version:",
              textfield(
                         -name      => 'patch_version',
                         -size      => '6',
                         -maxlength => '254'
              )
    );

    form_row( "File to Upload:", filefield( -name => 'content', -size => 30 ) );

    my @repos = software_list();
    if ( @repos > 1 ) {
        form_line( "Software Repository",
		popup_menu( -name=>'repo_name', -values=>[ @repos ], -default=>software_default() ) );
    }

    print "</table><p>";
    print
"The patch file can be in plaintext, gzip or bzip2 format.  [autodetected]<br>";
    print "<P>";

    print h3(
        "Fill in the ID or Name of the dependent patch or dependent baseline" ),
      p();
    print '<table width=$TABLE_WIDTH border=0>';

    form_row(
              "Patch ID to apply to:",
              textfield(
                         -name      => 'applies_id',
                         -size      => '5',
                         -maxlength => '254'
              )
    );

    form_row(
              "Patch Name to apply to:",
              textfield(
                         -name      => 'applies_name',
                         -size      => '20',
                         -maxlength => '254'
              )
    );

    form_row(
            "Apply patch in reverse",
            checkbox( -name      => 'reverse',
                      -checked=>0,
                      -value=>'1',
                      -label=>''
            )
    );

    print '</table><p>';
    print
"NOTE: Official baseline versions are in the system with placeholder patch ID's<p>";
    print "If you can't remember the name of a patch, ";
    my $cgi = $cfg->get( 'cgi_bin' ) || "cgi-bin";
    print
"you can <a href=\"/${cgi}/plm?module=search\" target=\"new\">search</a> for it.";
    print "<P>";

    print hidden( -name => 'debug', -value => param( 'debug' ) )
      if param( 'debug' );
    print hidden( -name => 'module', -value => 'addpatch_submission' );

    print submit( -value => 'Add Patch' );

    print endform();

    webapp_debug() if ( param( 'debug' ) && param( 'debug' ) eq 'on' );
    print $footer;

    exit 0;
}

# 
# Prints a submission error message and exits
#

sub _panic {
    my $txt = shift || "Unknown Error";

    new_html_page();
    page_select( "addpatch" );

    my ( $header, $footer ) = seperate_html();

    print $header;

    print h2( "Error in patch submission:" ), p();
    print h3( $txt ), p();
    print "Please try again.";

    webapp_debug() if ( param( 'debug' ) && param( 'debug' ) eq 'on' );
    print $footer;

    exit 0;
    #panic( $txt );
}

#
# The patch wen tin OK, print a report
#
sub report_add_ok {
    my $id = shift;

    new_html_page();
    page_select( "addpatch" );

    my ( $header, $footer ) = seperate_html();

    print $header;

    print h3( "Patch add OK as Patch #$id" );
    print "<p>You can now go to the ";
    print "<a href=\"http://www.osdl.org/stp/\">Scalable Test Platform</a>";
    print " to request tests against this Patch ID#.<p>";

    webapp_debug() if ( param( 'debug' ) && param( 'debug' ) eq 'on' );
    print $footer;

    exit( 0 );
}

#
# Resolve the applies_name to a applies_id or leave the applies_id alone
#
# Requires a calling syntax:
#
#     resolve_applies( $applies_id, $applies_name );
sub resolve_applies {
    my ( $id, $name ) = @_;

    return $id if ( $id );

    my @data = PLM::RPC::Patch->patch_find_by_name( $name );
    if ( $data[ 0 ] ) {
        return $data[ 0 ];
    }

    # The user should never see this
    _panic(
          "Unable to resolve the applies patch name, possible internal error" );
}

#
# Set the applies 
#
#sub set_applies {
#    my $patch_id   = shift;
#    my $applies_id = shift;
#
#    PLM::RPC::Patch->patch_add_depend( user_creds(), "apply", $patch_id, $applies_id );
#}

#
# Verify the submission is of the type we expect
#

sub verify_submission {
    my ( $name, $applies_id, $applies_name, $file ) = @_;

    # Validate the *** NAME ***
    $name || _panic( "Missing the name of the patch to add" );

    my @data = PLM::RPC::Patch->patch_find_by_name( $name );
    if ( $data[ 0 ] ) {
        _panic( "A patch already exists with that name" );
    }

    # Validate the *** APPLIES ID or NAME ***
    ( $applies_id || $applies_name )
      || _panic( "Missing both the Applies ID and Applies Name" );

    if ( $applies_name ) {
        my @data = PLM::RPC::Patch->patch_find_by_name( $applies_name );
        if ( !$data[ 0 ] ) {
            _panic( "Patch '$applies_name' does not seem to exist" );
        }
    }

    # FIXME Add validation check of the ID if given

    # Validate the *** CONTENT ***
    if ( !$file && cgi_error() ) {
        print header( -status => cgi_error() );
        webapp_debug() if ( param( 'debug' ) && param( 'debug' ) eq 'on' );
        exit 0;
    }

    if ( !$file ) {
        _panic( "Missing uploaded file" );
    }
}

#
# MODULE ( content_addpatch_submission )
#

sub content_addpatch_submission {
    my $patch        = new PLM::Object::Patch();
    my $name         = param( 'patch_name' );
    my $version      = param( 'patch_version' );
    my $applies_id   = param( 'applies_id' ) || "";
    my $applies_name = param( 'applies_name' ) || "";
    my $reverse      = param( 'reverse' ) || "0";
    my $file         = upload( 'content' );
    my $repo         = find_software_id( $applies_id, $applies_name );
    my $repo_intended = param( 'repo_name' ) || "linux";    # set linux as the default

    if ( $version ) {
        unless ( $version =~ /(_|-|\.)\d+/ ) {
            $version = "-" . $version;
        }
        $name .= $version;
    }

    verify_submission( $name, $applies_id, $applies_name, $file );

    # repo_intended is the name, repo is the id.
    verify_software( $repo_intended, $repo );

    my $content;
    while ( <$file> ) {
        $content .= $_;
    }
    if ( !$content ) { _panic( "Error slurping patch content" ) }

    $patch->setValue( "name",            $name );
    $patch->setValue( "plm_user_id",     user_get_id() );
    $patch->setValue( "content",         $content );
    $patch->setValue( "content_format",  "" );
    $patch->setValue( "plm_software_id", $repo );
    $patch->setValue( "reverse", $reverse );
    $applies_id = resolve_applies( $applies_id, $applies_name );
    $patch->setValue( "plm_applies_id", $applies_id );

    #my $xml = $patch->toString();

    my $id = PLM::RPC::Patch->patch_add( user_creds(), $patch );

    if ( !$id ) {
        _panic(
            "Problem adding patch.  You might want to contact the admins.<p>"
            . "It's possible your patch name conflicts with a reserved one (standard trees...)"
        );
    }

    #set_applies( $id, resolve_applies( $applies_id, $applies_name ) );
    report_add_ok( $id );
}

sub find_software_id {
    my ( $id, $name ) = @_;
    my $patch = new PLM::PLM::Patch();

    unless ( $id ) {
        my $ref = $patch->search_sql( { name => $name } );

        return 0 unless ( $ref );

        $id = ${ $ref }[ 0 ]{ id };
    }

    panic( "Unable to find the parent patch by name [$name]" ) unless ( $id );

    $patch->load( $id );

    return $patch->getValue( "plm_software_id" );
}

#
# Prints out a line of the form in correct table format
# Copied from Patch.pm
#
sub form_line {
    my ( $name, $field ) = @_;

    print "<tr>";
    print "<td width=150>$name</td>";
    print "<td>$field</td>";
    print "</tr>";
}

sub verify_software {
    use PLM::PLM::Software;

    my $repo_name = shift;
    my $repo_id1;
    my $repo_id2 = shift;

    my $repo_obj = new PLM::PLM::Software();
    $repo_id1 = $repo_obj->verify($repo_name);
    if ( $repo_id1 != $repo_id2 ) {
        _panic("The software repository you have chosen does not match"
               . " that of the applies patch.  Check your input.");
    }
    return;         #   returns only if there is a match
}    

1;
