package Tests::XML;

use PLM::XML::QDXmlElement;
use PLM::XML::QDXml;

# this routine tests the instanciation of a QDXml object
sub instanciate_QDXml {
    my $xml = new PLM::XML::QDXml( "test" );

    if ( !defined( $xml ) ) {
        return 0;
    }

    if ( $xml->getElementName() eq "test" ) {
        return 1;
    }

    return 0;
}

# instanciate a QDXmlElement, set/get it's name
sub instanciate_QDXmlElement {
    my $xml = new PLM::XML::QDXmlElement();

    $xml->setElementValue( "test" );
    if ( $xml->getElementValue() eq "test" ) {
        return 1;
    }

    return 0;
}

sub make_container {

    # instanciate the main xml container
    my $xml = new PLM::XML::QDXml( "rec" );

    # since the subrec is technically also a QDXml object, we
    # need to create it as well, and populate it with children
    my $xmlSubRec = new PLM::XML::QDXml( "subrec" );

    # add subrec's entry, subdata, empty - we can do this in two
    # ways, we'll explore the first here, passing the element name
    # and an empty element value -- much easier to deal with this
    # stuff in a typed language, but since perl is untyped, and
    # we're overloading, we have to make some tradeoffs
    $xmlSubRec->addElement( "subdata", "" );

    # now, add the subrec to the main data -- notice the overloading
    $xml->addElement( $xmlSubRec );

    # here's where we add moredata, going to demonstrate adding it
    # the "other" way
    my $xmlElement = new PLM::XML::QDXmlElement( "moredata" );

    # now, add moredata into the tree
    $xml->addElement( $xmlElement );

    return $xml;
}

sub subrec_container {
    my $finalstring =
"<rec>\n <subrec>\n  <subdata></subdata>\n </subrec>\n <moredata></moredata>\n</rec>\n";

    # instanciate the main xml container
    my $xml = make_container();

    if ( $xml->toString() eq $finalstring ) {
        return 1;
    }

    return 0;
}

sub subrec_modify {
    my $finalstring =
"<rec>\n <subrec>\n  <subdata>my data</subdata>\n </subrec>\n <moredata>even more data</moredata>\n</rec>\n";

    # instanciate the main xml container
    my $xml = make_container();

    # set the value of subrec.subdata to something
    $xml->setElementValue( "subrec.subdata", "my data" );

    # set the value of moredata to something
    $xml->setElementValue( "moredata", "even more data" );

    if ( $xml->toString() eq $finalstring ) {
        return 1;
    }

    return 0;
}

sub parse {
    my $finalstring =
"<rec>\n <subrec>\n  <subdata>nothing here</subdata>\n </subrec>\n <moredata>move along please</moredata>\n</rec>\n";
    my $data =
      "<rec><subrec><subdata>nothing here</subdata></subrec> "
      . "<moredata>move along please</moredata></rec>";

    # instanciate the main xml container
    my $xml = make_container();

    $xml->parseXMLData( $finalstring );

    if ( $xml->toString eq $finalstring ) {
        return 1;
    }

    return 0;
}

1;

