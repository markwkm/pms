
# module responsible for patch functions

package PLM::RPC::Software;

use PLM::Validation::Suite;
use PLM::PLM::Software;
use PLM::Util;

require Exporter;
@ISA = qw( Exporter );

# symbols to export by default

@EXPORT = qw(
  software_verify
  software_add_software
  software_delete_software
  software_get_value
);

my $log = getLog( "PLM::RPC::Software" );

BEGIN { }

# software verify
sub software_verify {
    shift;                  # Package name, may be including package if called from SOAP
    my $software = new PLM::PLM::Software();

    my $ret = $software->verify( @_ );

    return $ret;
}

# software add software
sub software_add_software {
    my $software = new PLM::PLM::Software();

    return 0 unless PLM::Validation::Suite::validate( "software_add_software", @_ );

    shift;    # Away username
    shift;    # Away password

    my $ret = $software->add_software( @_ );

    return $ret;
}

# software delete_software
sub software_delete_software {
    my $software = new PLM::PLM::Software();

    return 0
      unless PLM::Validation::Suite::validate( "software_delete_software", @_ );

    shift;    # Away username
    shift;    # Away password

    my $ret = $software->delete_software( @_ );

    return $ret;
}

sub software_get_value {
    shift;                  # Package name, may be including package if called from SOAP
    my ( $id, $field ) = @_;
    my $value;
    my $software;

    $software = new PLM::PLM::Software();
    $software->load( $id );
    ($value) = $software->getValue( $field );
    ## ($value) = $patch->get_value( $id, $field );

    #return "PANIC: MISSING SOFTWARE $id OR BAD REQUEST $field" unless $value;

    return $value;
}

END { }

1;
