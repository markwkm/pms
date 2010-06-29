#!/usr/bin/perl -w

use SOAP::Transport::HTTP;
use PLM::RPC::Server;           # This will be our 'Base'
use CGI::Carp qw(fatalsToBrowser);
use strict;

SOAP::Transport::HTTP::CGI->dispatch_to( 'PLM::RPC::Server' )->handle;

