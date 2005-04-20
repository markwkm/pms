# PLM::FilterRequest Package
#
# Author:	Nathan Dabney
# Date:		06/17/02
#
# Presents a method reference to a Filter object in the PLM data space

package PLM::PLM::FilterRequestState;

@ISA = qw( PLM::PLM );

use strict;
use PLM::Util::Log;
use PLM::DB::Handle;
use PLM::PLM;
use PLM::Util;

my $log = getLog( "PLM::PLM::FilterRequestState" );
my %STATE_CACHE;

sub new {
    my $self = {};
    my $type = shift;
    bless $self, $type;

    $self->SUPER::new( "plm_filter_request_state" );

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

sub get_state {
    my ( $self, $code ) = @_;
    my $ref;

    return 0 unless ( $code );
    return $STATE_CACHE{ $code } if ( $STATE_CACHE{ $code } );

    $ref = $self->search_sql( { code => $code } );

    return 0 unless ( $ref && ${ $ref }[ 0 ]{ id } );

    $STATE_CACHE{ $code } = ${ $ref }[ 0 ]{ id };

    return $STATE_CACHE{ $code };
}

1;
