package Tests::Software;

use strict;
#use PLM::DB::Handle;
use PLM::PLM::Software;
#use PLM::PLM;

sub instantiate {
    my $p = new PLM::PLM::Software();

    if ( defined $p ) { return 1 }

    return 0;
}

sub verify {
    my $soft = new PLM::PLM::Software();
    my ( $x, $y ) = @_;

    if ( defined $y ) {
        if ( $soft->verify( $x, $y ) ) { return 1 }
    } else {
        if ( $soft->verify( $x ) ) { return 1 }
    }

    return 0;
}

sub add_software {
    my $soft = new PLM::PLM::Software();
    my $name = shift;

    if ( $soft->add_software( $name ) ) { return 1 }

    return 0;
}

sub delete_software {
    my $soft = new PLM::PLM::Software();
    my $name = shift;

    my $softwareID = $soft->verify( $name );

    if ( $soft->delete_software( $softwareID ) ) { return 1 }

    return 0;
}

1;
