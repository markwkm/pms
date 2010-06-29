# PLM::Filter Package
#
# Author:	Nathan Dabney
# Date:		06/17/02
#
# Presents a method reference to a Filter object in the PLM data space

package PLM::PLM::Filter;

@ISA = qw( PLM::PLM );

use strict;
use PLM::Util::Log;
use PLM::DB::Handle;
use PLM::PLM;
use PLM::Util;

my $log = getLog( "PLM::PLM::Filter" );

sub new {
    my $self = {};
    my $type = shift;
    bless $self, $type;

    $self->SUPER::new( "plm_filter" );

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
