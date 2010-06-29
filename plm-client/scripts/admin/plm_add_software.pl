#!/usr/bin/perl 

# start podify

=head1 NAME

plm_add_software.pl

=head1 SYNOPSIS

This script allows an administrator of PLM to add a software definition to
the database.

=head1 DESCRIPTION

The SYNOPSIS covers it.

=head1 OPTIONS

=item
B<--software> I<name>

=head1 EXAMPLES

plm_add_software.pl --software linux

=head1 AUTHOR

Mark Wong <markw@osdl.org>

=cut

# end podify

use strict;
use DBI;
use PLM::Util;
use Getopt::Long;

my $config = getConfig();

my $dsn     = $config->get( "dsn" );
my $dsnuser = $config->get( "dsnuser" );
my $dsnpass = $config->get( "dsnpass" );
my $dbh     = DBI->connect( $dsn, $dsnuser, $dsnpass );

my $sql;
my $rc;

my $software;

GetOptions( "software=s" => \$software );

unless ( $software ) {
    print "usage: plm_add_software.pl --software <name>\n";
    exit 1;
}

my $time = time();
$sql =
  "INSERT INTO plm_software (rsf, created, name)\n"
  . "VALUES (1, $time, '$software' )";

print "SQL to execute:\n";
print "$sql\n";
print "\n";
$rc = $dbh->do( $sql );

if ( $rc == 1 ) { print "Successfully added software '$software' to PLM.\n"; }
else { print "Could not add software '$software' to PLM.\n"; }
