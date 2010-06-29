# PLM::PLM::Note Package
#
# Author:	Nathan Dabney
# Date:		06/17/02
#
# Presents a method reference to a Note object in the PLM data space

package PLM::PLM::Note;

use strict;
use PLM::Util::Log;
use PLM::DB::Handle;
use PLM::XML::Note;
use PLM::Util;

my $log = getLog( "PLM::PLM::Note" );

sub new {
    my $self = {};
    my $type = shift;
    bless $self, $type;

    $self->{ dbh } = getDBHandle();
    $self->{ xml } = undef;

    $log->msg( 3, "New PLM::PLM::Note object created" );

    return $self;
}

sub debug {
    my ( $self, $debug ) = @_;

    $log->debug( $debug ) if defined $debug;

    return $log->debug();
}

sub setValue {
    my ( $self, $key, $val ) = @_;

    return 0 unless ( defined $key && defined $val );

    $self->{ xml } = new PLM::XML::Note() unless $self->{ xml };

    $self->{ xml }->setElementValue( $key, $val );

    return 1;
}

sub getValue {
    my ( $self, $key ) = @_;

    return undef unless ( defined $key );

    $self->{ xml } = new PLM::XML::Note() unless $self->{ xml };

    return $self->{ xml }->getElementValue( $key );
}

sub verify {
    my ( $self, $noteID ) = @_;
    my $dbh = $self->{ dbh };

    panic( "verify( invalid ID )" ) unless $dbh->valid( $noteID );

    my $ref = $dbh->get( "id", "plm_note", "id = '$noteID'" );

    unless ( $ref ) {
        $log->msg( 2, "verify($noteID) - invalid" );
        return 0;
    }

    $log->msg( 2, "verify($noteID) - valid" );

    return 1;
}

sub add {
    my ( $self, $xml_ref ) = @_;
    my $dbh    = $self->{ dbh };
    my @fields =
      qw(created accessed plm_user_id plm_note_type_id subject content);

    if ( $xml_ref ) {
        $self->{ xml } = ${ $xml_ref };
    }

    panic( "missing xml" ) unless defined $self->{ xml };

    $dbh->connect();

    my $dbHandle = $dbh->{ _dbh };
    my $id       = $dbh->next_index( "plm_note" );

    panic( "Unable to get next plm_note ID" ) unless $id;

    $log->msg( 2, "Adding new note to the database [id: $id]" );
    my @data;
    for ( @fields ) {
        push @data, $self->getValue( $_ );
    }

    $dbHandle->do( "INSERT INTO plm_note(id, rsf, "
                  . ( join ",", @fields )
                  . " ) VALUES ( $id , 1 , ?, ?, ?, ?, ?, ? ) ", undef, @data );

    my $ref =
      $dbh->get( "id", "plm_note", "id = $id AND created = "
                 . $self->getValue( "created" ) );

    $dbh->disconnect();

    unless ( $ref ) {
        $log->msg( 0, "Failure in adding note, unknown" );
        return 0;
    }

    return $id;
}

sub get {
    my ( $self, $id ) = @_;
    my $dbh    = $self->{ dbh };
    my @fields = qw(id created accessed plm_user_id plm_note_type_id
      subject content);

    panic( "missing id in get()" ) unless $id;

    $log->msg( 0, "get($id)" );

    $self->{ xml } = new PLM::XML::Note();

    my $ref = $dbh->get( "*", "plm_note", "id = $id" );

    unless ( defined $ref ) {
        $log->msg( 0, "SQL query returned empty for get($id) query" );
        return undef;
    }

    $self->{ xml } = undef;
    for ( keys %{ $ref } ) {
        if ( defined ${ $ref }{ $_ } ) {
            $self->setValue( $_, ${ $ref }{ $_ } );
        }
    }

    unless ( $self->getValue( "id" ) ) {
        $log->msg( 0, "ERROR, id missing from returned get($id) query" );
        return undef;
    }

    return $self->{ xml };
}

sub delete {
    my ( $self, $id ) = @_;
    my $dbh = $self->{ dbh };

    return 0 unless $self->verify( $id );

    $dbh->delete( "plm_note", "id = $id" );

    return 0 if $self->verify( $id );

    return 1;
}

sub search_sql {
    my ( $self, $ref ) = @_;
    my $dbh = $self->{ dbh };
    my $sql;

    unless ( $ref ) {
        $log->msg( 0, "Missing search option in search_sql" );
        return undef;
    }

    my %search = %{ $ref };

    for ( keys %search ) {
        $log->msg( 4, "Adding [$_] / [$search{$_}] to search list" );
        $sql .= "$_ = '$search{$_}' AND ";
    }

    $sql =~ s/(.*)\ AND\ $/$1/;

    $log->msg( 3, "search_sql: $sql" );

    my $res = $dbh->getAll( "*", "plm_note", $sql );
    my $num = @{ $res };

    unless ( $num ) {
        $log->msg( 2, "No results found in search" );
        return undef;
    }

    $log->msg( 2, "Search returning $num results" );
    return $res;
}

1;
