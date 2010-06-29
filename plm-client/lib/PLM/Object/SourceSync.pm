# an XML object for a source_sync

package PLM::Object::SourceSync;
@ISA = qw( PLM::Object);

use strict;
use warnings;
use PLM::Object;

my $FALSE=0;
my $TRUE=1;

sub new {

    my $pkg_or_self = shift;
    # instanciate the data, fill in values
    my $self;
    if (ref $pkg_or_self){
       $self = $pkg_or_self;
    } else {
        $self = {};
        bless $self, $pkg_or_self;
    }

    # create an array to hold the data
    $self->{ data } = {};

    # set our element name
    $self->{ elementName } = "source_sync";

    # set up our fields
    $self->addElement( "id",                 "" );
    $self->addElement( "plm_source_type",    "" );
    $self->addElement( "search_location",    "" );
    $self->addElement( "depth",              "" );
    $self->addElement( "wanted_regex",       "" );
    $self->addElement( "not_wanted_regex",   "" );
    $self->addElement( "baseline",           "" );
    $self->addElement( "applies_regex",      "" );
    $self->addElement( "name_substitution",  "" );
    $self->addElement( "descriptor",         "" );
    $self->addElement( "plm_source_id",      "" );
    $self->addElement( "last_timestamp",     "" );

    return $self;
}

sub isa_base{
    my $ref=shift;
    if ($ref->getValue('baseline') =~ m/Y/i){
        return $TRUE;
    } 
    return $FALSE;
}

1;
