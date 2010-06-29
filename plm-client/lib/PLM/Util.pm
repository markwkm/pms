# PLM Base Package
#
# Author: Nathan Dabney
#
# Base module for PLM class objects

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

package PLM::Util;


use strict;
#use Fcntl;
use Exporter;
use PLM::Util::Trace;

our( $LICENSE, $VERSION, @ISA, @EXPORT );

@ISA = qw( Exporter PLM::Util::Trace );

@EXPORT = qw(
  getLog
  getConfig
  getDBHandle
  call_trace
  panic
  db_echeck
);

$VERSION = "Patch Lifecycle Manager V1.3.0";
$LICENSE = "Copyright (c) 2002 Open Source Development Lab";
$LICENSE .= ", See COPYING for details";

=pod

=head1 NAME

PLM - Patch Lifecycle Manager, a single manager for various source types and tracking patches against them.

=head1 SYNOPSIS


=head1 DESCRIPTION

PLM - This is the object for tying logging, config and trace tools.

=head1 METHODS

=cut

use PLM::Util::Config;
use PLM::Util::Log;
use PLM::DB::Handle;
use PLM::DB::Gateway;


# Global vars :(
my $cfg_stamp;
my $cfg;
my $log;
my $dbh;


check_reload() if ( $cfg );

$log = getLog( "PLM::Util" ) unless ( $log );
$log->msg( 3, $VERSION );
$log->msg( 3, $LICENSE );


trace_configure( $log, $cfg );

=pod

=head2 module_list

  check_reload();

Internal function which checks if config has changed.

=cut

sub check_reload {
    my @s = stat "/etc/plm.cfg";
    $cfg_stamp = 0 unless ( $cfg_stamp );

    return if ( $cfg_stamp == $s[ 9 ] );

    $cfg = "";

    $cfg_stamp = $s[ 9 ];
}

sub getLog {
    my $id = shift || "FIXME";
    if ( !$cfg ) { $cfg = getConfig() }

    my $filename = $cfg->get( "log_file" )   || "/var/log/plm/plm.log";
    my $target   = $cfg->get( "log_target" ) || "file";
    my $level    = 0;

    if ( defined $cfg->get( "log_level" ) ) {
        $level = $cfg->get( "log_level" );
    }

    if ( defined $cfg->get( $id . "_log_level" ) ) {
        $level = $cfg->get( $id . "_log_level" );
    }

    my $newlog = new PLM::Util::Log(
        {
            filename => $filename,
            target   => $target,
            level    => $level,
            id       => $id
        }
    );

    return $newlog;
}

sub getDBHandle {
    if ( $dbh ) { return $dbh }
    if ( !$cfg ) { $cfg = getConfig() }

    $dbh = new PLM::DB::Handle(
        {
            dsn  => $cfg->get( "dsn" ),
            user => $cfg->get( "dsnuser" ),
            pass => $cfg->get( "dsnpass" )
        }
    );

    $dbh->nameSpace( $cfg->get( "namespace" ) );

    $dbh->connect();
    return $dbh;
}

sub getConfig {
    my $passed_config=shift;
    if ( defined $cfg and ! $passed_config ) {
        return $cfg;
    }
    
    my $choice = 0;
 
    #  Allow to pass cfg name.
    if ( $passed_config ){
        if ( -r "$passed_config" ) {
            $choice = $passed_config;
        } else {
            return 0; 
        }
    }

    if ( !$choice && -r "~/.plm.cfg" ) {
        $choice = "~/.plm.cfg";
    }

    if ( !$choice && -r "/etc/plm/plm.cfg" ) {
        $choice = "/etc/plm/plm.cfg";
    }

    if ( !$choice && -r "/etc/plm.cfg" ) {
        $choice = "/etc/plm.cfg";
    }

    if ( !$choice ) {
        if ( defined $log ) {

            #$log->msg( 0, "ERROR unable to find a readable config file" );
        } else {
            print STDERR "ERROR unable to find a readable config file\n";

            my $t = localtime( time() );
            chomp $t;

            open( FILE, ">>/tmp/PLM-PANIC" );
            print FILE "$t - ERROR unable to find a readable config file\n";
            close FILE;
        }
        exit 1;
    }

    my $local_cfg = new PLM::Util::Config( $choice );
    if (! $passed_config){
        # Set the global one
        $cfg = $local_cfg;
    }
    return $local_cfg;
}

END {
}

1;

