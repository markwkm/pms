#!/usr/bin/perl

# start podify

=head1 NAME

plm_request_filter.pl

=head1 SYNOPSIS

Request a filter for a specific patch.

=head1 DESCRIPTION

PLM automatically requests filters for a patch only when it is added to the
system.  This script is intended to be used to request filters for a patch when
the filter has been added to the system after a patch has.

=head1 OPTIONS

=item
B<--pid> I<patch_id>
B<--fid> I<filter_id>
B<--uid> I<user_id>

=head1 EXAMPLES

plm_request_filter.pl --pid 1 --fid 1 --uid 1

=head1 NOTES

The user id isn't all that important and any valid user id should be sufficient.

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

my $url = $config->get( "plm_http" );

my $sql;
my $sth;
my $rc;

my $data = "";
my $response;
my $protocol;

my $patch_id;
my $filter_id;
my $latest;
my $help;
my $user_id;

GetOptions(
            "fid=i" => \$filter_id,
            "help" => \$help,
            "latest" => \$latest,
            "pid=i" => \$patch_id,
            "uid=i" => \$user_id
);

if ( $help ) {
    print "usage: plm_request_filter.pl --pid <patch_id> --fid <filter_id> --uid <user_id>\n";
    exit 1;
}

unless ( $patch_id ) {
    print "patch id me, yo!\n";
    exit 1;
}

unless ( $filter_id ) {
    print "filter id me, yo!\n";
    exit 1;
}

unless ( $user_id ) {
    print "give me a user id because i'm not going to look one up\n";
    exit 1;
}

# Check to make sure this filter is valid for the patch.

$sql = "SELECT pf.name, pp.name, ps.name "
     . "FROM plm_filter pf, plm_patch pp, plm_filter_request pfr, "
     . "     plm_software ps "
     . "WHERE pp.id = $patch_id "
     . "  AND pf.id = $filter_id "
     . "  AND (pp.plm_software_id = pf.plm_software_id "
     . "       OR pf.plm_software_id = 0) ";
$sth = $dbh->prepare( $sql );
$sth->execute();
my @row = $sth->fetchrow_array;
unless ( @row ) {
    print "you can't request filter '$filter_id' for patch $patch_id, you turkey\n";
    print "and i'm not going to look up what filter you tried to request either!\n";
    exit 1;
}

# Check to see if this filter is already requested.

$sql = "SELECT id "
     . "FROM plm_filter_request "
     . "WHERE plm_patch_id = $patch_id "
     . "  AND plm_filter_id = $filter_id";
$sth = $dbh->prepare( $sql );
$sth->execute();
if ( $DBI::rows ) {
    print "this filter has already been requested, you turkey\n";
    exit 1;
}

# Now it's ok to request this filter.

print "Requesting $row[ 0 ] for $row[ 1 ]\n";

my $time = time();
$sql = "INSERT INTO plm_filter_request(created, modified, accessed, "
     . "                               plm_filter_id, plm_patch_id, "
     . "                               plm_user_id, "
     . "                               plm_filter_request_state_id, priority ) "
     . "VALUES ($time, $time, $time, $filter_id, $patch_id, $user_id, "
     . "        $state_queued, 1)";
$dbh->do( $sql );

print "good luck, i hope it requested properly\n"
