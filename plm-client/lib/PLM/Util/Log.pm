package PLM::Util::Log;

use strict;
use POSIX;
use Mail::Internet;
use Sys::Syslog qw(:DEFAULT setlogsock);

sub new {
    my $self = {};
    bless $self;

    shift;
    $self->{ target }    = "syslog";
    $self->{ level }     = 0;
    $self->{ filename }  = undef;
    $self->{ timestamp } = "on";

    $self->config( shift );

    setlogsock "unix";
    openlog "PLM", "pid", "LOG_DAEMON";

    if ( defined( my $cfg = shift || undef ) ) { $self->config( $cfg ) }

    return $self;
}

sub config {
    my $self   = shift;
    my $cfgRef = shift;

    unless ( defined $cfgRef ) {return}

    my %cfg = %{ $cfgRef };

    for ( keys( %cfg ) ) {
        $self->{ $_ } = $cfg{ $_ };
    }
}

sub debug {
    my $self = shift;

    if ( ref( $self ) && @_ == 1 ) {
        $self->{ level } = shift;
    }
    return $self->{ level };
}

sub target {
    my ( $self, $t ) = @_;

    mylog( $self, 1, "Changing log target to: $t" );

    my $tmp = $self->{ target };
    $self->{ target } = "";

    if ( $t =~ /new/i ) { $self->{ target } = "" }
    if ( $t =~ /stdout/i ) { $self->{ target } .= "stdout" }
    if ( $t =~ /stderr/i ) { $self->{ target } .= "stderr" }
    if ( $t =~ /email/i )  { $self->{ target } .= "email" }
    if ( $t =~ /syslog/i ) { $self->{ target } .= "syslog" }
    if ( $t =~ /file/i )   {
        unless ( $self->{ filename } ) {
            die "must pre-set log filename!";
            return;
        }
        $self->{ target } .= "file";
    }

    if ( $self->{ target } eq "" ) {
        $self->{ target } = $tmp;
        die "syntax requires one of: file, stdout, stderr";
    }
}

sub filename {
    my $self = shift;
    unless ( @_ == 1 ) { return $self->{ filename } }
    my $file = shift;

    if ( -e $file && !( -f $file ) ) {
        mylog( $self, 0, "Can't log to there!" );
    }

    $self->{ filename } = $file;
}

sub mylog {
    my $self  = shift;
    my $level = shift;
    my $txt   = undef;

    if ( $self->{ id } ) {
        $txt = "[" . $self->{ id } . "] " . join ( "", @_ );
    } else {
        $txt = join ( "", @_ );
    }

    unless ( $level <= $self->{ level } ) {return}
    if ( $self->{ target } eq "file" && !( $self->{ filename } ) ) {return}

    if ( $self->{ target } =~ /stdout/ ) {
        print STDOUT $self->_logtime . $txt . "\n";
    }
    if ( $self->{ target } =~ /stderr/ ) {
        print STDERR $self->_logtime . $txt . "\n";
    }
    if ( $self->{ target } =~ /syslog/ ) {
        syslog "LOG_INFO", "%s", $txt;
    }

    if ( $self->{ target } =~ /file/ ) {
        open( LOG, ">>" . $self->{ filename } ) || die "Can't open log file \"$self->{ filename }\"";
        print LOG $self->_logtime() . $txt . "\n";
        close LOG;
    }
}

sub msg {
    my $self  = shift;
    my $value = shift;
    unless ( @_ > 0 ) { die "usage: CLASSNAME->msg(txt)" }

    mylog( $self, $value, @_ );
}

sub _logtime {
    my $self = shift;
    my @t    = localtime( time );

    if ( $self->{ timestamp } =~ /^$|off/i ) { return "" }

    return "[" . POSIX::strftime(
                                  "%b %e %T", $t[ 0 ], $t[ 1 ], $t[ 2 ],
                                  $t[ 3 ],    $t[ 4 ], $t[ 5 ], $t[ 6 ],
                                  $t[ 7 ],    -1
    ) . "] ";
}

1;
