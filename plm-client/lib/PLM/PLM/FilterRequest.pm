# PLM::FilterRequest Package
#
# Author:	Nathan Dabney
# Date:		06/17/02
#
# Presents a method reference to a Filter object in the PLM data space

package PLM::PLM::FilterRequest;

@ISA = qw( PLM::PLM );

use strict;
use PLM::Util::Log;
use PLM::DB::Handle;
use PLM::PLM;
use PLM::PLM::FilterRequestState;
use PLM::Util;

my $log = getLog( "PLM::PLM::FilterRequest" );

sub new {
    my $self = {};
    my $type = shift;
    bless $self, $type;

    $self->SUPER::new( "plm_filter_request" );

    my $state = new PLM::PLM::FilterRequestState();

    my $ref = $state->search_sql( { code => "Queued" } );

    unless ( $ref && @{ $ref } ) {
        panic( "Unable to find state for filter request!" );
    }

    $self->setValue( "plm_filter_request_state_id", ${ $ref }[ 0 ]{ "id" } );

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

1;
