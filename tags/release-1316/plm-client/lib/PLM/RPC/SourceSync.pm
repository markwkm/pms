package PLM::RPC::SourceSync;

require Exporter;
@ISA = qw( Exporter );

@EXPORT = qw(
  source_sync_by_source
  source_sync_set_value
);

use strict;
use PLM::PLM::SourceSync;
use PLM::Object::SourceSync;
use PLM::Util;

require Exporter;

my $log = getLog( "PLM::RPC::SourceSync" );

BEGIN { }

my $config = getConfig();


#
#  Return a list of the physical archive information about the requested repo
#

sub source_sync_by_source {
    shift;                  # Package name, may be including package if called from SOAP
    my $source_id = shift;
    my $source_sync       = new PLM::PLM::SourceSync();

    return "" unless ( $source_id && $source_id =~ /^\d+$/ );

    my $ref = $source_sync->search_sql( { plm_source_id => $source_id } );

    return "" unless ( $ref && @{ $ref } );

    my @ret;
    foreach ( @{ $ref } ) {
        # We load and print them one at a time, Maybe could be done better?
        $source_sync->load( ${ $_ }{ 'id' } , $_ );
        my $s = new PLM::Object::SourceSync();
        $s->loadDataOnly( $source_sync );
        push @ret, $s;
    }
    return \@ret;
}

sub source_sync_set_value{
    shift;                  # Package name, may be including package if called from SOAP
    my $source_sync_id = shift;
    my $field=shift;
    my $value=shift;
 
    my $dbh = getDBHandle();

    $log->msg( 1, "source_sync_set_value( $source_sync_id, $field, $value )" );

    if ( $dbh ){
        my $rv = $dbh->update( "plm_source_sync", "$field = \'$value\'", "id = \'$source_sync_id\'" );
        $log->msg( 2, "Update return value: $rv");
        return $rv;
    }
    $log->msg( 0, "No database handle");
    return 0;
}

1;
