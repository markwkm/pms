# PLM::DATA Package
#
# Author:	Nathan Dabney
# Date:		07/11/02
#
# Presents a method reference to a generic object in the PLM data space

package PLM::DB::XML;

@ISA = qw( PLM::XML::QDXml );

use strict;
use PLM::XML::QDXml;
use PLM::DB::Handle;
use PLM::DB::Gateway;
use PLM::Util;

my $log = getLog( "PLM::DB::XML" );

my %table_cache;

sub new {
    my $self = shift;

    $self->{ dbh }        = getDBHandle();    # DB we are bound to
    $self->{ data }       = [];               # Internal XML
    $self->{ fields }     = ();               # For auto SQL builds
    $self->{ field_type } = {};               # 'bound' to DB? 'meta' only?
    $self->{ table }      = shift;            # Name of the table bound to

    return unless $self->{ table };           # Don't let this happen.

    $self->{ table } =~ /plm_(.*)/;
    $self->{ elementName } = $1 || $self->{ table };

    my $table = $self->{ table };

    if ( defined $table_cache{ $table } ) {
        $log->msg( 4, "Table [$table] XML cache HIT" );

        # Take the table definition from the cache
        $self->{ fields } = $table_cache{ $self->{ table } };

        # Setup each of the fields in XML as bound to the database
        for ( @{ $self->{ fields } } ) {
            $self->addElement( $_, "" );
            $self->{ field_type }{ $_ } = "bound";
        }
    } else {
        $log->msg( 4, "Table [$table] XML cache MISS" );

        # Grab the first entry in the database.  For meta-data parsing
        # The 'x'='x' is to accomodate the WHERE which is added in 'get' and add the LIMIT clause
        my $ref = $self->{ dbh }->get( "*", $self->{ table } , "'x'='x' LIMIT 1" );

        #  If the database is empty, we need to get fields anyway...
        if ( !$ref ) {
            $self->{ dbh }->do(
                               "INSERT INTO $self->{ table } (id) VALUES (0)" );
            $ref = $self->{ dbh }->get( "*", $self->{ table } );
            $self->{ dbh }->do( "DELETE FROM $self->{ table } WHERE id = 0" );
        }

        # Build the list of field types (bound to DB)
        # and add the Elements to the XML schema.  
        # (otherwise the data fields won't really be available)
        for ( keys %{ $ref } ) {
            $log->msg( 4, "addElement( $_ )" );
            $self->{ field_type }{ $_ } = "bound";
            $self->addElement( $_, "" );
            push @{ $self->{ fields } }, $_;
        }

        # Throw the new table definition into the cache
        $table_cache{ $self->{ table } } = $self->{ fields };

    }

    $self->{ auto_sync }   = 0;    # Start with auto-sync OFF
    $self->{ state_empty } = 1;    # Start with empty values

    $log->msg( 4, "New PLM::DB::XML object created [table: $self->{ table }]" );
    $log->msg( 4, "Fields: " . join ( ", ", @{ $self->{ fields } } ) );
}

sub disable_sync {
    my ( $self ) = @_;

    $self->{ auto_sync } = 0;
}

sub debug {
    my ( $self, $debug ) = @_;

    $log->debug( $debug ) if defined $debug;

    return $log->debug();
}

sub setValue {
    my ( $self, $key, $val ) = @_;
    my $id = $self->getElementValue( "id" );

    unless ( defined $key && defined $val ) {
        $log->msg( 0, "setValue( invalid options )" );
        return 0;
    }

    # Update the backend DB with the new data if needed
    if ( ( $self->{ auto_sync } )
         && ( $self->{ field_type }{ $key } )
         && ( $self->{ field_type }{ $key } eq "bound" ) )
    {
        $log->msg( 4, "auto-sync update: [ $self->{ table } | $key | $id ]" );
        my $data = $self->{ dbh }->quote( $val );
        $self->{ dbh }->update(
                                $self->{ table }, "$key = $data",
                                "id = $id"
        );

        # Update the modified time for this object
# DON'T update the mtime if the data being updated is either the ACCESSED
        # or CREATED flag.
        $self->mtime( time() ) if ( $key ne "accessed" && $key ne "created" );
    }

    # Update the local XML schema
    $self->setElementValue( $key, $val );

    if ( !$self->{ field_type }{ $key } ) {

        # We have a new element
        $self->addElement( $key, $val );
        $self->{ field_type }{ $key } = "auto";
    }

    return 1;
}

