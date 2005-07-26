#!/usr/bin/perl

# start podify

=head1 NAME

plm_reset_request.pl

=head1 SYNOPSIS

Reset the state of a filter request to queued.

=head1 DESCRIPTION

This is intended as a simple tool to reset a particular filter request for a
patch or all filter requests for a patch to the queued state.

=head1 OPTIONS

=item
B<--pid> I<patch_id>
B<--fid> I<filter_id>

=head1 EXAMPLES

Reset all filters for a patch id:

plm_reset_request.pl --pid 1

=head1 AUTHOR

Mark Wong <markw@osdl.org>

=cut

# end podify

use strict;
use DBI; 
use PLM::Util;
use Getopt::Long;

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
my $patch_id;
my $filter_id;
my $rc;

GetOptions(
            "pid=s" => \$patch_id,
            "fid=i" => \$filter_id
);

unless ( $patch_id ) {
    print "usage: plm_reset_request.pl --pid <patch_id> [--fid <filter_id>]\n";
    exit 1;
}

$sql =
  "UPDATE plm_filter_request "
  . "SET plm_filter_request_state_id = $state_queued "
  . "WHERE plm_filter_request_state_id IN ($state_completed, $state_failed) ";
if ( $patch_id ) {
    $sql .= "  AND plm_patch_id = $patch_id";
}
if ( $filter_id ) {
    $sql .= "  AND plm_filter_id = $filter_id";
}
print "$sql\n";
$rc = $dbh->do( $sql );
print "$rc\n";
