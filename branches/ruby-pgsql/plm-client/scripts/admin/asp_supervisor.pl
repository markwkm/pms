#!/usr/bin/perl 

use strict;
use POSIX ":sys_wait_h";
use MIME::Base64();

my $state_queued    = 1;
my $state_pending   = 2;
my $state_running   = 3;
my $state_completed = 4;
my $state_failed    = 6;

my $uniq_id = rand() . time();

my $pid_file;
if ( $ARGV[ 0 ] ) {
    $pid_file = $ARGV[ 0 ];
} else {
    $pid_file = "/tmp/.plm_supervisor" . $ENV{ PPID };
}

exit( 0 ) if ( `find $pid_file -amin -360 2> /dev/null` );  # We are a duplicate
open( FILE, ">$pid_file" ) || exit 0;                       # No write access
print FILE $uniq_id;
close( FILE );

check_run_file();

#
# Start the actual script
# 
#
use PLM::Util::Log;
use PLM::Util::Config;
use PLM::PLMClient;

my $config = new PLM::Util::Config( "/etc/plm/plm.cfg" );
my $log = new PLM::Util::Log(
    {
        filename => $config->get( "log_file" ),
        target   => $config->get( "log_target" ),
        level    => $config->get( "log_level" ),
        id       => "ASP Supervisor"
    }
);

my $rpc = new PLM::PLMClient( $config );

my $request   = 0;
my $patch_id  = 0;
my $filter_id = 0;
my $filename;
my $timeout;
my $software;

$ENV{ PATH } = "/usr/local/bin/:/bin:/usr/bin";    # Required for ccache support
$ENV{ CCACHE_DIR } = $config->get( "ccache_dir" ) || "/tmp/plm-ccache";

sub cleanup_old_files {
    system "rm -rf $software" . "* plm-* result.filter $filename";
}

while ( check_run_file() ) {
    $patch_id = 0;
    my $sleep_delay = $config->get( "supervisor_sleep" ) || 120;

    while ( $patch_id == 0 ) {
        check_run_file();

        my $type = $config->get( "filter_type" );
        my $data = $rpc->ASP( "GetRequest", $type );

        unless ( ref $data ) {
	    $patch_id = 0;
	    sleep( $sleep_delay );
	} else {
            ( $request, $patch_id, $filter_id, $filename, $timeout, $software ) = @{$data};

            $log->msg( 2, "ASP( GetRequest($type) ) returned: [ ",
                   join ( ":", @{$data} ), " ]" );

        # Fork here on 'else'
        #     Parent: Monitor child, when child exits, set $patch_id = 0 again.
        #           I child doesn't exit after timeout kill it.  Timout is set 
        #           for each filter in the database.
        #     Child:  Run filter then exit.
        #    
             my $pid ;
             $pid = fork;
             if ($pid != 0) {
                 # Parent Process
                 # Timeout for filter was pulled with request
                 my $wait_period;
                 my $interval= 60;
                 if ( $interval >= $timeout ) {
                     $interval  = $timeout / 2 ;
                 }
                 for ( $wait_period=0; $wait_period < $timeout; $wait_period+=$interval) {
                      sleep( $interval );
                      # does child still exist?
                      if ( waitpid ($pid, WNOHANG) ) {
                          # Filter is done, go back to querying ASP
                          $wait_period = $timeout;
                      }
                 }
                 if (! waitpid ($pid, WNOHANG) ) {
                     # If we get here the filter has run too long.
                     #    Kill child 
                     $log->msg( 0, "Filter timed out for patch $patch_id, Request: $request, Filename $filename.  Killing.");
                     system "kill -9 $pid";
                     sleep( 5 );
                     waitpid ($pid, WNOHANG);
                     cleanup_old_files();
                     # Wait for dependent processes to die, 
                     # killall no good, will affect other filters' processes
		     sleep( 300 );
                     cleanup_old_files();
                     # Update database that filter failed
                 }
                 # Go back to querying ASP.
                 $patch_id = 0;
             }  # else Child Process just runs as before...
        }
    }

    # Sanity Check
    panic( "\$software variable invalid" ) unless ( $software );
    panic( "\$patch_id variable invalid" ) unless ( $patch_id );
    panic( "\$filename variable invalid" ) unless ( $filename );
    panic( "\$filter_id variable invalid" ) unless ( $filter_id );

    # Get the kernel source and patch.
    system "rm -rf $software" . "*";
    system "plm_build_tree.pl $software " . $patch_id;
    if ($?){
         $log->msg( 0, "The patch $patch_id had an error building, check plm_build_tree.pl output." );
         my $result = "RESULT: FAIL\nRESULT-DETAIL: PLM build (plm_build__tree.pl )  failed for $patch_id.  Check LOG.\n";
         my $output = "";
         $rpc->ASP( "SubmitResult", $request, $result, $output );
         exit 1;
    }
    check_run_file();

    # Get the filter.
    my $filter = $rpc->ASP( "GetFilter", $filter_id );
    open( FILTERFILE, "> ${filename}" );
    print FILTERFILE MIME::Base64::decode( $filter );
    close FILTERFILE;

    check_run_file();

    # Execute the filter.
    my ( $rc ) = $rpc->ASP( "SetFilterRequestState", $request, $state_running );
    panic( "could not set filter request state to running" ) unless ( $rc );
    system "chmod +x $filename";
    my $output = `./$filename $patch_id $software | bzip2`;
    check_run_file();

    # Sanity check, somebody should see this down the road...
    panic( "NO OUTPUT FROM FILTER" ) unless $output;

    # Detect a correct filter run
    panic( "Missing filter results after run" ) unless -f "result.filter";

    # Record completed state information
    my $result = `cat result.filter`;
    check_run_file();
    $output = MIME::Base64::encode( $output );
    $rpc->ASP( "SubmitResult", $request, $result, $output );

    cleanup_old_files();
    # Child Process exits
    exit;
}

sub check_run_file {
    #exit 0 unless ( -f $pid_file );  # No $pid_file is present
    if ( ! -f $pid_file ) {
        $log->msg(0, "PID $pid_file file does not exist.");
        exit 0;
    }

    open( FILE, $pid_file ) || exit 0; 
    my $tmp = <FILE>;
    close( FILE );

    chomp $tmp;

    #exit 0 unless ( $tmp eq $uniq_id );
    if ( ! $tmp eq $uniq_id ) {
        $log->msg(4, "PID $pid_file file does not match.");
        exit 0;
    }

    system "touch $pid_file";

    return 1;
}
