#!/usr/bin/perl

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
  "SELECT pfr.plm_patch_id, pf.name, pfr.result, pfr.result_detail, "
  . "       pfr.plm_filter_id "
  . "FROM plm_filter_request pfr, plm_filter pf "
  . "WHERE pfr.plm_filter_request_state_id = $state_completed "
  . "  AND pf.id = plm_filter_id "
  . "ORDER BY pfr.id, pfr.plm_filter_id";
$sth = $dbh->prepare( $sql );
$sth->execute();
@row = $sth->fetchrow_array;

while ( @row ) {
    print "[$row[ 0 ]] $row[ 1 ]($row[ 4 ]): $row[ 2 ] - $row[ 3 ]\n";
    @row = $sth->fetchrow_array;
}
