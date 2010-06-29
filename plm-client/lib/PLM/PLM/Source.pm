# PLM::PLM::Source
#
# Author:       Judith Lebzelter
# Date:         02/18/03
#
# Presents a method reference to a Source object in the PLM data space.

package PLM::PLM::Source;

@ISA = qw( PLM::PLM );

use strict;
use PLM::Util::Log;
use PLM::PLM;
use PLM::Util;

BEGIN { }

my $log = getLog( "PLM::PLM::Source" );

sub new {
    my $self = {};
    my $type = shift;
    bless $self, $type;

    $self->SUPER::new( "plm_source" );

    return $self;
}

sub debug {
    my ( $self, $debug ) = @_;

    if ( defined( $debug ) ) {
        $log->debug( $debug );
    }

    return $log->debug;
}

1;
