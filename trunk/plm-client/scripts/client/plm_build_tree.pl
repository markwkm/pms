#!/usr/bin/perl -w

use strict;
use Fcntl;
use MIME::Base64();

use PLM::Util::Log;
use PLM::Util::Config;
use PLM::PLMClient;
use PLM::Util;
use PLM::Object::Source;

my $log = getLog("plm_build_tree.pl");
my $cfg = getConfig();

my ( $repo, $patch_id ) = @ARGV;

unless ( $repo )     { panic( "Missing software repository" ) }
unless ( $patch_id ) { panic( "Missing patch ID number to build tree of" ) }

my $rpc = new PLM::PLMClient($cfg);

# get software_id for repo
my $software_id; 
($software_id) = $rpc->ASP("software_verify", $repo);

sanity_check($repo, $software_id, $patch_id);

build_tree( $_ );

deposit_build_scripts($repo, $patch_id);

sub sanity_check {
    my $repo = shift;
    my $software_id = shift;
    my $patch_id = shift;
    if ( -d $repo ) {
        print "ERROR - the $repo directory already exists\n";
        exit 1;
    }

    # Add a check here, does repo exist and is patch_id in it?
    #    Get id from plm_software by name
    #
    if ($software_id == 0) {
        print "ERROR - the repository $repo does not exist\n";
        $log->msg( 0, "ERROR - the repository $repo does not exist");
        exit 1;
    }
    #    Is value of plm_software_id = to previous id from plm_filter by id.
    #
    my $patch_software_id;
    ($patch_software_id) = $rpc->ASP("patch_get_value", $patch_id, "software_id");
    if (! $patch_software_id or $software_id != $patch_software_id) {
        print "ERROR - the patch $patch_id is not in repository $repo\n";
        $log->msg( 0, "ERROR - the patch $patch_id is not in repository $repo");
        exit 1;
    }
}

sub build_tree {
    my $applies = $rpc->ASP( "get_applies_tree", $patch_id );
    unless ( scalar @{$applies} ) {
        print "[$patch_id] is an invalid patch ID.\n";
        exit 1;
    }
    print "Applies Tree: @{$applies}\n";

    my $base_patch = pop @{$applies};
    handle_base( $base_patch );

    for ( reverse @{$applies} ) {
        handle_patch( $_ );
    }
}

sub handle_base {
    my $pid = shift;

    return if ( -d $repo );    # Another part of tree already expanded to base

    my $patch = $rpc->ASP( 'get_patch', $pid );

    my $remote_identifier = ${$patch}[0];
    my $base_location = ${$patch}[1];
    my $source_id = ${$patch}[2];

    panic( "Can't get filename or location from ASP server." )
      unless $remote_identifier;
    if ( -e $remote_identifier ){
      print( "File $remote_identifier already exists.\n");
      exit;
    }

    my ( $source_info ) = $rpc->ASP("source_get", $source_id);
    #  bless source object or it is "PLM::PLM::Source"
    bless $source_info, "PLM::Object::Source";

    my $locType=$source_info->{'source_type'};
    panic( "Can't get repo type from database" ) unless $locType;
    $locType="\u\L$locType";

    # Load the appropriate source access module
    my $source_access_module="PLM::Archive::" . $locType;
    eval "use $source_access_module" ;
    if ($@){ panic("Cannot load access module for $locType : $@"); }
    
    print "Retrieving software base from [ \U${locType} ] " . $source_info->{'root_location'} . ", $base_location, $remote_identifier\n";
    my $source_access = new $source_access_module($source_info);
    my $rv=0;
    if ( !( -f $remote_identifier ) ) {
        my $retry = 3;
        while ( $retry && !( -e $remote_identifier ) ) {
            # Name the file the same thing locally. 
            $rv=$source_access->get_content_to_file($remote_identifier, $base_location);
            unless ( $rv ) {
                $retry--;
                sleep 10;
            }
        }
    }

    if ( !( -e $remote_identifier ) or ! $rv ) {
        panic( "Retrieval of base source for $repo $remote_identifier failed! [ $rv ]" );
    }

    $remote_identifier=$source_access->post_process();

    rename $remote_identifier, $repo if ( -d $remote_identifier );
    # Exception for xfsprogs, which has unexpected source dir name.
    rename "${remote_identifier}.src", $repo if ( -d "${remote_identifier}.src");
    
}

sub handle_patch {
    my $pid  = shift;
    my $file = "plm-$pid.patch";
    my $path;

    my $patch = $rpc->ASP( 'get_patch', $pid );
    my $reverse = ${$patch}[3];
    my $p = ${$patch}[4];

    open(PATCHFILE, "> ${file}");
       print PATCHFILE MIME::Base64::encode(${$patch}[5]);
    close PATCHFILE;

    chdir $repo;

    print "Patching source, placing output in: patch.$pid.out\n";
    if ( $reverse eq "true" ){
        system "(patch -f -R -p${p} < ../$file &> patch.$pid.out) || touch patch.error";
    } else {
        system "(patch -f -p${p} < ../$file &> patch.$pid.out) || touch patch.error";
    }
    # this extra check was suggested as some patch programs do not error out.
    system "grep -e \"Hunk \\#[0-9]\\{1,\\} FAILED\" patch.$pid.out >/dev/null && touch patch.error";

    chdir "..";
}

sub deposit_build_scripts{
    my ($software, $patch_id) = @_;
    my @command_type = qw( build install validate );
    my $command_type;
    for $command_type ( @command_type ){
        my $commands = $rpc->ASP("command_set_get_content", $software, $patch_id, $command_type );
        if (ref $commands){
            my $filename=$software . "-" . $patch_id . "-" . $command_type ; 
            commands_to_file( $commands, $filename );
        }
    }
}

sub commands_to_file{
    my ($ref, $filename)=@_;

    my $row;
    if ($#{$ref} > -1){
        open FH, ">$filename" || panic("Could not open $filename");
        foreach $row (@{$ref}){
            print FH "$row->{command}\n";
        }
    }
}
