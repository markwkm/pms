package Tests::User;

use strict;
use PLM::PLM::User;
#use PLM::DB::Handle;
#use PLM::PLM;

sub login_ok {
    my $u = new PLM::PLM::User();

    if ( $u->verify( shift, shift ) ) { return 1 }

    return 0;
}

sub valid_user {
    my $u = new PLM::PLM::User();

    if ( $u->verify( shift ) ) { return 1 }

    return 0;
}

sub valid_password {
    my $u = new PLM::PLM::User();

    if ( $u->verify( shift, shift ) ) { return 1 }

    return 0;
}

sub invalid_user {
    my $u = new PLM::PLM::User();

    if ( $u->verify( shift ) ) { return 0 }

    return 1;
}

sub invalid_password {
    my $u = new PLM::PLM::User();

    if ( $u->verify( shift, shift ) ) { return 0 }

    return 1;
}

sub add {
    my $u = new PLM::PLM::User();

    if ( $u->add( shift, shift ) ) { return 1 }

    return 0;
}

sub change_password {
    my $user = shift || panic( "missing user" );
    my $pass = shift || panic( "missing pass" );

    my $u = new PLM::PLM::User();

    $u->password( $user, $pass );

    if ( $u->verify( $user, $pass ) ) { return 1 }

    return 0;
}

sub valid_delete {
    my $u = new PLM::PLM::User();

    if ( $u->delete( shift ) ) { return 1 }

    return 0;
}

sub invalid_delete {
    my $u = new PLM::PLM::User();

    if ( $u->delete( shift ) ) { return 0 }

    return 1;
}

sub set_option {
    my $user   = shift;
    my $option = shift;
    my $value  = shift;

    my $u = new PLM::PLM::User();

    unless ( $u->set_option( $user, $option, $value ) ) { return 0 }

    if ( $u->get_option( $user, $option ) eq $value ) { return 1 }

    return 0;
}

sub get_option {
    my $user   = shift;
    my $option = shift;
    my $value  = shift;

    my $u = new PLM::PLM::User();

    if ( $u->get_option( $user, $option ) eq $value ) { return 1 }

    return 0;
}

sub is_an_admin {
    my $u = new PLM::PLM::User();

    if ( $u->is_admin( shift ) ) { return 1 }

    return 0;
}

sub is_not_an_admin {
    my $u = new PLM::PLM::User();

    if ( $u->is_admin( shift ) ) { return 0 }

    return 1;
}

1;
