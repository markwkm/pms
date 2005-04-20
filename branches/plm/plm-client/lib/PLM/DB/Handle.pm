# Database Package
#
# Authors:  
#   Jerry Sievert
#   Nathan Dabney
#
# Database module, given a config file, handle all interface with the
# database, as well as track/store everything.
#

package PLM::DB::Handle;

use strict;
use DBI;
use PLM::DB::ResultSet;
use PLM::Util;

#use Apache::Constants qw( :common );    # mod_perl shared DB pool stuff
#use vars qw( $DBH );

my $log;

sub new {
    my $type = shift;
    my $self = {};
    bless $self, $type;

    $log = PLM::Util::getLog( "PLM::DB::Handle" );

    if ( @_ < 1 ) { panic( "Incorrect syntax for PLM::DB::Handle->new()" ) }
    my $configRef = shift;

    $self->{ _NS }        = undef;
    $self->{ _dbh }       = "";
    $self->{ _dbh_lock }  = 0;
    $self->{ _resultSet } = {};

    if ( defined $configRef ) { $self->config( $configRef ) }

    return $self;
}

sub config {
    my $self = shift;
    my %cfg  = %{ ( shift ) };

    for ( keys( %cfg ) ) {
        $self->{ $_ } = $cfg{ $_ };
        $log->msg( 3, "Config [$_] = [$cfg{$_}]" );
        if ( $self->{ $_ } eq "" ) { $self->{ $_ } = undef }
        if ( $_ =~ /debug/i )     { $self->debug( $self->{ $_ } ) }
        if ( $_ =~ /namespace/i ) { $self->nameSpace( $self->{ $_ } ) }
    }
}

sub debug {
    my $self  = shift;
    my $debug = shift || undef;

    if ( defined( $debug ) ) { $log->debug( $debug ) }

    return $log->debug;
}

sub nameSpace {
    my ( $self, $ns ) = @_;

    if ( $ns ) {
        $log->msg( 3, "Setting namespace to: $ns" );
        $self->{ _NS } = $ns;
    }

    return $self->{ _NS };
}

sub _echeck {
    my $self = shift;

    #db_echeck( $self->{ _dbh }, "old _echeck()" );

    unless ( $self->{ _dbh } ) {
        $log->msg( 2, "debug: user: '$self->{user}' pass:'$self->{pass}'" );
        panic( "missing database reference" );
    }

    if ( defined( $self->{ _dbh }->err ) || defined( $self->{ _dbh }->errstr ) )
    {
        $log->msg( 0, "Database returned error: " . $self->{ _dbh }->err );
        $log->msg( 0, "Translation: " . $self->{ _dbh }->errstr );
        $log->msg( 2, "debug: user:'$self->{user}' pass:'$self->{pass}'" );
        exit 1;
    }
}

sub connect {
    my $self = shift;

    unless ( $self->{ dsn } )  { panic( "Missing DSN" ) }
    unless ( $self->{ user } ) { panic( "Missing Username for DSN" ) }
    unless ( $self->{ pass } ) { panic( "Missing Password for DSN" ) }

    unless ( $self->{ _dbh } ) {

#$DBH ||= DBI->connect( $self->{ dsn }, $self->{ user }, $self->{ pass },
#                     { RaiseError => 0, PrintError => 1, AutoCommit => 1 } );

        $self->{ _dbh } = DBI->connect(
                                        $self->{ dsn },
                                        $self->{ user },
                                        $self->{ pass },
                                        {
                                            RaiseError => 0,
                                            PrintError => 1,
                                            AutoCommit => 1
                                        }
        );

        #$self->{ _dbh } = $DBH;
        $self->_echeck;
    }

    $self->{ _dbh_lock }++;

    if ( $self->{ _dbh_lock } == 1 ) {
        $log->msg( 3, "Connecting to the database (pool)" );
    }

    return $self->{ _dbh };
}

sub disconnect {
    my $self = shift;

    return;    #This is now a no-op

    $self->{ _dbh_lock }--;

    if ( $self->{ _dbh_lock } == 0 ) {
        $log->msg( 3, "Disconnecting from the database" );
        $self->{ _dbh }->disconnect;
        $self->_echeck;
    } else {
        $log->msg( 5,
                 "Decreasing count for \$dbh_lock to " . $self->{ _dbh_lock } );
    }

    if ( $self->{ _dbh_lock } < 0 ) {
        $log->msg( 1, "Database count less than zero, RESET" );
        $self->{ _dbh_lock } = 0;
    }
}

sub dbh {
    my $self = shift;

    return $self->{ _dbh };
}

