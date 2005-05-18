package PLM::RPC::Server;

#
# This server is for actions that do not need to be trusted, mostly pulling patches
#   via plm_build_tree.pl.  plm_source_sync also runs here, but probably should be 
#   private.
#
use  SOAP::MIME;
use  MIME::Entity;
@ISA = qw( SOAP::Server::Parameters );
use strict;


use PLM::RPC::CommandSet qw( command_set_get_content );
use PLM::RPC::User qw( user_verify ) ;
use PLM::RPC::Patch qw( patch_add patch_get_list patch_get_value patch_get_software_name patch_find_by_name );
#use PLM::RPC::Patch qw( patch_add patch_add_depend patch_get_value patch_get_software_name patch_find_by_name );
use PLM::RPC::Software qw( software_verify );
use PLM::RPC::Source qw( source_get_by_software source_get );
use PLM::RPC::SourceSync qw( source_sync_by_source source_sync_set_value );
use PLM::RPC::Supervisor qw( get_applies_tree );               #  This should be in plm_patch table, method
#use PLM;

#my $log = getLog( "PLM::RPC::Server" );

1;
