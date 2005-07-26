
# validation test suite
# user tests go in here, such as authentication checks

package PLM::Validation::User;

use PLM::Validation::Suite;

use PLM::PLM::User;

# basic check to see if a user is authenticated
sub isAuthenticated {
    my $name = shift;
    my ( $username, $password ) = @_;

    # if either the username or password aren't defined, return failure
    if ( !defined( $username ) || !defined( $password ) ) {
        PLM::Validation::Suite::setFailureMessage(
                     "isAuthenticated: no " . "username and/or " . "password" );
        return 0;
    }

    # check the user_verify() call here
    my $user = new PLM::PLM::User();
    my $ret  = $user->verify( $username, $password );

    return $ret;
}

# basic check to see if a user is an admin
sub isAuthenticatedAdmin {
    my $name = shift;

    my ( $username , $password ) = @_;

    # if the username isn't defined, return failure
    if ( !defined( $username ) ) {
        PLM::Validation::Suite::setFailureMessage( "isAuthenticatedAdmin: no username" );

        return 0;
    }

    my $user = new PLM::PLM::User();
    # Check user and password
    my $ret  = $user->verify( $username, $password );
    if ( ! $ret ){
        return $ret;
    }
    # check the user_access_level() call here
    $ret  = $user->is_admin( $username );

    return $ret;
}

# check to see if the options set are possible for this user
sub canSetOption {
    my $name = shift;

    my ( $username, $password, $who, $option, $value ) = @_;

    # is the user trying to set the admin flag
    if ( $option =~ /admin_flag/i ) {
        if ( isAuthenicatedAdmin( "canSetOption", $username, $password ) ) {
            return 1;
        } else {
            PLM::Validation::Suite::setFailureMessage(
                                               "canSetOption: user not admin" );
            return 0;
        }
    }

    return 1;
}

1;