sub _do {
    my $self = shift;
    my $sql  = shift || panic( "missing sql in _do" );

    $log->msg( 3, "(_DO) SQL: $sql" );

    $self->connect;
    my $result = $self->{ _dbh }->do( $sql );
    $self->_echeck;
    $self->disconnect;

    return $result;
}

sub valid {
    my ( $self, $data ) = @_;
    if ( @_ != 2 ) { panic( "valid() bad syntax" ) }

    return unless ( $data );

    $self->connect();
    my $dbh = $self->{ _dbh };

    if ( "'$data'" ne $dbh->quote( $data ) ) {
        $log->msg( 0,
                   "valid($data) - failed: quote(): " . $dbh->quote( $data ) );
        $self->disconnect();
        return 0;
    }

    $self->disconnect();

    $log->msg( 3, "valid( $data ) checked out OK" );
    return 1;
}

sub do {
    my $self = shift;
    my $sql  = shift || panic( "missing sql in do()" );

    $log->msg( 2, "(DO) SQL: $sql" );

    $self->connect;
    my $result = $self->{ _dbh }->do( $sql );
    $self->_echeck;
    $self->disconnect;

    return $result;
}

sub _insert {
    my $self  = shift;
    my $table = shift || panic( "missing table in call to _insert" );

    $self->connect;
    my $id = $self->next_index( $table );
    $self->_do( "INSERT INTO $table (id, rsf) VALUES ($id, 1)" );
    $self->disconnect;

    return $id;
}

sub insert {
    my $self  = shift;
    my $table = shift || panic( "missing table in call to insert" );
    my $set   = shift || undef;

    $self->connect;
    my $id = $self->_insert( $table );
    if ( defined( $set ) ) {
        $self->update( $table, $set, "id=$id" );
    }
    $self->disconnect;

    return $id;
}

sub update {
    my $self  = shift;
    my $table = shift || panic( "missing table in call to update" );
    my $set   = shift || panic( "missing set in call to update" );
    my $where = shift || panic( "missing where in call to update" );

    $log->msg( 4, "update( $table, $set, $where )" );

    return $self->_do( "UPDATE $table SET $set WHERE $where" );
}

sub delete {
    my $self  = shift;
    my $table = shift || panic( "missing table in call to delete" );
    my $where = shift || panic( "missing where in call to delete" );

    $log->msg( 4, "delete( $table, $where )" );

    $self->_do( "DELETE FROM $table WHERE $where" );
}

sub quote {
    my $self = shift;
    my $data = shift;

    $self->connect;
    my $txt = $self->{ _dbh }->quote( $data );
    $self->disconnect;

    return $txt;
}

sub get {
    my $self = shift;

    # Returns only the first row.  Use getAll for all rows
    return ( ${ $self->getDataRef( $self->getResultSet( @_ ) ) }[ 0 ] );
}

sub getAll {
    my $self = shift;

    return ( $self->getDataRef( $self->getResultSet( @_ ) ) );
}

sub next_index {
    my ( $self, $table ) = @_;
    my $iList = $self->{ _NS } . "index";
    my $r     = int( rand 999999999 );
    my $key   = $r + 1;
    my $val   = 0;

    unless ( $table ) { panic( "next_index missing table" ) }
    unless ( $self->{ _NS } ) { panic( "missing name space" ) }

    $self->connect;

    while ( $key != $r ) {
        $val = ${ $self->get( "*", $iList, "token='$table'" ) }{ value };
        $self->update(
                       $iList,
                       "value=$val + 1, lock_key='$r' ",
                       "token='$table' AND value=$val"
        );
        $key = ${ $self->get( "*", $iList, "token='$table'" ) }{ lock_key };
    }

    $self->disconnect;

    return ( $val + 1 );
}

sub getResultSet {
    my $self = shift;
    my $sql;

    $sql = "SELECT " . shift || panic( "missing fields in getResultSet" );
    $sql .= " FROM " . shift || panic( "missing table in getResultSet" );

    my $where = shift || "";
    if ( $where ne "" ) { $sql .= " WHERE " . $where }

    $log->msg( 4, "(RS) SQL: $sql" );

    $self->connect;
    $self->{ _resultSet } =
      new PLM::DB::ResultSet( $self->{ _dbh }->prepare( $sql ) );
    $self->disconnect;

    return $self->{ _resultSet };
}

sub returnResultSet {
    my $self = shift;

    return $self->{ _resultSet };
}

sub setResultSet {
    my $self = shift;

    $self->{ _resultSet } = shift || panic( "missing ResultSet" );
}

sub getProperty {
    my ( $self, $row, $property ) = @_;

    return $self->{ _resultSet }->getProperty( $row, $property );
}

sub getNumRows {
    my $self = shift;
    my $rs   = shift || $self->{ _resultSet };

    return $rs->getNumRows;
}

