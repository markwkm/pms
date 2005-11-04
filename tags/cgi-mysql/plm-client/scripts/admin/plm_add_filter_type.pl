#!/usr/bin/perl

# start podify

=head1 NAME

plm_add_filter_type.pl

=head1 SYNOPSIS

This script allows an administrator of PLM to add a filter type definition to
the database.

=head1 DESCRIPTION

The 'code' is really just a name or identifier for the filter type.

=head1 OPTIONS

=item
B<--code> I<code>

=head1 EXAMPLES

plm_add_filter_type.pl --code ia32

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

my $code;

GetOptions( "code=s" => \$code );

unless ( $code ) {
    print "usage: plm_add_filter_type.pl --code <code>\n";
    exit 1;
}

my $time = time();
$sql =
  "INSERT INTO plm_filter_type (rsf, created, code)\n"
  . "VALUES (1, $time, '$code')";

print "SQL to execute:\n";
print "$sql\n";
print "\n";
$rc = $dbh->do( $sql );

if ( $rc == 1 ) { print "Successfully added filter type '$code' to PLM.\n"; }
else { print "Could not add filter type '$code' to PLM.\n"; }
