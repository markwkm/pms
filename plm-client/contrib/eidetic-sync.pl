#!/usr/bin/perl -w

# Cliffw 9/8/2004
# removing bk and -mm kernels from mass_request
# cliffw 12/13/2004
# adding linux-mm testing list
# 
use strict;
use PLM::Util;

my $log = getLog( "searchSync" );
my $cfg = getConfig();

my $plm_dbh = getDBHandle();
my $eidetic_dbh = new PLM::DB::Handle( { dsn => $cfg->get( "GW:1:driver:dsn" ),
				    user => $cfg->get( "GW:1:driver:user" ),
				    pass => $cfg->get( "GW:1:driver:pass" ) });

#
# Make sure the dbh handles we have are valid
#
die "Bad plm_dbh handle" unless ( $plm_dbh );
die "Bad eidetic_dbh handle" unless ( $eidetic_dbh );

#
# Connect to the databases
#
$plm_dbh->connect() || die "Can't correct to the database: plm";
$eidetic_dbh->connect() || die "Can't connect to the database: EIDETIC";

# Set patch_tag table name
my $remote_patch_table='patch_tag';
my $sync_db=$cfg->get( "patch_replication_target");
if ($sync_db){
    $remote_patch_table=$sync_db .'.'. $remote_patch_table;
}

#Make hash with sofware types
my $plmRef = $plm_dbh->getAll( "id, name", "plm_software", "rsf=1" );

my @software_names=();
for (@{ $plmRef }){
    $software_names[ ${$_}{id} ] = ${$_}{name};
}

#
# Grab the lists of available patches from both systems
#
$plmRef = $plm_dbh->getAll( "*", "plm_patch", "rsf=1" ); 
my $eideticRef = $eidetic_dbh->getAll( "*", $remote_patch_table ); 

#
# Do sanity checking on the list of available patches from both systems
#
die "Bad plmRef" unless ( $plmRef && @{ $plmRef } );
die "Bad eideticRef" unless ( $eideticRef && @{ $eideticRef } );

#
# Make sure neither count is zero (possibly corrupt/unavailable count...)
#
my $plmCount = @{ $plmRef };
my $eideticCount = @{ $eideticRef };

die "Not enough patches in PLM" unless ( $plmCount );
die "Not enough patches in EIDETIC" unless ( $eideticCount );

#
# Push any new patches from the PLM database to the EIDETIC database
#
for ( @{ $plmRef } ) {
    my %plm = %{ $_ }; 

    my $test = 0;
    for ( @{ $eideticRef } ) { 
        $test = 1 if ( ${ $_ }{ uid } eq $plm{ id } );
    }
    next if $test;

    print "Syncing Patch: $plm{ id } \t$plm{ name }\n"; 

    my $sql = "INSERT INTO $remote_patch_table ( uid, rsf, descriptor, software_type ) ";

    my $id = $plm{ id } || die "bad ID";
    my $desc = $plm{ name } || die "bad descriptor"; 
    my $software_type = $software_names[ $plm{ plm_software_id } ] or die "No software_type for patch:  $plm{ name } softwareID:  $plm{ plm_software_id }";
    $sql .= "VALUES ( $id, 1, '$desc', '$software_type' )";

    $eidetic_dbh->do( $sql );

	# Baseline match
    if ( $plm{ name } =~ /^(patch|linux)-\d+\.\d+\.\d+$/ ) {
        print "Mass requesting patches against patch $id\n";
        system "/home/plm/bin/mass_request.pl -plm $id -file=/home/plm/stp_requests/stp_baseline_mr.xml";
        system "/home/plm/bin/mass_request.pl -plm $id -file=/home/plm/stp_requests/linux_mm.xml -user=1060";

	# 2.6 -bk match
    # } elsif ( $plm{ name } =~ /^patch-2\.6\.\d+-test\d+-bk\d+$/ ) {
    } elsif ( $plm{ name } =~ /^patch-2\.6\.\d+(-rc\d+){0,1}-bk\d+$/ ) {
        print "Not Mass requesting patches against patch $id\n";
        # system "/home/plm/bin/mass_request.pl -plm $id -file=/home/plm/stp_requests/stp_bk_request.xml";
	# 2.4 match
    } elsif ( $plm{ name } =~ /^(patch|linux)-2\.4\.\d+/ ) {
        print "Mass requesting patches against patch $id\n";
        system "/home/plm/bin/mass_request.pl -plm $id -file=/home/plm/stp_requests/stp_2.4.request.xml";

	# 2.6.x-test match
    } elsif ( $plm{ name } =~ /^(patch|linux)-2\.6\.\d+-test\d+$/ ) {
        print "Mass requesting patches against patch $id\n";
        system "/home/plm/bin/mass_request.pl -plm $id -file=/home/plm/stp_requests/stp_pre.xml";

	# 2.6-x rc/pre match
    } elsif ( $plm{ name } =~ /^(patch|linux)-\d+\.\d+\.\d+-(rc|pre)\d+$/ ) {
        print "Mass requesting patches against patch $id\n";
        system "/home/plm/bin/mass_request.pl -plm $id -file=/home/plm/stp_requests/stp_pre.xml";

	# 2.6 -mm match
    #} elsif ( $plm{ name } =~ /^\d+\.\d+\.\d+-mm\d+$|^2\.6\.\d+-test\d+-mm\d+$/ ) {
    } elsif ( $plm{ name } =~ /^\d+\.\d+\.\d+(.\d+){0,1}-mm\d+$|^2\.6\.\d+(.\d+){0,1}-(rc|pre)\d+-mm\d+$/ ) {
        print "Not Mass requesting tests against patch $id\n";
	# system "/home/plm/bin/mass_request.pl -plm $id -file=/home/plm/stp_requests/stp_mm_mr.xml";

	# -osdl match
    } elsif ( $plm{ name } =~ /^osdl-\d+\.\d+\.\d+-/ ) {
        print "Mass requesting tests against patch $id\n";
	system "/home/plm/bin/mass_request.pl -plm $id -file=/home/plm/stp_requests/stp_pre.xml";
    }
}
