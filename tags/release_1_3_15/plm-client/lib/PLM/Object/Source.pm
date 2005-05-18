# an XML object for a Source

package PLM::Object::Source;
@ISA = qw( PLM::Object );

use strict;
use warnings;
use PLM::Object;

sub new {

    # instanciate the data, fill in values
    my $self = {};
    bless $self;

    # create an array to hold the data
    $self->{ data } = {};

    # set our element name
    $self->{ elementName } = "source";

    # set up our fields
    $self->addElement( "id",                 "" );
    $self->addElement( "plm_software_id",    "" );
    $self->addElement( "plm_source_type",    "" );
    $self->addElement( "root_location",      "" );
    $self->addElement( "source_password",    "" );
    $self->addElement( "sc_module",          "" );
    $self->addElement( "sc_branch",          "" );

    return $self;
}

1;
