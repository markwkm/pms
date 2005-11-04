# PLM::PLM::PatchACL Package
#
# Author:	Nathan Dabney
# Date:		09/19/02
#
# Presents a method reference to a PatchACL object in the PLM data space

package PLM::PLM::PatchACL;

@ISA = qw( PLM::PLM );

use strict;
use PLM::Util::Log;
use PLM::PLM;
use PLM::PLM::PatchACL_to_User;
use PLM::Util;

my $log = getLog( "PLM::PLM::PatchACL" );

sub new {
    my $self = {};
    my $type = shift;
    bless $self, $type;

    $self->SUPER::new( "plm_patch_acl" );

    return $self;
}

sub debug {
    my ( $self, $debug ) = @_;

    $log->debug( $debug )       if defined $debug;
    $self->SUPER::log( $debug ) if defined $debug;

    return $log->debug();
}

sub add {
    my ( $self, $xml_ref ) = @_;

    $self->unload();

    $self->loadDataOnly( ${ $xml_ref } ) if ( $xml_ref );

    $self->SUPER::add();
}

sub check_user_access {
    my ( $self, $acl_id, $user_id ) = @_;
    my $acl_join = new PLM::PLM::PatchACL_to_User();

    my $ref = $acl_join->search_sql(
        {
            plm_patch_acl_id => $acl_id,
            plm_user_id      => $user_id
        }
    );

    return 1 if ( $ref );

    return 0;
}

sub patch_name_acl {
    my ( $self, $software_id, $patchname, $user_id ) = @_;
    my $acl = new PLM::PLM::PatchACL();
    my $regex;
    my $reason;

    my $list = $self->search_sql( { plm_software_id => $software_id } );

    return 0 unless $list;

    for ( @{ $list } ) {
        $acl->load( ${ $_ }{ id } );
        $regex  = $acl->getValue( "regex" );
        $reason = $acl->getValue( "reason" );

        $log->msg( 3,
                   "Checking patch name [$patchname] against regex [$regex]" );

        if ( $patchname =~ /$regex/i ) {
            return 1 unless $self->check_user_access( ${ $_ }{ id }, $user_id );
        }
    }

    return 0;
}

1;
