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

#use PLM::Util::Config;
use PLM::Util::Log;
use PLM::Util::Trace;

use SOAP::Lite;
use SOAP::MIME;
use MIME::Entity;

require Exporter;

@ISA = qw( Exporter );

@EXPORT = qw( ASP );

BEGIN { }


sub new {
    my ( $pkg, $cfg ) = @_;
    my $http = $cfg->get( "PLMClient_proxy" );
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

    trace_configure( $log, $cfg );    # What is this ?

    $obj= { 
         proxy => $http,
         uri => $default_uri,
         log => $log
    };
    return bless $obj, $pkg;
}


sub ASP {
    my ( $obj, $command, @args ) = @_;

    my $soap;
    my $ent;
    my @parts=();
    if ($command =~ m/^patch_add$/){
        $ent = attach_content($args[3]);
        @args2=($args[0], $args[1], $args[2]);
    }elsif ($command =~ m/^submit_result$/){
        $ent = attach_content($args[2]);
        @args2=($args[0], $args[1]);
    } else {
        $ent = attach_content("");
        @args2=@args;
    }
    push @parts, $ent;

    eval { 
        $soap = SOAP::Lite->readable(1)->uri( $obj->{'uri'}, timeout=>600 )->parts(@parts)->proxy( $obj->{'proxy'} )->$command( @args2 );
        #$soap = SOAP::Lite->uri( $obj->{'uri'} )->proxy( $obj->{'proxy'}, timeout=>1200 )->$command( @args );
        if ( $soap->fault ) {
            print STDERR "SOAP::Lite fault message:\n";
            print STDERR $soap->faultcode . " " . $soap->faultstring . "\n";
            return undef;
        }
    };

    if ( $@ ) {
        print STDERR "SOAP::Lite -> $@\n";
        return undef;
    }

    my $ret = $soap->result();
    $ret = '' unless ( defined $ret );

    # Some clients apparently break the < character?
    $ret =~ s/&lt;/</g;

    return $ret;

}

sub attach_content{
    my $content=shift;
    my $ent;
    # If SOAP encodes it is slower than PLM doing the encoding.
    $ent = MIME::Entity->build(Type =>  'text/plain',
                                  Encoding    => "binary",
                                  Data        => $content);
    return $ent;

}


END { }

1;
