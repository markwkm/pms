package PLM::RPC::PrivateServer;

use  SOAP::MIME;
use  MIME::Entity;
@ISA = qw( SOAP::Server::Parameters );
use strict;


#use PLM::RPC::User qw( user_verify user_add user_delete user_password user_set_option user_get_option user_find_by_email user_get_info) ;
use PLM::RPC::User qw( user_verify user_get_email ) ;
use PLM::RPC::CommandSet qw( command_set_get_content );
use PLM::RPC::Patch qw( patch_add patch_get_value patch_get_software_name patch_find_by_name );
#use PLM::RPC::Patch qw( patch_add patch_get_value patch_get_software_name patch_add_depend patch_find_by_name );
use PLM::RPC::Software qw( software_verify );
use PLM::RPC::Source qw( source_get_by_software source_get );
use PLM::RPC::SourceSync qw( source_sync_by_source source_sync_set_value );
#use PLM;
use PLM::RPC::Supervisor qw( set_filter_request_state get_request submit_result get_applies_tree );

#my $log = getLog( "PLM::RPC::PrivateServer" );

1;
