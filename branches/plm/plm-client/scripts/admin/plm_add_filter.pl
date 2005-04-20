#!/usr/bin/perl

# start podify

=head1 NAME

plm_add_filter.pl

=head1 SYNOPSIS

This script allows an administrator of PLM to add a filter definition to the
database.

=head1 DESCRIPTION

Use plm_add_filter_type.pl to see how to add a filter type to the database.
Filter type can be 'all'.  See the documentation for why and how that works.

=head1 OPTIONS

=item
B<--software> I<software>
B<--name> I<name>
B<--location> I<url>
B<--command> I<script>
B<--runtime> I<seconds>
B<--filter_type> I<code>

=head1 EXAMPLES

plm_add_filter.pl --software linux --name apply_patch --location http://www.osdl.org/apply_patch.sh --command apply_patch.sh --runtime 600 --filter_type ia32

=head1 SEE ALSO

plm_add_filter_type.pl

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
my $sth;
my $rc;
my @row;

my $software_id;
my $filter_type_id;

my $command;
my $filter_type;
my $location;
my $name;
my $runtime;
my $software;

GetOptions( "software=s" => \$software,
            "runtime=i" => \$runtime,
            "name=s" => \$name,
            "location=s" => \$location,
            "filter_type=s" => \$filter_type,
            "command=s" => \$command );

sub usage() {
    print "usage: plm_add_filter.pl --software <software> --name <name> --location <url>\n"
        . "                         --command <script> --runtime <seconds>\n"
        . "                         --filter_type <code>\n";
    exit 1;
}

usage() unless ( $command && $location && $name && $runtime && $software &&
                 $filter_type );

if ( $software eq "all" ) {
    $software_id = 0;
} else {
    # Check to make sure the software package that this filter is for exists.
    $sql = "SELECT id "
         . "FROM plm_software "
         . "WHERE name = '$software'";
    $sth = $dbh->prepare( $sql );
    $sth->execute();
    @row = $sth->fetchrow_array;
    unless ( @row ) {
        print "Software '$software' does not exist.\n";
        exit 1;
    }
    $software_id = $row[ 0 ];
}

if ( $filter_type eq "all" ) {
    $filter_type_id = 0;
} else {
    # Check to make sure the filter type that this filter is for exists.
    $sql = "SELECT id "
         . "FROM plm_filter_type "
         . "WHERE code = '$filter_type'";
    $sth = $dbh->prepare( $sql );
    $sth->execute();
    @row = $sth->fetchrow_array;
    unless ( @row ) {
        print "Filter type '$filter_type' does not exist.\n";
        exit 1;
    }
    $filter_type_id = $row[ 0 ];
}

# Insert the filter into the database.
my $time = time();
$sql = "INSERT INTO plm_filter (rsf, created, plm_software_id, name, \n"
     . "                        location, command, runtime, \n"
     . "                        plm_filter_type_id)\n"
     . "VALUES (1, $time, $software_id, '$name', '$location', '$command', \n"
     . "        $runtime, $filter_type_id)";
$rc = $dbh->do( $sql );

if ( $rc == 1 ) { print "Successfully added filter '$name' to PLM.\n"; }
else { print "Could not add filter '$name' to PLM.\n"; }
