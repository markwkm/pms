#!/usr/bin/perl -w

use strict;

use PLM::PLMClient;
use PLM::Util;
use Data::Dumper;

my $log = getLog("call_rpc.pl");
my $cfg = getConfig();


my $rpc = new PLM::PLMClient($cfg);
my $rv = $rpc->ASP(@ARGV);

print Dumper $rv;
