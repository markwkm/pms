#
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

package PLM::Util::TempFile;

require 5.005_62;

use strict;
use Fcntl;
use POSIX qw(tmpnam);
use Exporter;

our( $LICENSE, $VERSION, @ISA, @EXPORT );

@ISA = qw( Exporter );

@EXPORT = qw( 
  getTempDir
  createTempFile
  getTempFileHandle
  endScript
);

=pod

=head1 NAME

PLM - Patch Lifecycle Manager, a single manager for various source types and tracking patches against them.

=head1 SYNOPSIS


=head1 DESCRIPTION

PLM - This is the object for tying together accessing database tables of its child objects, configuration, logging and temporary file access.

=head1 METHODS

=cut

my $temp_dir   = undef;
my @temp_files = ();


# To ensure a DESTROY call later (blessed when a temp_dir is created)
my $self = undef;


=pod

=head2 module_list

  check_reload();

Internal function which checks if config has changed.

=cut

sub getTempDir {
    if ( defined $temp_dir ) { return $temp_dir }

    unless ( $self ) {
        $self = {};
        bless $self;
    }

    my $orig = "PLM-";
    my $name = $orig . int( rand 100000 ) . "-" . int( rand 100000 );

    while ( -d "/tmp/$name" ) {
        $name = $orig . int( rand 100000 ) . "-" . int( rand 100000 );
    }

    $temp_dir = "/tmp/$name";

    mkdir $temp_dir, 0770;
    return $temp_dir;
}

sub createTempFile {
    my $orig = shift || "PLM";
    my $dir = getTempDir();

    $orig .= "-";
    my $name = $orig . int( rand 100000 ) . "-" . int( rand 100000 );

    while ( -e "$dir/$name" ) {
        $name = $orig . int( rand 100000 ) . "-" . int( rand 100000 );
    }

    return "$dir/$name";
}

sub getTempFileHandle {
    my $name;

    local *FH;

    do { $name = tmpnam() }
      until sysopen( FH, $name, O_RDWR | O_CREAT | O_EXCL );

    push @temp_files, $name;

    return ( *FH, $name );
}

END {

    # print "Cleaning up: $temp_dir\n";
    system "rm -rf $temp_dir" if ( $temp_dir );

    # Remove any temp files created by this run
    for ( @temp_files ) {
        system "rm -f $_";
    }
}

1;

