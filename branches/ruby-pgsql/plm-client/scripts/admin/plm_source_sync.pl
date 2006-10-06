#!/usr/bin/perl -w

use strict;
use File::Find;
use DBI;
use Getopt::Long;

use PLM::Object::Patch;
use PLM::Object::Source;
use PLM::PLMClient;
use PLM::Util;

my $cfg = getConfig();
my $log = getLog( "plm_source_sync" );
my $rpc = new PLM::PLMClient( $cfg );

my $LOCKFILE = "/var/lock/plm/cron";

exit( 0 ) if ( -f "/var/lock/plm/stop" );

if ( !-f $LOCKFILE ) {
   # Here we  create the lockfile
   `touch $LOCKFILE`;
} else {
   print STDERR "Lockfile found, exiting.\n";
   exit 0;
}

sub END {
   if ( -f $LOCKFILE ) {
      print STDERR "Deleting the lockfile\n";
      `rm -f $LOCKFILE`;
   }
   print STDERR "$0 exiting\n";
}

# Options:
# --config
# This script should take an argument for the config file.
# that should contain the repo, the plm user, and the plm password.
# This allows more flexibility for syncing various repositories.
# --list_only
# Another option will be to find files, but not sync them
#
#  One repository per config; config looks like (minus the #'s):
#repository = linux
#plm_user = test
#plm_password = testtest
#

my $source_sync_cfg;
my $source_sync_cfg_object;
my $LIST_ONLY;
#
# This is to speed things up where bz2 and gz files are both available.
#
my %CHECKED;
my %LOADED_MODULE;
my $source_sync_module;
my $source_access_module;

GetOptions( "config=s", \$source_sync_cfg,
            "list_only", \$LIST_ONLY);

my $repository;
my $plm_user;
my $plm_password;

if (! $source_sync_cfg) {
    $log->msg( 1, "Script requires configuration file." );
    die "Usage:  plm_source_sync.pl --config <file_name> [--list_only]\n";
} else { 
    my $source_sync_cfg_object = getConfig("$source_sync_cfg");
    if (! $source_sync_cfg_object){
        $log->msg( 0, "SourceSync configuration file [ $source_sync_cfg ] is not readable.\n" );
        print "SourceSync configuration file [ $source_sync_cfg ] is not readable.\n";
        exit -1;
    }
    $repository=$source_sync_cfg_object->get( "repository" );
    $plm_user=$source_sync_cfg_object->get( "plm_user" );
    $plm_password=$source_sync_cfg_object->get( "plm_password" );
}    

my $archive;

my $softwareID;
my $plm_user_ID;

# Check the user and repository
(($softwareID) = $rpc->ASP( "SoftwareVerify", $repository )) || panic( "Bad Repository" );
(($plm_user_ID) = $rpc->ASP( "UserVerify", $plm_user, $plm_password )) || panic( "Bad Username" );

# This needs to be done through table plm_source now
my $source_info_ref;
$source_info_ref = $rpc->ASP( "SourceGetBySoftware", $softwareID );

#
#  This loops through all the source types set for a software
#
my $source_info;
foreach $source_info(@{$source_info_ref}){
  bless $source_info, 'PLM::Object::Source'; 
  my $root_location;
  (($root_location)=$source_info->{ 'root_location' }) || panic( "No location");
  my $plm_source_type;
  (( $plm_source_type )=$source_info->{ 'source_type' }) || panic("No Source type: CVS, TAR etc");
  # All source types are only first char upper case due to 'make manifest' filtering out 'CVS'.
  $plm_source_type="\u\L$plm_source_type";

  #  This needs to work with all types of source.
  if (! $LOADED_MODULE{$plm_source_type}){
     $source_sync_module="PLM::Object::SourceSync::" . $plm_source_type;
     $source_access_module="PLM::Archive::" . $plm_source_type;
     if ($plm_source_type =~ m/Tar|Cvs/){
         eval "require $source_sync_module";
         if ($@) { panic( "Cannot load module $source_sync_module : $@");}
         eval "require $source_access_module";
         if ($@) { panic( "Cannot load module $source_access_module : $@");}
     } else {
         panic "$plm_source_type is not supported.";
     }
  }
  # Get source sync information from database
  # This only works for 'CVS', 'TAR'
  my $source_sync_data;
  ($source_sync_data = $rpc->ASP( "SourceSyncBySource", $source_info->{ 'id' })) || panic( "No Source Syncing information");
  my $source_sync_info;

  print "    Syncing '$repository' repository located at [ " . $source_info->{ 'root_location' } . " ]\n";
  foreach $source_sync_info ( @{$source_sync_data} ) {
    bless $source_sync_info, $source_sync_module;
    $source_sync_info->addElement( 'softwareID', "");
    $source_sync_info->setElementValue( 'softwareID', $softwareID );
    $source_sync_info->addElement( 'plm_user_ID' , "");
    $source_sync_info->setElementValue( 'plm_user_ID', $plm_user_ID );

    system "rm -f /tmp/plm-not.wanted.txt";

    print "    Syncing '$repository' directory [ " . $source_sync_info->{ 'search_location' } . " ]\n";

    # This is where we retrieve the file list through Source Sync
    my $my_archive;
    $my_archive = new $source_access_module( $source_info, $source_sync_info );
    my $files = $my_archive->get_files();
    my $file;
    foreach $file (@{$files}){
        handle_source_item( $file->[1], $file->[0], $repository, $source_sync_info, $source_info );
    }
  }
}


