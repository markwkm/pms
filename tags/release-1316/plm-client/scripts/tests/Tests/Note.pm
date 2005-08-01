package Tests::Note;

use strict;
use PLM::DB::Handle;
use PLM::PLM::Note;
use PLM::XML::Note;

my $n;

sub instantiate {
    $n = new PLM::PLM::Note();

    if ( defined $n ) { return 1 }

    return 0;
}

sub setValue {
    my $key = shift;
    my $val = shift;

    return 0 unless $n->setValue( $key, $val );

    return 1;
}

sub getValue {
    my $key = shift;
    my $val = shift;

    return 0 unless ( $n->getValue( $key ) eq $val );

    return 1;
}

sub add {
    my $xml = new PLM::XML::Note();

    return 0 unless $xml;

    $xml->setElementValue( "subject",          "-TEST NOTE-" );
    $xml->setElementValue( "content",          "EMPTY NOTE CONTENT" );
    $xml->setElementValue( "plm_user_id",      "5" );
    $xml->setElementValue( "plm_note_type_id", "6" );

    my $noteID = $n->add( \$xml );

    return 0 unless $noteID;

    return 0 unless $n->getValue( "subject" ) eq "-TEST NOTE-";
    return 0 unless $n->getValue( "content" ) eq "EMPTY NOTE CONTENT";
    return 0 unless $n->getValue( "plm_user_id" ) eq "5";
    return 0 unless $n->getValue( "plm_note_type_id" ) eq "6";

    return 1;
}

sub get {
    my $search = shift;

    my $ref = $n->search_sql( $search );

    return 0 unless $ref;

    my %note = %{ ${ $ref }[ 0 ] };
    my $xml  = $n->get( $note{ id } );

    return 0 unless $xml;
    return 0 unless $xml->getElementValue( "id" ) eq $note{ id };

    return 1;
}

sub search_sql {
    my $search = shift;

    return 0 unless defined $n->search_sql( $search );

    return 1;
}

sub delete {
    my $search = shift;
    my $note   = new PLM::PLM::Note();

    my $ref = $note->search_sql( $search );

    return 0 unless $ref;

    for ( @{ $ref } ) {
        return 0 unless $note->delete( ${ $_ }{ id } );
    }

    $ref = $note->search_sql( $search );

    return 0 if $ref;

    return 1;
}

1;
