#!/usr/bin/perl

# start podify

=head1 NAME

plm_filter_check.pl

=head1 SYNOPSIS

This script lists PLM patches and filters that have not been requested for them.

=head1 DESCRIPTION

If only I could get an equivalent NOT EXISTS query to work on MySQL.  This
script runs really slow.

=head1 EXAMPLES

plm_filter_check.pl

=head1 AUTHOR

Mark Wong <markw@osdl.org>

=cut

# end podify

use strict;
use DBI;
use PLM::Util;

my $config = getConfig();

my $state_queued    = 1;
my $state_pending   = 2;
my $state_running   = 3;
my $state_completed = 4;
my $state_failed    = 6;

my $dsn     = $config->get( "dsn" );
my $dsnuser = $config->get( "dsnuser" );
my $dsnpass = $config->get( "dsnpass" );
my $dbh     = DBI->connect( $dsn, $dsnuser, $dsnpass );

my $sql;
my $sth;
my @row;

# If only I could figure out how to do division in MySQL...
#The queries:
#
#SELECT * FROM table1 WHERE id NOT IN (SELECT id FROM table2);
#SELECT * FROM table1 WHERE NOT EXISTS (SELECT id FROM table2
#                                       WHERE table1.id=table2.id);
#
#Can be rewritten as:
#
#SELECT table1.* FROM table1 LEFT JOIN table2 ON table1.id=table2.id
#                                       WHERE table2.id IS NULL;

# I guess I'll have to do this the stupid slow way...

my @patch_id = ();
$sql =
  "SELECT id, plm_software_id, name "
  . "FROM plm_patch "
  . "ORDER BY id DESC ";
$sth = $dbh->prepare( $sql );
$sth->execute();
@row = $sth->fetchrow_array;
while ( @row ) {
    push @patch_id, join( ":", @row );
    @row = $sth->fetchrow_array;
}

print "Patch ID, Patch Name, Filter ID, Filter Name\n";
for ( @patch_id ) {
    my @data = split /:/, $_;
    $sql =
      "SELECT pf.id, pfr.plm_patch_id, pf.name "
      . "FROM plm_filter pf "
      . "LEFT JOIN plm_filter_request pfr "
      . "ON pf.id = pfr.plm_filter_id "
      . "AND pfr.plm_patch_id = $data[ 0 ] "
      . "WHERE pfr.plm_patch_id IS NULL "
      . "  AND pf.plm_software_id IN (0, $data[ 1 ]) ";
    $sth = $dbh->prepare( $sql );
    $sth->execute();
    if ( $DBI::rows ) {
        @row = $sth->fetchrow_array;
        while ( @row ) {
            print "$data[ 0 ], $data[ 2 ], $row[ 0 ], $row[ 2 ]\n";
            @row = $sth->fetchrow_array;
        }
    }
}
