package Tests::ASP;

use strict;
use PLM::RPC::Server;
use PLM::PLMClient;
#use PLM::PLM;

sub user_verify {
    return 1 if PLM::RPC::Server::user_verify( @_ );
    return 0;
}

sub user_add {
    return 1 if PLM::RPC::Server::user_add( @_ );
    return 0;
}

sub user_delete {
    return PLM::RPC::Server::user_delete( @_ );
}

sub user_password {
    return 1 if PLM::RPC::Server::user_password( @_ );

    return 0;
}

sub user_set_option {
    return 1 if PLM::RPC::Server::user_set_option( @_ );
    return 0;
}

sub user_get_option {
    return PLM::RPC::Server::user_get_option( @_ );
}

sub user_find_by_email {
    return PLM::RPC::Server::user_find_by_email( @_ );
}

sub patch_add {
    return 1 if PLM::RPC::Server::patch_add( @_ );

    return 0;
}

sub SOAP_user_verify {
    my @ret = ASP( "user_verify", @_ );

    return 1 if $ret[ 0 ];
    return 0;
}

sub SOAP_user_add {
    my @ret = ASP( "user_add", @_ );

    return 1 if ( $ret[ 0 ] );

    return 0;
}

sub SOAP_user_delete {
    my @ret = ASP( "user_delete", @_ );

    return $ret[ 0 ];
}

sub SOAP_user_password {
    my @ret = ASP( "user_password", @_ );

    return $ret[ 0 ];
}

sub SOAP_user_set_option {
    my @ret = ASP( "user_set_option", @_ );

    return $ret[ 0 ];
}

sub SOAP_user_get_option {
    my @ret = ASP( "user_get_option", @_ );

    return $ret[ 0 ];
}

sub SOAP_user_find_by_email {
    my @ret = ASP( "user_find_by_email", @_ );

    return 1 if $ret[ 0 ];
    return 0;
}

sub SOAP_patch_add {
    my @ret = ASP( "patch_add", @_ );

    return 1 if $ret[ 0 ];
    return 0;
}

1;
