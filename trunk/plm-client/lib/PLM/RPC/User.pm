
# module responsible for user functions

package PLM::RPC::User;

use PLM::Validation::Suite;
use PLM::PLM::User;
use PLM::Util;

require Exporter;
@ISA = qw( Exporter );

# symbols to export by default

@EXPORT = qw(
  user_verify
  user_add
  user_delete
  user_password
  user_set_option
  user_get_option
  user_find_by_email
  user_get_info 
  user_get_email );

BEGIN { }

my $log = getLog( "PLM::RPC::User" );

# verify a user (login)
sub user_verify {
    shift;                  # Package name, may be including package if called from SOAP
    my ( $username, $password ) = @_;
    my $User = new PLM::PLM::User();

    my $ret = $User->verify( $username, $password );

    return $ret;
}

# add a user
sub user_add {
    my ( $username, $password ) = @_;
    my $user = new PLM::PLM::User();

    return 0 unless PLM::Validation::Suite::validate( "user_add", @_ );

    my $ret = $user->add( $username, $password );

    return $ret;
}

# delete a user
sub user_delete {
    my ( $username, $password, $delete_user ) = @_;
    my $user = new PLM::PLM::User();

    return 0 unless PLM::Validation::Suite::validate( "user_delete", @_ );

    my $ret = $user->delete( $delete_user );

    return $ret;
}

# change a password
sub user_password {
    my ( $username, $oldpassword, $newpassword ) = @_;
    my $user = new PLM::PLM::User();

    return 0 unless PLM::Validation::Suite::validate( "user_password", @_ );

    $user->password( $username, $newpassword );

    my $ret = $user->verify( $username, $newpassword );

    return 1 if $ret;
    return 0;
}

# set a user option
sub user_set_option {
    my ( $username, $password, $who, $option, $value ) = @_;
    my $user = new PLM::PLM::User();

    return 0 unless PLM::Validation::Suite::validate( "user_set_option", @_ );

    my $ret = $user->set_option( $who, $option, $value );

    return $ret;
}

# get a user option
sub user_get_option {
    my ( $username, $password, $who, $option ) = @_;
    my $user = new PLM::PLM::User();

    return 0 unless PLM::Validation::Suite::validate( "user_get_option", @_ );

    my $ret = $user->get_option( $who, $option );

    return $ret;
}

# find a user by email
# it becomes really confusing here -- we're actually doing some
# data parsing, and work here, where as everywhere else, we're
# acting as a pass-thru
sub user_find_by_email {
    shift;                  # Package name, may be including package if called from SOAP
    my ( $username ) = @_;
    my $user = new PLM::PLM::User();

    my $data = $user->search_sql( { email => $username } );

    return "" unless $data;    # Return an empty string if nothing is found

    my $ret = ${ $data }[ 0 ]{ name };    # Yay for perl data structures

    return $ret;
}

# This function should be _private_
sub user_get_email {
    $self=shift;
    my ( $username ) = @_;
    my $user = new PLM::PLM::User();

    my $data = $user->get_option( $username, 'email' );

    return $data;
}

# Retrieve a XML doc of the USER's attributes
sub user_get_info {
    shift;                  # Package name, may be including package if called from SOAP
    my ( $username, $password, $target_user ) = @_;
    my $user = new PLM::PLM::User();

    return ""
      unless ( ( $username eq $target_user )
               || PLM::Validation::User::isAdmin( @_ ) );

    my $id = $user->verify( $target_user );

    return "" unless $id;

    $user->unload();
    return "" unless ( $user->load( $id ) );

    $user->disable_sync();
    $user->setValue( "pass", "HIDDEN" );

    return $user;
}

END { }

1;

