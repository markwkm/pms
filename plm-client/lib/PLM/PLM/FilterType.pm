# PLM::Filter Package
#
# Author:	Nathan Dabney
# Date:		06/17/02
#
# Presents a method reference to a FilterType object in the PLM data space

package PLM::PLM::FilterType;

@ISA = qw( PLM::PLM );

use strict;
use PLM::Util::Log;
use PLM::DB::Handle;
use PLM::PLM;
use PLM::Util;

my $log = getLog( "PLM::PLM::FilterType" );

sub new {
    my $self = {};
    my $type = shift;
    bless $self, $type;

    $self->SUPER::new( "plm_filter_type" );

    return $self;
}

sub debug {
    my ( $self, $debug ) = @_;

    $log->debug( $debug )       if defined $debug;
    $self->SUPER::log( $debug ) if defined $debug;

    return $log->debug();
}

sub add {
    my ( $self, $xml_ref ) = @_;

    $self->unload();

    $self->loadDataOnly( ${ $xml_ref } ) if ( $xml_ref );

    $self->SUPER::add();
}

sub get_next_request_by_type {
    my ( $self, $type ) = @_;
    my ( $ref, $type_id, $request_id );
    my $request = new PLM::PLM::FilterRequest();
    my $state   = new PLM::PLM::FilterRequestState();
    my $dbh     = getDBHandle();

    panic( "Invalid FilterType" )
      unless ( $type );    # Bail if we were not given a valid type

    $ref = $self->search_sql( { code => $type } );

    return 0 unless ( $ref && ${ $ref }[ 0 ]{ id } );   # Invalid/No match found

    $type_id = ${ $ref }[ 0 ]{ id };

    $ref =
      $dbh->get( "plm_filter_request.id",
        "plm_filter_request, plm_filter_type, plm_filter, "
        . "plm_filter_request_state",
        "plm_filter_type.code = '$type' AND "
        . "plm_filter.plm_filter_type_id = plm_filter_type.id AND "
        . "plm_filter_request.plm_filter_id = plm_filter.id AND "
        . "plm_filter_request_state.code = 'Queued' AND "
        . "plm_filter_request.plm_filter_request_state_id = plm_filter_request_state.id "
        . "ORDER BY plm_filter_request.priority, plm_filter_request.id "
        . "LIMIT 1" );

    return 0 unless ( $ref && ${ $ref }{ id } );    # Invalid/No next request

    $log->msg( 1, "Next filter for type [$type] id [${ $ref }{ id }]" );

    return ${ $ref }{ id };
}

1;
