# Result Set
#
# Author: Jerry Sievert
# Date: 10/29/01
#
# Result Set module, this is what's returned from a Database query.
#
# 	02/27/02 Nathan T. Dabney <smurf@osdl.org>
# 		 Added Util::Log functionality
# 		 Added execute & finish to new()
# 		 Added _echeck function & calls
#
# 	03/11/02 Nathan T. Dabney <smurf@osdl.org>
# 		 Added API to return reference to array of hash
# 		 Moved internal data to $self->{ _data } scalar (ref to above)

package PLM::DB::ResultSet;

use strict;
use DBI;
use PLM::Util;

my $log;

sub new {
    my $self = {};
    my $type = shift;
    my $sth  = shift;
    bless $self, $type;

    # We need the ability to detect class/noclass here

    $self->{ _data } = ();

    # see if we're instanciating without any arguments
    unless ( defined $sth ) {
        $self->{ numRows } = 0;
        return $self;
    }

    $log = PLM::Util::getLog( "PLM::DB::ResultSet" );

    $sth->execute;
    if ( $sth->err ){
        $log->msg( 0, "Error after execute:  " . $sth->err . ":" . $sth->errstr . "  rows  " . $sth->rows );
        $self->{ numRows } = 0;
        return $self;
    }

    # load the data from the database handle provided
    my @rows;
    $self->{ numRows } = $sth->rows;

    for ( my $i = 0; $i < $self->{ numRows }; $i++ ) {
        my $hash = $sth->fetchrow_hashref;
        if ( $sth->err ){
            $log->msg( 0, "Error after fetchrow_hashref:  " . $sth->err . ":" . $sth->errstr . "  rows  " . $sth->rows );
            die "Error after fetchrow_hashref";
        }
        $self->setRow( $i, $hash );
    }

    $sth->finish;
    return $self;
}

sub setRow {
    my ( $self, $row, $hash ) = @_;

    $self->{ _data }[ $row ] = $hash;
}

sub getProperty {
    my ( $self, $row, $property ) = @_;

    if ( $row > $self->{ numRows } || $row < 0 ) {
        ( "$row is outside of range (< 0 or > " . $self->{ numRows } . ")" );
    }

    if ( !defined( ${ $self->{ _data }[ $row ] }{ $property } ) ) {
        return "-BAD Column Name-";
    }

    return ${ $self->{ _data }[ $row ] }{ $property };
}

sub getNumRows {
    my ( $self ) = @_;

    return $self->{ numRows };
}

sub setNumRows {
    my ( $self, $numRows ) = @_;

    $self->{ numRows } = $numRows;
}

sub getDataRef {
    my $self = shift;

    return \@{ $self->{ _data } };
}

1;
