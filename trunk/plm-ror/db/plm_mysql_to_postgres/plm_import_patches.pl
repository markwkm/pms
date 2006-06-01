#!/usr/bin/perl

use MIME::Base64;
use DBI;
#use DBD::Pg;


my $database = plm_production;
my $host = 'testdb';
my $user = plm;
my $conn = DBI->connect( "dbi:Pg:dbname=$database;host=$host", "$user" );

opendir DH, './patch';
foreach $file (readdir DH) {
    next unless $file =~ m/bz2$/;
    print "Importing patch: $file\n";
    $length = length( $file );
    my $id = substr( $file, 6, $length-10 );
    $patch = `bzcat ./patch/$file`;
    $encoded_patch = encode_base64( $patch );
    $statement = "UPDATE patches SET diff =  '$encoded_patch' WHERE id = '$id';";
    $conn->do( $statement );
}
close DH;   

$conn->disconnect();