sub not_wanted {
    my ( $dir, $file, $reason ) = @_;

    $dir    = "N/A"     unless ( $dir );
    $file   = "N/A"     unless ( $file );
    $reason = "Unknown" unless ( $reason );

    chomp $dir;
    chomp $file;
    chomp $reason;

    open( FILE, ">>/tmp/plm-not.wanted.txt" )
      || panic( "Can't open not.wanted.txt: $!" );
    print FILE "$dir :: $file :: $reason\n";
    close( FILE );

    return 0;
}

#
#  This needs to be moved to a module PLM::PLM::SourceSync or PLM::PLM::SourceSync::TAR or ?
#
sub handle_source_item {
    my ( $dir, $file, $repository, $source_sync_info, $source_info ) = @_;

    my $applies;
    my $content;

    my $filename = $file;
    $file =~ s/(\.tar){0,1}\.(gz|bz2|dif)$//;    # Strip the file extensions
    my $name = $file;
    unless($name=$source_sync_info->fix_name($name, $source_info->{ 'sc_module' })){
         $log->msg( 0, "Software [ $repository] [ $name ] name match error [ $source_sync_info->getValue('name_substitution') ]." );
         return 0;
    }

    # Do not check for twice (gz and bz2)
    return not_wanted( "", $file, "" ) if ( $CHECKED{ $file} );
    $CHECKED{ $file }=1;

    # General checks
    # Checks on specific files
    return not_wanted( "", $file, "" ) if ($source_sync_info->name_checks($name));

    # Check if these exist in db already
    my ($patch_id) = $rpc->ASP("PatchFindByName", "$name" );
    if ( $patch_id ) {    # Already exists, expected for those we've already synced
        $log->msg( 4, "Patch $name already exists as PLM ID $patch_id" );
        return 0;
    }

    $log->msg( 4, "File [$file] passed phase 2 selection [ $repository ] [ $source_sync_info->{ 'descriptor' } ]" );

    # Can file type retrieved properly, from mime type, BEFORE the download?
    # This also is only for type 'TAR', and should be rolled into SourceSync.
    my $file_type=$source_sync_info->get_file_type($filename);
    if (! $file_type){
        $log->msg( 0, "Not supported file type [ $filename ]");
        return 0;  # Do not die, continue with rest of files.
    }

    my $appliesID=0;
    my $source_access="";
    if ( $source_sync_info->isa_base() ){
        print "        baseline: $filename    \t[ $name ] \t[ $dir ]\n";
        $content='';
    } else {
        print "        patch: $filename    \t[ $name ] \t[ $dir ]\n";
        # Get applies value
        $applies = $source_sync_info->get_applies_version($file, $repository);
        if (! $applies){
            $log->msg( 0, "Failed adding $name, no value for applies!" );
            print "Failed adding: $filename    \t[ $name ] \t[ $dir ] no applies.\nCheck applies regex [ " . $source_sync_info->{ 'applies_regex' } . " ]\n";
            return 0;
        }

        $appliesID = get_appliesID($name, \$applies, $repository);

        if (! $LIST_ONLY){
            my $error;
            $source_access = new $source_access_module($source_info, $source_sync_info);
            if ( $source_access->get_top_page_content($filename, $dir) ) {
                $content=$source_access->base64($file_type);
            } else {
                $log->msg( 0, "Failed retrieve for $dir/$filename." );
                print "            Failed retrieve for $dir/$filename.\n";
                return -1;
            }
        } else {
            print "          Applies: [ $applies ]\n";
            $content = "";
        }
        #  This check is late to get the printout for list_only option
        if ( ! $appliesID ){
            print "            Did not retrieve '$dir/$filename', no applies '$applies'.\n";
            return 0;
        }
    }
   
    my $res = submit_patch( $name, $appliesID, $content, $source_sync_info, $file_type, $dir, $filename, $source_info->{ "id" } );
}

sub get_appliesID {
    my ( $name, $applies_ref, $repository) = @_;
    my $applies = ${$applies_ref};
    my $appliesID = 0;

    ($appliesID) = $rpc->ASP("PatchFindByName", "$applies" );
    if ( ! $appliesID ) {
            # Target missing
            # try again with 'patch' for linux kernels
            my $second_applies = $applies;
            $second_applies =~ s/^$repository-/patch-/;
            $log->msg( 2, "Failed adding $name, [ $applies ] trying [ $second_applies ]" );
            ($appliesID) = $rpc->ASP("PatchFindByName", "$second_applies" );

            if ( ! $appliesID ) {    # Target missing
                $log->msg( 0, "Failed adding $name, [ $applies ] missing!" );
                return 0;
            } else {
                $$applies_ref = $second_applies;
            }
    }
    return $appliesID;
}

sub submit_patch {
    my ( $name, $appliesID, $content, $archive_info, $file_type, $dir, $filename, $plm_source_id) = @_;
    my $patch_id  = 0;
    my $sql;

    if ( $LIST_ONLY ){
        print ( "          Would fetch Item:  $name  AppliesID: $appliesID\n" );
        return 0;
    }
         
    # Add the patch.
    my ( $res ) = $rpc->ASP( "PatchAdd", $plm_user, $plm_password, $name, $dir, $filename, $plm_source_id, $appliesID, $content, $file_type);
    if ( $res > 0 ) {
        $log->msg( 0, "patch accepted as ID# $res" );
        print ( "          Patch accepted as ID# $res\n" );
    } else {
        panic( "patch add failed for unknown reason: $res" );
    }

}

#  Currently not used
sub find_applies {
    my $a;

    if ( /\A(\S*?)?(.?\d+.\d+.)(\d+)(.*)$/ ) {
        my $ver = $3 - 1;
        return $repository . $2 . $ver;
    }

    panic( "ERROR: find_applies() is BROKEN against: [@_]" );
}
