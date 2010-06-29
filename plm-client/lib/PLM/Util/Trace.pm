package PLM::Util::Trace;

use strict;
use warnings;
use PLM::Util::Log;
use PLM::Util::Config;
use Exporter;

our @ISA    = qw( Exporter );
our @EXPORT = qw( trace_configure panic call_trace db_echeck );

my $log = undef;
my $cfg = undef;

sub trace_configure {
    $log = shift;
    $cfg = shift;
}

sub panic {
    my $reason = shift || "UNKNOWN - FIXME";

    call_trace( $reason, 1 );
}

sub call_trace {
    my $reason = shift || "UNKNOWN - FIXME";
    my $panic  = shift || 0;
    my $depth  = 0;

    my $msg = "[CALL TRACE :: START ] Reason: $reason\n";

    my ( $pkg, $file, $line, $sub ) = caller( $depth++ );

    while ( $file ) {
        $msg .= "[$depth] ($pkg) $file:$line $sub()\n";

        ( $pkg, $file, $line, $sub ) = caller( $depth++ );
    }

    if ( $panic ) {
        $msg .= "[CALL TRACE :: PANIC ] [errstr: $!]\n";
        trace_output( $msg, $reason );

        exit 1;
    } else {
        $msg .= "[CALL TRACE :: END ]\n";
        trace_output( $msg, $reason );
    }
}

sub trace_output {
    my $txt = shift;
    my $msg = shift;

    print "\n$txt\n";
    $log->msg( 0, $txt ) if ( $log );

    email_admin( $txt, $msg ) if ( $cfg );
}

sub email_admin {
    my $txt = shift;
    my $msg = shift;

    my $email = $cfg->get( "admin_email" );

    return unless ( $email );

    my $host = `hostname`;
    chomp $host;

    system "echo '$txt' | mail -s '[PLM] PANIC on $host ($msg)' $email";
}

sub db_echeck {
    my $dbh = shift;
    my $sql = shift || "no sql givin";

    $sql = "[SQL: $sql]";

    unless ( $dbh ) {
        panic( "missing database reference! $sql" );
    }

    if ( defined( $dbh->err ) || defined( $dbh->errstr ) )
    {
        my $err = $dbh->err || "N/A";
	my $errstr = $dbh->errstr || "N/A";

        panic( "DB Error: $err ($errstr) $sql" );
    }
}

1;