sub getValue {
    my ( $self, $key ) = @_;

    return undef unless ( defined $key );

    # Retrieve the local XML value for this key
    my $ret = $self->getElementValue( $key );

    return $ret;
}

sub unload {
    my ( $self ) = @_;

    $log->msg( 4, "unload() - freeing XML data" );

    # If we are already 'empty' we can return without doing anything
    return if ( $self->{ state_empty } );

    # Change the empty flag to true since it will be now :)
    $self->{ state_empty } = 1;

    # Turn XML->DB sync OFF - we don't want to clear the valid data!
    $self->{ auto_sync } = 0;

    # Set all the per-object non-external data to empty
    for ( @{ $self->{ fields } } ) {
        $self->setValue( $_, "" );
    }

    $log->msg( 4, "unload() - DONE" );
}

sub load {
    my ( $self, $id , $ref) = @_;

    $self->unload();    # Clear out old data

    panic( "missing table" ) unless $self->{ table };

    # Grab the actual data from the backend database
    if (! $ref){
        $ref = $self->{ dbh }->get( "*", $self->{ table }, "id = '$id'" );
    }

    unless ( $ref ) {    # return - on failure
        $log->msg( 0, "load( $id ) FAILED" );
        return 0;
    }
    else {
        $log->msg( 4, "load( $id ) DB retrieval OK, Loading to XML..." );
    }

    # Load the DB data into the XML schema
    for ( keys %{ $ref } ) {
        if ( defined ${ $ref }{ $_ } ) {
            $self->setValue( $_, ${ $ref }{ $_ } );
        }
    }

    # Since we now have a full valid XML schema, we want auto sync ON
    $self->{ auto_sync }   = 1;
    $self->{ state_empty } = 0;

    return 1;
}

# Verify a specific ID exists in this table
sub verify_id {
    my ( $self, $ID ) = @_;
    my $dbh = $self->{ dbh };

    panic( "verify_id( invalid ID: $ID )" ) unless $dbh->valid( $ID );

    my $ref = $dbh->get( "id", $self->{ table }, "id = '$ID'" );

    unless ( $ref ) {
        $log->msg( 1, "verify_id( $ID ) - INVALID" );
        return 0;
    }

    $log->msg( 2, "verify_id( $ID ) - VALID" );

    return 1;
}

# Master routine for adding new objects to the database.
# This can be given a XML schema to incorporate from somewhere else OR
# it can work on a previously built internal XML object
sub add {
    my ( $self, $xml_ref ) = @_;
    my $dbh    = $self->{ dbh };
    my @fields = @{ $self->{ fields } };
    my $table  = $self->{ table };

    if ( $xml_ref ) {
        $self->{ xml } = ${ $xml_ref };
    }

    # We want to force sync updates OFF for the duration of the add()
    $self->{ auto_sync } = 0;

    panic( "missing table" ) unless $table;

    # Update all time values
    $self->ctime( time() );
    $self->mtime( time() );
    $self->atime( time() );

    $self->setValue( "rsf", 1 );

    $dbh->connect();

    my $dbHandle = $dbh->{ _dbh };
    my $id       = $dbh->next_index( $table );
    $self->setValue( "id", $id );

    panic( "Unable to get next $table ID" ) unless $id;

    $log->msg( 2, "New database entry [id: $id table: $table]" );
    my @data;
    for ( @fields ) {
        push @data, $self->getValue( $_ );
    }

    my $holders = "?," x ( @data );
    $holders =~ s/\?,$/\?/;

    $log->msg( 2, "SQL INSERT via dbHandle (not logged) [$table]" );

    # Do the actual add to the database.  Note this uses the DBI $dbh NOT
    # the DBH from the PLM::DB::Handle class.  This is because it has to be able
    # to handle binary data.  This requirement will go away when the PLM::DB::Handle
    # level goes to a hash based representation system.
    $dbHandle->do( "INSERT INTO $table("
                   . ( join ",", @fields )
                   . " ) VALUES ( $holders ) ", undef, @data );

    $dbh->disconnect();

    # Double check to make sure the adding of the object worked
    unless ( $self->verify_id( $id ) ) {
        $log->msg( 0, "Failure in adding entry, unknown cause, FUBAR" );
        return 0;
    }

    # Since we now have a full XML schema object, we want updates ON
    $self->{ auto_sync } = 1;

    return $id;
}

