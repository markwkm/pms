#!/usr/bin/perl -w

use strict;

use PLM::PLMClient;
use PLM::Util;

my $TRUE=0;
my $FALSE=1;

my $log = getLog("plm_build_app.pl");
my $cfg = getConfig();
my $output_file='.';
if ($ENV{TEST_LOGS}){
    $output_file=$ENV{TEST_LOGS};
}

my ($software, $patch_id, $command_type)=@ARGV;

$output_file.="/$software.$patch_id.$command_type.log";

open OUTFILE, ">$output_file" or panic "Cannot open file for logging output.";

my $rpc = new PLM::PLMClient($cfg);
if ( $patch_id =~ m/.*\D.*/){
    ($patch_id) = $rpc->ASP("PatchFindByName", $patch_id );
}
my $ref = $rpc->ASP("ComandSetGetContent", $software, $patch_id, $command_type );

if (ref $ref){
    chdir $software or panic("Cannot find directory $software to build in.");
    print OUTFILE "Running the $command_type commands.\n";
    if ( CommandExec::command_execute($ref, *OUTFILE)){
         print OUTFILE "Build type \'$command_type\' of $software, $patch_id Failed.\n";
         exit 1;
    }
        
} else {
    print OUTFILE "No rows retrieved\n";
    exit 1;
}

print  OUTFILE "\u$command_type of $software PLM ID $patch_id completed successfully.\n";
exit 0;


package CommandExec;

sub command_execute {
    my $ref =shift;
    my $fh=shift;

    my $row;
    foreach $row (@{$ref}){
        my $exec = $row->{command_type};
        my $rv = eval( "$exec \$row, $fh\;") ;
        if ($@ or $rv){
            print $fh "Execution failed:  $exec:  $row->{command}\n";
            print $fh "$@\n";
            return $FALSE;
        }
    }
    
}

# These scripts will be executed based on the command 'command_type'
sub command {
    my $row = shift;
    my $fh=shift;

    print "Executing:  $row->{command}\n";
    my $output = `$row->{command} 2>&1`;
    my $err=$?;
    print $fh $output;
    # For 'command' type we just check return value
    if ($err != $row->{expected_result}){
        # Here is an error
        $log->msg( 0, "Build Error - \'$row->{command}\' returned $err" );
        return $FALSE;
    } 
    return $TRUE;
}

sub script{
   #  
}

1;
