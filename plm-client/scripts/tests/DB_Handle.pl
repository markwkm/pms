#!/usr/bin/perl -w -I/usr/lib/perl5/site_perl/PLM

use strict;
use PLM::DB::Handle;
use PLM::Util;

my $cfg = getConfig();
my $dbh = getDBHandle();

$dbh->connect;
$dbh->getResultSet( "*", "plm_user" );
$dbh->disconnect;

print "Num rows: " . $dbh->getNumRows() . "\n\n";

for ( my $x = 0; $x < $dbh->getNumRows(); $x++ ) {
    print "User Info: " . "["
      . $dbh->getProperty( $x, "id" ) . "] "
      . $dbh->getProperty( $x, "name" ) . " "
      . "(created: "
      . localtime( $dbh->getProperty( $x, "created" ) ) . ") \n";
}

print "\n";

for ( @{ $dbh->getDataRef } ) {
    my %info = %{ $_ };
    print "User Info: [$info{id}] $info{name} "
      . "(created: "
      . localtime( $info{ created } ) . ")\n";
}

print "\n";
