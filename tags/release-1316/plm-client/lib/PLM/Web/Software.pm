#
# perl module for supporting the requirements of a web application
# 

package PLM::Web::Software;

@ISA = qw( Exporter );

@EXPORT = qw( software_list software_default software_resolve content_software_info );

use strict;
use Exporter;
use CGI qw/:standard/;
use CGI::Cookie;
use CGI::Carp qw(fatalsToBrowser);
use PLM::Util;
use PLM::PLM::Software;
use PLM::PLM;

use PLM::Web::General;
use PLM::Web::Session;

use PLM::RPC::Software;

my $software = undef;

#
# Create the XML object for $software
#
sub software_init {
    return if $software;

    $software = new PLM::PLM();

    $software->{ data }        = {};
    $software->{ elementName } = "software";
    $software->addElement( "id",      "" );
    $software->addElement( "created", "" );
    $software->addElement( "name",    "" );
}

#
# Return an array of the available software repositories
#
sub software_list {

    my $object = new PLM::PLM::Software();

    my $result = $object->search_sql('plm_software', { rsf => 1 });
    # Pull out all the names
    my @names;
    my $software;
    foreach $software (@{$result}){
        push @names,${$software}{name};
    }

    return ( @names );

}

# 
# Return the default repository for the installation
#
sub software_default {

    # FIXME

    return "linux";
}

#
# Resolve the software name to a software ID
#
sub software_resolve {
    my $name = shift;

    my @data = PLM::RPC::Software->software_verify( $name );

    return 0 unless ( @data );

    return $data[ 0 ];
}

sub content_software_info {
    my $software_name = param( 'software' );

    new_html_page();
    page_select( "softwareinfo" );

    my ( $header, $footer ) = seperate_html();

    print $header;

    print "<H2>$software_name</H2>\n";

    print "<p>";

    my $object = new PLM::PLM::Software();
    my $result = $object->search_sql('plm_software', { name  => $software_name });
    panic( "Error retrieving software details for $software_name" ) unless ( ref $result );

    print( ${$result}[0]->{'description'} );


    webapp_debug() if ( param( 'debug' ) && param( 'debug' ) eq 'on' );
    print $footer;

    exit( 0 );
}

1;
