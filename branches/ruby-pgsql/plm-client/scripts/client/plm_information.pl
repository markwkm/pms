#!/usr/bin/perl -w

use strict;
use Fcntl;

use PLM::Util::Log;
use PLM::Util::Config;
use PLM::PLMClient;
use PLM::Util;

my $log = getLog("plm_information.pl");
my $cfg = getConfig();

my ( $call, @options ) = @ARGV;

unless ( $call )     { print ( "You must call a remote function-options 'GetName'\n" ); exit; }

my $rpc = new PLM::PLMClient($cfg);

# get software_id for repo
my ($answer) = $rpc->ASP($call, @options);
print $answer . "\n";
exit;
