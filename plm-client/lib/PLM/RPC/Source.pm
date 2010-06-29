package PLM::RPC::Source;

require Exporter;
@ISA = qw( Exporter );

@EXPORT = qw(
    source_get_by_software
    source_get
);

#use strict;
use PLM::PLM::Source();
use PLM::Object::Source();
use PLM::Util;

#
#  Return a list of the source information for the requested software
#

sub source_get_by_software {
    shift;                  # Package name, may be including package if called from SOAP
    my $software_id = shift;
    my $source       = new PLM::PLM::Source();

    return "" unless ( $software_id && $software_id =~ /^\d+$/ );

    my $ref = $source->search_sql( { plm_software_id => $software_id } );

    return "" unless ( $ref && @{ $ref } );

    my @ret;
    foreach ( @{ $ref } ) {
        # We load and print them one at a time, Maybe could be done better?
        $source->load( ${ $_ }{ 'id' } , $_ );
        my $s = new PLM::Object::Source;
        $s->loadDataOnly($source);
        push @ret, $s;
    }
    return \@ret;
}
 

# This returns just one source object
sub source_get {
    shift;                  # Package name, may be including package if called from SOAP
    my $source_id=shift;
    my $source = new PLM::PLM::Source();
    
    return "" unless ( $source_id && $source_id =~ /^\d+$/ );
    my $ref = $source->search_sql( { id => $source_id } );

    return "" unless ( $ref && @{ $ref } );
    $source->load( ${$ref}[0]{ 'id' } , ${$ref}[0] );

    $source->passDataOnly();
    return $source;
}

1;