sub delete {
    my ( $self, $id ) = @_;
    my $table = $self->{ table };

    $log->msg( 1, "delete( $id )" );

    return 0 unless $id;

    # return 0 (fail) if the user does not exist in the database
    unless ( $self->verify_id( $id ) ) {
        $log->msg( 0, "Unable to delete $id from $table, missing" );
        return 0;
    }

    # do the actual delete
    $self->{ dbh }->delete( $table, "id = $id" );

    # double check to make sure the delete worked
    if ( $self->verify_id( $id ) ) {
        $log->msg( 0, "Unknown failure in deleting $id from $table" );
        warn "Unknown failure in deleting $id from $table";
        return 0;
    }

    $self->unload();

    return 1;
}

sub search_sql {
    my ( $self, $ref ) = @_;
    my $dbh = $self->{ dbh };
    my $sql;
    my %meta;

    unless ( $ref ) {
        $log->msg( 0, "Missing search option in search_sql" );
        return undef;
    }

    # We passed by reference to save memory.  go us. 
    my %search = %{ $ref };

    $meta{ order } = "id";
    $meta{ limit } = 100000;

    # Build the list of search terms (tokens)
    for ( keys %search ) {
        my $key = $_;
        if ( defined $meta{ $key } ) {
            $meta{ $key } = $search{ $key };
        } else {
            $log->msg( 4, "Adding [$key] / [$search{$key}] to search list" );
            if ( $search{ $key } =~ /^(\<|\>)(\d+)$/s ) {
                $sql .= "$key $1 $2 AND ";
            } else {
                $sql .= "$key LIKE '$search{$key}' AND ";
            }
        }
    }

    # Yay for SQL generation
    if ( $sql && $sql =~ /.*\ AND\ $/ ) {
        $sql =~ s/(.*)\ AND\ $/$1/;
    }

    # Throw order and limit on there...
    $sql .= " ORDER BY $meta{order} LIMIT $meta{limit}";

    # Log what we are giong to do:
    if ( $sql ) {
        $log->msg( 3, "search_sql: [$self->{table}]: WHEN $sql" );
    } else {
        $log->msg( 3, "search_sql: [$self->{table}]" );
    }

    # search_sql returns a list of all the objects matching, not just the first
    my $res = $dbh->getAll( "*", $self->{ table }, $sql );
    my $num = @{ $res };

    # return undef if no results were found
    unless ( $num ) {
        $log->msg( 2, "No results found in search" );
        return undef;
    }

    # log the number of results found
    $log->msg( 2, "Search [$self->{table}] returning $num results" );

    return $res;
}

# update the ACCESSED time for an object through the setValue() method
sub atime {
    my ( $self, $now ) = @_;

    return unless $self->{ field_type }{ accessed };

    $self->setValue( "accessed", $now ) if $now;

    return $self->getValue( "accessed" );
}

# update the MODIFIED time for an object through an INTERNAL duplicate of the
# setValue() method.  This is done because the setValue method also calls
# mtime() when it's acting on anything but ACCESSED or CREATED
sub mtime {
    my ( $self, $now ) = @_;
    my $update = 0;

    return unless $self->{ field_type }{ modified };

    $update = 1 if ( $self->{ field_type }{ modified } eq "bound" );
    $update = 1 if ( $update && $self->{ auto_sync } );

    $self->setElementValue( "modified", $now ) if $now;
    return $self->getElementValue( "modified" ) unless $update;

    my $id = $self->getElementValue( "id" );
    if ( $now && $id ) {
        $log->msg( 4, "auto-sync mtime: [ $self->{ table } | $now ]" );
        my $table = $self->{ table };
        $self->{ dbh }->update( $table, "modified = $now", "id = $id" );
    }

    return $self->getElementValue( "modified" );
}

# update the CREATED time for an object through the setValue() method
sub ctime {
    my ( $self, $now ) = @_;

    return unless $self->{ field_type }{ created };

    $self->setValue( "created", $now ) if $now;

    return $self->getValue( "created" );
}

1;
