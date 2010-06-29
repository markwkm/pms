#!/usr/bin/perl -w

use strict;

use PLM::DB::Handle;
use PLM::Util;

my $dbh = getDBHandle();

$dbh->connect();

$dbh->get( "*", "Queues" );

for ( my $i = 0; $i < $dbh->getNumRows(); $i++ ) {
    print "Queue: " . $dbh->getProperty( $i, "name" ) . "\n";
}

$dbh->disconnect();
