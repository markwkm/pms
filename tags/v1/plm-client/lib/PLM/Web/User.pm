#
# perl module for supporting the requirements of a web application
# 

package PLM::Web::User;

@ISA = qw( Exporter );

@EXPORT = qw(user_creds user_login user_get_id user_get_email);
push @EXPORT, qw(user_is_admin user_default_public);

use strict;
use Exporter;
use CGI qw/:standard/;
use CGI::Cookie;
use CGI::Carp qw(fatalsToBrowser);
use PLM::Util;
use PLM::PLM;

use PLM::Web::General;
use PLM::Web::Session;

my $USER_ID = 0;
my $user    = 0;
my $log     = getLog();

#
# Quick function to return the credentials for the current user
# 
sub user_creds {
    return ( "", "" ) unless $SESSION{ username };

    return ( $SESSION{ username }, $SESSION{ password } );
}

# 
# Get user information from the server if we don't have it
#
sub user_get_meta {
    return 1 if $user;
    return 0 unless $SESSION{ username };

    $user = PLM::RPC::User->user_get_info(      $SESSION{ username },
                    $SESSION{ password }, $SESSION{ username }
    );

    return 0 unless ( $user );

    unless ( $user->getValue( "name" ) eq $SESSION{ username } ) {
        panic(
             "We didn't get info on the user we expected: " . $user->getValue('name') . " " . $user->getValue('id') );
    }

    return 1;
}

#
# Log the user into the system
# 
sub user_login {
    my ( $user, $pass ) = @_;

    my @id = PLM::RPC::User->user_verify( $user, $pass );

    return 0 unless ( @id );

    $USER_ID = $id[ 0 ];

    return $USER_ID;
}

#
# Retrieve the users ID
#
sub user_get_id {
    return "" unless ( user_get_meta() );

    return $user->getValue( "id" );
}

#
# Retrieve the user email from the RPC server
#
sub user_get_email {
    return "ERROR" unless ( user_get_meta() );

    # We need this to return a null like value when the email is not available
    return ( $user->getValue( "email" ) || "" );
}

#
# Detect if the user is an administrator or not
#
sub user_is_admin {
    return 0 unless ( user_get_meta() );

    return 0 unless $user->getValue( "admin_flag" );

    return 1;
}

#
# Detect if the user submissions default public
#
sub user_default_public {
    return 0 unless ( user_get_meta() );

    return 0 unless $user->getValue( "autopublic_flag" );

    return 1;
}

1;
