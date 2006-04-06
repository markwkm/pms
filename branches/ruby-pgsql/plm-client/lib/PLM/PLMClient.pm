# Copyright (C) 2002 Open Source Development Lab 
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

package PLM::PLMClient;

use PLM::Util::Log;
use PLM::Util::Trace;

use SOAP::Lite;

require Exporter;

@ISA = qw( Exporter );

@EXPORT = qw( ASP );

BEGIN { }


sub new {
    my ( $pkg, $cfg ) = @_;
    my $http = $cfg->get( "PLMClient_proxy" );
    my $wsdl = $cfg->get( "wsdl" );
    my $client_base_url = $cfg->get( "PLMClient_base_url");
    if ( $client_base_url && $http){
        $http = $client_base_url . $http;
    }
    $http ||= $cfg->get( "plm_http" ) . "/plm_server.pl";
    my $default_uri   = $cfg->get( "PLMClient_uri" );  # Use this for SOAP
    my $log = new PLM::Util::Log(
      {
        filename => $cfg->get( "log_file" ),
        target   => $cfg->get( "log_target" ),
        level    => $cfg->get( "log_level" ),
        id       => "PLMClient"
      }
    );
    my $service = SOAP::Lite -> service($wsdl);

    trace_configure( $log, $cfg );    # What is this ?

    $obj= { 
         proxy => $http,
         service => $service,
         uri => $default_uri,
         log => $log
    };

    return bless $obj, $pkg;
}

sub ASP {
    my ( $obj, $command, @args ) = @_;
    my $ret;
    my $service = $obj->{'service'};

    if ( $command eq 'get_applies_tree' ) {
        $ret = $service->GetAppliesTree( @args );
    } elsif ( $command eq 'get_patch' ) {
        $ret = $service->GetPatch( @args );
    } elsif ( $command eq 'get_request' ) {
        $ret = $service->GetRequest( @args );
    } elsif ( $command eq 'patch_get_list' ) {
        $ret = $service->PatchGetList( @args );
    } elsif ( $command eq 'patch_get_value' ) {
        $ret = $service->PatchGetValue( @args );
    } elsif ( $command eq 'set_filter_request_state' ) {
        $ret = $service->SetFilterRequestState( @args );
    } elsif ( $command eq 'software_verify' ) {
        $ret = $service->SoftwareVerify( @args );
    } elsif ( $command eq 'source_get' ) {
        $ret = $service->SourceGet( @args );
    } elsif ( $command eq 'submit_result' ) {
        $ret = $service->SubmitResult( @args );
    } elsif ( $command eq 'get_name' ) {
        $ret = $service->GetName( @args );
    } else {
        panic('undefined ASP call');
    }

    return $ret;
}

END { }

1;
