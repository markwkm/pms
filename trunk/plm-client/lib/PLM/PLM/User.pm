# PLM::PLM::User Package
#
# Author: 	Nathan Dabney
# Date:		01/04/02
#
# Presents a method reference to a User object in the PLM data space.

package PLM::PLM::User;

@ISA = qw( PLM::PLM );

use strict;
use PLM::Util::Log;
use PLM::DB::Gateway;
use PLM::PLM;
use PLM::Util;

BEGIN { }

my $log = getLog( "PLM::PLM::User" );

sub new {
    my $self = {};
    my $type = shift;
    bless $self, $type;

    $self->SUPER::new( "plm_user" );

    return $self;
}

sub debug {
    my ( $self, $debug ) = @_;

    $log->debug( $debug )       if defined $debug;
    $self->SUPER::log( $debug ) if defined $debug;

    return $log->debug;
}

sub _getUser {
    my ( $self, $user, $pass ) = @_;
    my $dbh = $self->{ dbh };

    $self->unload();
    my $ref = $self->search_sql( { name => $user } );
    $self->load( ${ $ref }[ 0 ]{ id } ) if $ref;

    # Attempt to get password from external source
    my $gw = getGatewayID( "plm_user", "pass" );
    if ( $gw ) {
        my $gwDBH   = getGatewayDBH( $gw );
        my $gwTable = getGatewayTable( $gw, "plm_user" );
        my $gwUser  = getGatewayField( $gw, "user" );
        my $ref     = $gwDBH->get( "*", $gwTable, "$gwUser = '$user'" );

        my $gwPass = getGatewayField( $gw, "pass" );
        if ( defined ${ $ref }{ $gwPass } ) {
            if ( !$self->getValue( "id" ) ) {
                $log->msg( 0, "User exists in Gateway only, adding to PLM" );
                if ( $pass ) {
                    $self->add( $user, $pass );
                } else {
                    $self->add( $user, "*" );
                }
                my $ref = $self->search_sql( { name => $user } );
                $self->load( ${ $ref }[ 0 ]{ id } ) if $ref;
            }
            $self->setValue( "pass", ${ $ref }{ $gwPass } );
        } else {
            $log->msg( 1, "User $user does not exist in Gateway" );
        }

        my $gwEmail = getGatewayField( $gw, "email" );
        if ( defined ${ $ref }{ $gwEmail } ) {
            if ( ${ $ref }{ $gwEmail } ne $self->getValue( "email" ) ) {
                $self->setValue( "email", ${ $ref }{ $gwEmail } );
            }
        }
    }
}

sub login {
    if ( @_ < 2 ) { panic( "verify() bad syntax" ) }
    my ( $self, $user, $pass ) = @_;
    my $dbh = $self->{ dbh };

    $log->msg( 0, "login( $user )" );
    return 0 unless defined $user && $dbh->valid( $user );

    $self->_getUser( $user, $pass );

    unless ( $self->getValue( "name" ) ) {
        $log->msg( 3, "login: No such user [$user]" );
        return 0;
    }

    $self->atime( time() );

    unless ( defined $pass ) {
        $log->msg( 3, "login: User [$user] found - no password tried" );
        return $self->getValue( "id" );
    }

    return 0 if ( $pass eq "*" );

    if (
         crypt( $pass, $self->getValue( "pass" ) ) ne $self->getValue( "pass" )
      )
    {
        $log->msg( 3, "login: Password for user $user is INVALID" );
        return 0;
    } else {
        my $id = $self->getValue( "id" );
        $log->msg( 3, "login:  Password for user $user is VALID [$id]" );
        return $id;
    }
}

# BACKWARDS COMPATIBLE API STUB
sub verify {
    my $self = shift;

    return $self->login( @_ );
}

