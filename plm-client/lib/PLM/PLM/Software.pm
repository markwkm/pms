# PLM::PLM::Software Package
#
# Author: 	Nathan Dabney
# Date:		02/28/02
#
# Presents a method reference to a Software object in the PLM data space.

package PLM::PLM::Software;

@ISA = qw( PLM::PLM );

use strict;
use PLM::Util::Log;
use PLM::DB::Handle;
use PLM::PLM;
use PLM::Util;

BEGIN { }

my $log = getLog( "PLM::PLM::Software" );

sub new {
    my $self = {};
    my $type = shift;
    bless $self, $type;

    $self->SUPER::new( "plm_software" );

    return $self;
}

sub debug {
    my ( $self, $debug ) = @_;

    if ( defined( $debug ) ) {
        $log->debug( $debug );
    }

    return $log->debug;
}

sub verify {
    my ( $self, $name ) = @_;
    my $dbh = getDBHandle();
    my $ref;

        $log->msg( 2, "verify( $name )" );

    unless ( $dbh->valid( $name ) ) { return 0 }

    $ref =
       $dbh->get( "s.id", "plm_software as s",
                  "s.name = '$name' AND " . "s.rsf = 1" );
    unless ( defined $ref ) { $log->msg( 0, "Unable to find id for $name" ) }

    unless ( defined $ref ) { return 0 }    # Debug already sent

    $log->msg( 0, "software $name found (ID: ${$ref}{id})" );

    return ${ $ref }{ id };
}

sub add_software {
    my ( $self, $name ) = @_;
    my $dbh = getDBHandle();
    my $now = time();

    $log->msg( 1, "add_software( $name )" );

    unless ( $dbh->valid( $name ) ) { return 0 }    # Bad characters

    if ( $self->verify( $name ) ) {
        $log->msg( 0, "add_software( $name ) failed, software already exists" );
        return 0;
    }

    if ( $dbh->get( "id", "plm_software", "name='$name'" ) ) {
        $log->msg( 0, "Re-enabling deleted software package: $name" );
        $dbh->update( "plm_software", "rsf = 1", "name = '$name'" );
    } else {
        $log->msg( 0, "Adding new software package: $name" );
        my $next = $dbh->next_index( "plm_software" );
        $dbh->do( "INSERT INTO plm_software (id, rsf, name, created) "
                  . "VALUES ($next, 1, '$name', '$now')" );
    }

    if ( $self->verify( $name ) ) {
        return $self->verify( $name );
    } else {
        return 0;
    }
}

sub search_sql {
    my ( $self, $table, $ref ) = @_;
    my $dbh = getDBHandle();
    my $sql;

    unless ( defined $ref ) {
        $log->msg( 0, "Missing search option(s) in search_sql" );
        return undef;
    }

    unless ( $table =~ /^plm_software$/ ) {
        $log->msg( 0, "Invalid table in search_sql [$table]" );
        return undef;
    }

    my %search = %{ $ref };

    for ( keys %search ) {
        $log->msg( 3, "Adding [$_] / [$search{$_}] to search list" );
        $sql .= "$_ = '" . $search{ $_ } . "' AND ";
    }

    $sql =~ s/\ AND\ $//;

    $log->msg( 2, "search_sql: $sql" );
    my $result = $dbh->getAll( "*", $table, $sql );
    my $num = @{ $result } || 0;

    if ( $num ) {
        $log->msg( 1, "Search returned $num results" );
    } else {
        $log->msg( 1, "No results found" );
        return undef;
    }

    return $result;
}

sub delete_software {
    my ( $self, $ID ) = @_;
    my $dbh = getDBHandle();

    $log->msg( 2, "delete_software( $ID )" );

    unless ( $dbh->valid( $ID ) ) {
        $log->msg( 0, "Request to delete an invalid package" );
        return 0;
    }

    unless ( $dbh->get( "id", "plm_software", "id = '$ID' " . "AND rsf = 1" ) )
    {
        $log->msg( 0, "Request to delete a previously deleted package" );
        return 0;
    }

    $dbh->update( "plm_software", "rsf = 0", "id = '$ID'" );

    unless ( $dbh->get( "id", "plm_software", "id = '$ID' " . "AND rsf = 0" ) )
    {
        $log->msg( 0, "Faliure in marking package as deleted" );
        return 0;
    }

    $log->msg( 0, "Software package $ID deleted correctly" );
    return 1;
}

END { }

1;

