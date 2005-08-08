#!/usr/bin/perl -w 

# start podify

=head1 NAME

plm_status.pl

=head1 SYNOPSIS

Display the current state of the supervisors in PLM.

=head1 DESCRIPTION

The SYNOPSIS covers it.

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

$sql =
  "SELECT pfrs.code, count(pfr.id) "
  . "FROM plm_filter_request pfr, plm_filter_request_state pfrs "
  . "WHERE pfr.plm_filter_request_state_id = pfrs.id "
  . "GROUP BY pfrs.id "
  . "ORDER BY pfrs.id ";
$sth = $dbh->prepare( $sql );
$sth->execute();

@row = $sth->fetchrow_array;
printf( "%-9s %-5s\n", "State", "Count" );
printf( "%9s %5s\n", "---------", "-----" );
while ( @row ) {
    printf( "%9s %5s\n", $row[ 0 ], $row[ 1 ] );
    @row = $sth->fetchrow_array;
}

$sql =
  "SELECT pp.id, pp.name, pf.name, pfr.started, pfrs.code "
  . "FROM plm_filter_request pfr, plm_patch pp, plm_filter pf, "
  . "     plm_filter_request_state pfrs "
  . "WHERE pfr.plm_filter_request_state_id IN ( $state_pending, "
  . "                                           $state_running) "
  . "  AND pp.id = pfr.plm_patch_id "
  . "  AND pf.id = pfr.plm_filter_id "
  . "  AND pfr.plm_filter_request_state_id = pfrs.id "
  . "ORDER BY pfr.plm_filter_request_state_id, pp.id ";
$sth = $dbh->prepare( $sql );
$sth->execute();

@row = $sth->fetchrow_array;
print "\nRunning Tests (does not catch supervisors running duplicate requests)\n";
printf( "%-8s %-25s %-20s %-8s %-12s\n", "Patch ID", "Name", "Filter",
  "State", "Elapsed Time" );
printf( "%-8s %-25s %-20s %-8s %s\n", "--------", "-------------------------",
  "--------------------", "-------", "------------" );
while ( @row ) {
    printf( "%8s %-25s %-20s %-9s %6.1f min\n", $row[ 0 ], $row[ 1 ], $row[ 2 ],
      $row[ 4 ], ( time() - $row[ 3 ] ) / 60  );
    @row = $sth->fetchrow_array;
}
