# PLM::PLM::SourceSync
#
# Author:       Judith Lebzelter
# Date:         11/18/03
#
# Presents a method reference to a SourceSync object in the PLM data space.

package PLM::PLM::SourceSync;

@ISA = qw( PLM::PLM );

use strict;
use PLM::Util::Log;
use PLM::DB::Handle;
use PLM::PLM;
use PLM::Util;

BEGIN { }

my $log = getLog( "PLM::PLM::SourceSync" );

sub new {
    my $self = {};
    my $type = shift;
    bless $self, $type;

    $self->SUPER::new( "plm_source_sync" );

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
