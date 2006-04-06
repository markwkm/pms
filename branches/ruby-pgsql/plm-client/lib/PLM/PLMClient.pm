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
    my $wsdl = $cfg->get( "wsdl" );
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
         service => $service,
         wsdl => $wsdl,
         log => $log
    };

    return bless $obj, $pkg;
}

sub ASP {
    my ( $obj, $command, @args ) = @_;
    return $obj->{'service'}->$command( @args );
}

END { }

1;
