package PLM::RPC::CommandSet;

require Exporter;
@ISA = qw( Exporter );

@EXPORT = qw(
  command_set_get_content
);

use strict;
use PLM::PLM::Software;
use PLM::Util;

require Exporter;

my $log = getLog( "PLM::RPC::CommandSet" );

BEGIN { }

#my $config = getConfig();


sub command_set_get_content {
    my ($ref, $software, $patch_id, $command_set_type) = @_;
    if (! $command_set_type){
        $command_set_type='build';
    }

    my $software_object=new PLM::PLM::Software();
    my $software_id=$software_object->verify("$software");
    
    my $dbh = getDBHandle();

    $log->msg( 1, "command_set_get_content( $software, $patch_id )" );

    if ( $dbh ){
        # SELECT command, command_type, expected_result from plm_command c, plm_software_to_command_set st where c.plm_command_set_id=st.plm_command_set_id AND st.plm_software_id = 1 and  min_plm_patch_id <= 100 AND max_plm_patch_id >=  100 ORDER BY c.command_order, c.id;
        my $ref = $dbh->getAll(  "command, command_type, expected_result", 
                             "plm_command c, plm_software_to_command_set st, plm_command_set cs",
                             "c.plm_command_set_id=st.plm_command_set_id AND st.plm_software_id = $software_id ". 
                             "AND st.plm_command_set_id = cs.id ". 
                             "AND cs.command_set_type=\'$command_set_type\' ".
                             "AND $patch_id >= min_plm_patch_id AND $patch_id <= max_plm_patch_id ".
                             "ORDER BY c.command_order, c.id" );
        #$log->msg( 2, "Update return value: $rv");
        if ( $ref ){
            return $ref;
        } else {
            return 0;
        }
    } 
    $log->msg( 0, "No database handle");
    return 0;

}
