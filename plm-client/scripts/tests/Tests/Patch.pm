package Tests::Patch;

use strict;
use warnings;
#use PLM::DB::Handle;
use PLM::PLM::Patch;
use PLM::XML::Patch;
#use PLM::PLM;

sub instantiate {
    my $p = new PLM::PLM::Patch();

    if ( defined $p ) { return 1 }

    return 0;
}

sub setValue {
    my $p   = new PLM::PLM::Patch();
    my $key = shift;
    my $val = shift;

    if ( $p->setValue( $key, $val ) ) { return 1 }

    return 0;
}

sub getValue {
    my $p   = new PLM::PLM::Patch();
    my $key = shift;
    my $val = shift;

    unless ( defined $key && defined $val ) { return 0 }

    $p->setValue( $key, $val );

    if ( $p->getValue( $key ) eq $val ) { return 1 }

    return 0;
}

sub add {
    my $patch = new PLM::PLM::Patch();
    my $xml   = new PLM::XML::Patch;

    $xml->setElementValue( "version",            ".0.-BETA" );
    $xml->setElementValue( "comment",            "This is a TEST PATCH" );
    $xml->setElementValue( "name",               "PLM_TEST" );
    $xml->setElementValue( "content",            "EMPTY PATCH CONTENT" );
    $xml->setElementValue( "content_format",     "plaintext" );
    $xml->setElementValue( "private_flag",       "1" );
    $xml->setElementValue( "submit_flag",        "1" );
    $xml->setElementValue( "plm_applies_id",     "1" );
    $xml->setElementValue( "plm_user_id",        "5" );
    $xml->setElementValue( "plm_software_id",    "10" );

    if ( $patch->add( \$xml ) ) { return 1 }

    return 0;
}

sub get {
    my $patch  = new PLM::PLM::Patch();
    my $search = shift;

    my $ref = $patch->search_sql( $search );
    unless ( defined $ref ) { return 0 }

    my %p = %{ ${ $ref }[ 0 ] };

    return 0 unless $patch->get( $p{ id } );

    unless ( $patch->getValue( "name" ) ) { return 0 }

    return 1;
}

sub search_sql {
    my $p      = new PLM::PLM::Patch();
    my $search = shift;

    if ( defined $p->search_sql( $search ) ) { return 1 }

    return 0;
}

sub delete {
    my $patch = new PLM::PLM::Patch();

    my $ref = $patch->search_sql( { name => "PLM_TEST_PATCH" } );

    unless ( defined $ref ) { return 0 }

    my @patches = @{ $ref };

    for ( @patches ) {
        unless ( $patch->delete( ${ $_ }{ id } ) ) { return 0 }
    }

    return 1;
}

1;