sub getDataRef {
    my $self = shift;
    my $rs   = shift || $self->returnResultSet;

    return $rs->getDataRef;
}

1;

=head1 Header

 Perl abstraction from Database interaction and connection management.

=head1 SYNOPSIS

 use PLM::DB::Handle;

 $dbh->config( { token => value } );
	
 $dbh = new PLM::DB::Handle( { dsn  => "dsn", 
                          user => "user", 
		          pass => "pass" } );

 # Force connection management (not required, ever)
 $dbh->connect;
 $dbh->disconnect;

 # General database interaction
 $rv = $dbh->update( "table", "set", "where" );
 $rv = $dbh->delete( "table", "where );

 # Generic data select
 $hashRef            = $dbh->get( "fields", "table", "where" );
 $arrayRefOfHashRefs = $dbh->getAll( "fields", "table", "where" );
	
 # ResultSet data management specific
 $rs = $dbh->getResultSet( "fields", "table", "where" );
 $rs = $dbh->returnResultSet;
 $rv = $dbh->getNumRows;
 $rv = $dbh->getProperty( $row, "field" );
 $arrayRefOfHashRefs = $dbh->getDataRef;
	
 # Automatic index incriment specific
 $rv = $dbh->nameSpace( "namespace" );
 $rv = $dbh->insert( "tablename" );

I<This module is not thread safe>

=head1 DESCRIPTION
	
The Header module allows abstracted data access and connection management
of a perl DBI object.  It defines a set of methods for dealing with 
a Database connection.

=head2 Connection Management

After the initial has containing the name, user and pass for the DBI level 
connection is passed to the new() method, the user does not have to connect
or disconnect from the Database.  The connection management is done internaly 
on a per-request basis.  That means for every command that touches the Database,
a connect()/disconnect() pair is wrapped around the data access.

If you have a number of data accesses in a code block, or would like your code
to only connect once to the database at the start and stay connected to the end,
you can manualy force connection management.  

Example:

 $dbh = new PLM::DB::Handle( { name => 'name', user => 'user', pass => 'pass' } );
 $dbh->connect;
  ..multiple database accesses...
 $dbh->disconnect;
 ...database access...

In the example, all the Database accesses are pooled into one connection except
for the later one after the manual disconnect.  The last access will get it's own
internal connect/disconnect pair.

You can also nest connect/disconnect pairs in loops as a usage counter is 
maintained internally and the disconnect only disconnects the actual Database
connection when the usage counter is 0.

=head2 Major Modes of Access

The major modes of accessing data though the Handle object fall under
three areas:

=head3 Generic

get - returns a reference to a hash containing the first row of the result 
of a SELECT statement built from the options.

getAll - returns a reference to an array of hash references containing
the results of a SELECT statement built from the options.

Example:

  $ref = $dbh->get( "*", "users", "user='Dave'" );
  $ref = $dbh->getAll( "*", "users", "user='Dave'" );

The option for the WHERE SQL clause can be omitted to grab all records.

=head3 ResultSet

getResultSet works like the getMultRow except instead of returing a reference
it returns an instantiated ResultSet object - see: ResultSet(3).

Interaction with the data stored in the internal ResultSet can be done through
the methods: 

getNumRows - Returns the number of rows in the ResultSet
getProperty - Returns the value of the row and field options

returnResultSet - returns the same object reference that getResultSet returns
but without an additional query to the DBI object.  It's only there in case
you decide later in the code path to work with multiple ResultSet objects
through the direct ResultSet(3) methods.

getDataRef - returns a reference to an array representing the rows in the 
ResultSet each holding a hash referencing the Property -> Value for the 
executed SELECT.  This data reference can be used directly without methods.

Example:

  $rs = $dbh->getResultSet( "*", "users", "user='Dave'" );
  $rs = $dbh->returnResultSet;
  
  $count = $dbh->getNumRows;
  
  $email = $dbh->getProperty( $row, "email" );
  $email = $rs->getProperty( $row, "email" );
  
  for ( @{ $rs->getDataRef } ) {
    %data = %{$_};
  }

=head1 AUTHORS

 Nathan T. Dabney <smurf@osdl.org>
 Jerry Sievert <jerry@osdl.org>

=head1 COPYRIGHT

 Copyright (c) 2002 Open Source Development Labs
 This is free software; see the file COPYING for license and distribution
 information.  There is NO warrently; not even for MERCHANTABILITY or 
 FITNESS FOR A PARTICULAR PURPOSE.  

 If it breaks, you keep all the little pieces.

=head1 SEE ALSO

DBI(3) ResultSet(3)

=head1 FREQUENTLY ASKED QUESTIONS

 <jerry>  Are you on crack?
 <Nathan>  No.  It's supposed to be like that.

=cut

