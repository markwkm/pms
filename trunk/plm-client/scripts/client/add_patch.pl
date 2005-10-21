#!/usr/bin/perl -w

use strict;

use Getopt::Long;
use MIME::Base64::Perl;
use SOAP::Lite;

my $wsdl = 'http://lemming:3001/Backend/service.wsdl';

my $applies_patch_name;
my $help;
my $host;
my $login;
my $password;
my $patch_file;
my $patch_name;
my $software_name;

GetOptions (
    "applies-patch-name=s", \$applies_patch_name,
    "help!", \$help,
    "host=s", \$host,
    "login=s", \$login,
    "password=s", \$password,
    "patch-name=s", \$patch_name,
    "patch-file=s", \$patch_file,
    "software-name=s", \$software_name
);

if ($help) {
  print "usage: add_patch.pl --login <login> --password <password>\n";
  print "    --patch-file <filename> --patch-name <name> --software_name <software>\n";
  print "    --aplies-patch-name <patch-name> --host <host>\n";
  exit 0;
}

$wsdl = "https://$host/Backend/service.wsdl" if ($host);

my $abort = 0;

unless ($patch_file) {
  print "specify --patch_file\n";
  $abort = 1;
}

if ($patch_file) {
  unless (-f $patch_file) {
    print "'$patch_file' doesn't exist\n";
    $abort = 1;
  }
}

unless ($login) {
  print "specify --login\n";
  $abort = 1;
}

unless ($password) {
  print "specify --password\n";
  $abort = 1;
}

unless ($software_name) {
  print "specify --software_name\n";
  $abort = 1;
}

unless ($applies_patch_name) {
  print "specify --applies-patch-name\n";
  $abort = 1;
}

exit 1 if $abort == 1;

my $patch = "";
my $line;
open (PATCH, $patch_file);
while ($line = <PATCH>) {
  $patch .= $line;
}

my $service = SOAP::Lite -> service($wsdl);
my $id = $service -> AddPatch($login, $password, $patch_name, $software_name,
    $applies_patch_name, encode_base64($patch));

if ($id == -2) {
  print "invalid login or password\n";
  exit 1;
} elsif ($id == -1) {
  print "invalid software_name ($software_name), not a unique patch_name ($patch_name), or invalid applies_patch_name ($applies_patch_name)\n";
  exit 1;
}

print "$id\n";