sub add {
    my ( $self, $user, $pass ) = @_;
    if ( @_ != 3 ) { panic( "add() bad syntax" ) }

    return 0 if $pass && $pass ne "*" && $self->verify( $user );

    $self->unload();

    $self->setValue( "name",            $user );
    $self->setValue( "pass",            crypt( $pass, int( rand 1000 ) ) );
    $self->setValue( "autopublic_flag", 1 );
    $self->setValue( "rsf",             1 );

    return $self->SUPER::add();
}

sub delete {
    if ( @_ != 2 ) { panic( "delete() bad syntax" ) }

    my ( $self, $user ) = @_;

    my $uid = $self->verify( $user );

    $log->msg( 2, "delete( $user ) uid: $uid" );

    return 0 unless $uid;

    if ( $self->SUPER::delete( $uid ) ) {
        $log->msg( 0, "user $user [$uid] deleted OK" );
        return 1;
    } else {
        $log->msg( 0, "problem deleting $user [$uid]" );
        return 0;
    }
}

sub is_admin {
    if ( @_ != 2 ) { panic( "id_admin() bad syntax" ) }

    my ( $self, $user ) = @_;

    if ( $self->get_option( $user, "admin_flag" ) ) {
        $log->msg( 3, "is_admin: $user does have the admin_flag set" );
        return 1;
    }

    $log->msg( 3, "is_admin: $user does not have the admin_flag set" );
    return 0;
}

sub password {
    if ( @_ != 3 ) { panic( "password() bad syntax" ) }

    my ( $self, $user, $pass ) = @_;
    my $dbh = $self->{ dbh };
    my $sec = crypt( $pass, int( rand 10000 ) );
    my $now = time;

    unless ( $self->verify( $user ) ) { return 0 }

    $dbh->update( "plm_user", "pass='$sec', modified=$now, accessed=$now",
                  "name='$user'" );

    my $old_sec = ${ $dbh->get( "pass", "plm_user", "name='$user'" ) }{ pass };
    if ( $old_sec eq $sec ) {
        $log->msg( 2, "Password changed for [$user]" );
        return 1;
    } else {
        $log->msg( 2, "Error changing password for [$user]" );
        return 0;
    }
}

sub set_option {
    if ( @_ != 4 ) { panic( "set_option() bad syntax" ) }

    my ( $self, $user, $flag, $value ) = @_;
    my $dbh = $self->{ dbh };
    my $now = time;

    unless ( defined $value ) {
        panic( "missing value in set_option()" );
    }
    unless ( $self->verify( $user ) ) {
        $log->msg( 2, "Can't set option for non-existant user" );
        return 0;
    }

    unless (
        defined ${ $dbh->get( "$flag", "plm_user", "name='$user'" ) }{ $flag } )
    {
        panic( "option $flag does not exist" );
    }

    $log->msg( 2, "Setting option $flag to $value for user $user" );

    $dbh->update( "plm_user", "$flag='$value', modified=$now, accessed=$now",
                  "name='$user'" );

    if ( $self->get_option( $user, $flag ) eq $value ) {
        $log->msg( 1, "flag '$flag' updated to '$value' for user '$user'" );
    } else {
        $log->msg( 1,
                "ERROR in updating flag '$flag' to '$value' for user '$user'" );
    }

    return 1;
}

sub get_option {
    if ( @_ != 3 ) { panic( "get_option() bad syntax" ) }

    my ( $self, $user, $flag ) = @_;
    my $dbh = $self->{ dbh };
    my $value;

    $log->msg( 2, "Getting option: [$flag]" );

    unless ( $self->verify( $user ) ) {
        $log->msg( 2, "Can't get option for non-existant user" );
        return undef;
    }

    $value = ${ $dbh->get( "$flag", "plm_user", "name=\'$user\'" ) }{ $flag };

    unless ( defined $value ) {
        panic( "option $flag does not exist" );
    }

    $log->msg( 3, "option [$flag] is set to: [$value]" );

    return ( $value );
}

END { }

1;

