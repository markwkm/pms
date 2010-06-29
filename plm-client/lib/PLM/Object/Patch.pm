# an XML object for a patch

package PLM::Object::Patch;
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
    $self->{ elementName } = "patch";

    # set up our fields
    $self->addElement( "id",                 "" );
    $self->addElement( "version",            "" );
    $self->addElement( "comment",            "" );
    $self->addElement( "created",            "" );
    $self->addElement( "name",               "" );
    $self->addElement( "private_flag",       "" );
    $self->addElement( "submit_flag",        "" );
    $self->addElement( "plm_user_id",        "" );
    $self->addElement( "plm_applies_id",     "" );
    $self->addElement( "plm_software_id",    "" );
    $self->addElement( "user_id",            "" );
    $self->addElement( "content_format",     "" );
    $self->addElement( "content",            "" );
    $self->addElement( "patch_path",         "" );
    $self->addElement( "remote_identifier",  "" );
    $self->addElement( "plm_source_id",      "" );
    $self->addElement( "reverse",            "" );

    return $self;
}

1;
