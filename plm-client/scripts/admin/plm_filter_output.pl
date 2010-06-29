#!/usr/bin/perl

# start podify

=head1 NAME

plm_filter_output.pl

=head1 SYNOPSIS

Get the output result of a filter.

=head1 DESCRIPTION

This script queries PLM directly through the database and the Web interface to
get the filter results.  So make sure plm.cfg is configured correctly on the
system you run this on.

=head1 OPTIONS

=item
B<--pid> I<patch_id>
B<--fid> I<filter_id>
B<--latest>
B<--reverse>
B<--verbose>
B<--help>

=head1 EXAMPLES

Get a brief list of all results in reverse chronological order:

plm_filter_output.pl --reverse

Get a verbose listing for all filters for patch 2 in natural order:

plm_filter_output.pl --pid 2 --verbose

=head1 AUTHOR

Mark Wong <markw@osdl.org>

=cut

# end podify

use strict;
use DBI;
use PLM::Util;
use Getopt::Long;
use LWP::UserAgent;
use HTTP::Request;
use HTML::LinkExtor;
use URI::URL;

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
my $verbose;
my $reverse;
my $latest;
my $help;

GetOptions(
            "fid=i" => \$filter_id,
            "help" => \$help,
            "latest" => \$latest,
            "pid=s" => \$patch_id,
            "reverse" => \$reverse,
            "verbose" => \$verbose
);

if ( $help ) {
    print "usage: plm_filter_output.pl [--pid <patch id>] [--fid <filter id>]\n"
        . "                            [--latest] [--reverse] [--verbose]\n"
        . "                            [--help]\n";

    exit 1;
}

$sql =
  "SELECT pfr.plm_patch_id, pf.name, pfr.id, pfr.result, "
  . "     pfr.result_detail, pfr.plm_filter_id "
  . "FROM plm_filter_request pfr, plm_filter pf "
  . "WHERE plm_filter_request_state_id IN ($state_completed, $state_failed) "
  . "  AND pf.id = pfr.plm_filter_id ";

if ( $patch_id ) {
    $sql .= "  AND plm_patch_id = $patch_id ";
}
if ( $filter_id ) {
    $sql .= "  AND plm_filter_id = $filter_id ";
}

if ( $latest ) {
    $sql .= "ORDER BY pfr.completed DESC ";
} else {
    if ( $reverse ) {
        $sql .= "ORDER BY pfr.plm_patch_id DESC, ";
    } else {
        $sql .= "ORDER BY pfr.plm_patch_id, ";
    }
    $sql .= "pf.plm_filter_type_id, pfr.plm_filter_id";
}

$sth = $dbh->prepare( $sql );
$sth->execute();
my @row = $sth->fetchrow_array;
printf( "%-5s %-25s %-21s %s\n", "Patch", "Filter (ID)", "Host", "Result" );
while ( @row ) {

    #
    # Start retarded section.
    #

    # I'm extremely embarrassed to say that I'm going through the web interface
    # because I can't figure out how to get bzip2 to work on the fly.
    # This would be oh so much neater if someone can figure it out.
    my $ua = new LWP::UserAgent;
    my $link = "$url/plm?module=filter_output&id=$row[ 2 ]";
    my $request = HTTP::Request->new( GET => "$link" );
    my $response = $ua->request( $request );
    $data = $response->content;

    # Cut out the HTTP crap.
    $data =~ /<pre>(.*)<\/pre>/s;
    $data = $1;

    #
    # End restarded section.
    #

    $data =~ /host\s\[\s(.*)\s\]/; 
    my $host = $1;
    $host = "unknown" unless ( $host );

    printf( "%5s %-25s %-21s %s %s\n", $row[ 0 ],
      $row[ 1 ] . " (" . $row[ 5 ] . ")", $host, $row[ 3 ], $row[ 4 ] );
    print "$data\n" if ( $verbose );

    @row = $sth->fetchrow_array;
}

