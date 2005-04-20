
# module responsible for note functions

package PLM::RPC::Note;

use PLM::Validation::Suite;
use PLM::PLM::Note;
use PLM::XML::Note;
use PLM::Util;

require Exporter;
@ISA = qw( Exporter );

# symbols to export by default

@EXPORT = qw( note_add
  note_delete
  note_get
);

my $log = getLog( "PLM::RPC::Note" );

BEGIN { }

# add a note
sub note_add {
    my ( $username, $password, $rawXML ) = @_;
    my $note = new PLM::PLM::Note();

    # Run standard validation
    unless ( PLM::Validation::Suite::validate( "note_add", @_ ) ) {
        $log->msg( 0, "Unable to authenticate note_add for user: $_[0]" );
        return 0;
    }

    $log->msg( 1, "Converting the raw text to XML" );
    $XML->parseXMLData( $rawXML );

    my $ret = $note->add( \$XML );
    if ( $ret ) {
        $log->msg( 1, "Success in note_add for: [$username]" );
    } else {
        $log->msg( 0, "Failure in note_add for: [$username]" );
    }

    return $ret;
}

# delete a note
sub note_delete {
    my ( $username, $password, $data ) = @_;
    my $note = new PLM::PLM::Note();

    return 0 unless PLM::Validation::Suite::validate( "note_delete", @_ );

    my $ret = $note->delete( $data );

    return $ret;
}

# note get
sub note_get {
    my ( $data ) = @_;
    my $note = new PLM::PLM::Note();

    return 0 unless PLM::Validation::Suite::validate( "note_get", @_ );

    my $ret = $note->get( $data );

    return $ret->toString;
}

END { }

1;
