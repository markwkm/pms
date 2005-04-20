# Filename: Object.pm
# Author: JL
# Date: Sept 21, 2004
#
# This is a container for the data hash that allows us to use all 
#  the same calls as before when we accessed the QDXml.pm, except toString()
#  and parseXMLData()

package PLM::Object;

use strict;
use warnings;

BEGIN { }

# possible arguments are as follows:
#
#   elementName (container name)
sub new {

    # instanciate the data, fill in values
    my $self = {};
    bless $self;

    shift;

    my ( $elementName ) = @_;

    if ( defined( $elementName ) ) {
        $self->{ elementName } = $elementName;
    } else {
        # should be defined, even if empty
        $self->{ elementName } = "";
    }

    # create an hash to hold the data
    $self->{ data } = {};
    return $self;
}


# returns the name of the element being referenced, or if the case
# of a full document, the object
sub getElementName {
    my ( $self ) = @_;
    return $self->{ elementName };
}

# sets the elementName, or in this case, the container name
sub setElementName {
    my ( $self, $elementName ) = @_;
    $self->{ elementName } = $elementName;
}

# adds an element to the container
# possible arguments are as follows:
#
#   elementName
#   elementValue
#
# or:
#
#   QDXmlObject (either QDXml or QDXmlElement)
sub addElement {
    my ( $self ) = shift;

    # how many arguments do we have?
    # if we have 1, it should be a QDXmlElement
    # if we have 2, it should be a name/value pair
    if ( @_ == 2 ) {
        my ( $elementName, $elementValue ) = @_;
        $self->{ data }->{ $elementName } = $elementValue;
    } else {
        return -1;
    }
}

# sets the value of an element contained
# arguments:
#
# elementName
# elementValue
sub setElementValue {
    my ( $self, $elementName, $elementValue ) = @_; 

    $self->{ data }->{$elementName}=$elementValue;
}

# gets an elementValue contained in the object
sub getElementValue {
    my ( $self, $elementName ) = @_;

    my $elements = $self->{ data };
    return $elements->{$elementName};
}

# Why do these wrappers exist?

sub setValue {
    my $self = shift;

    $self->setElementValue( @_ );
}

sub getValue {
    my $self = shift;

    $self->getElementValue( @_ );
}

sub loadDataOnly {
    my ( $self, $data ) = @_;
    $self->{ elementName }=$data->{ elementName };
    $self->{'data'}={};
    my $key;
    foreach $key (keys %{$data->{'data'}}){
        $self->{'data'}->{ $key }= ${$data->{'data'}}{$key};
    }
    # for the PLM objects
    $self->{ state_empty } = 0;
}



END { }

1;
