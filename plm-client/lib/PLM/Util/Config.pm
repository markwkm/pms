# Config Package
#
# Author:  Jerry Sievert
# Date: 10/29/01
#
# Config module, given a filename, loads the config file, keeps track
# of all of the data in an associative array.

package PLM::Util::Config;

use strict;
use warnings;

BEGIN { }

my $fileName = "";    # config file name
my %configOptions;    # config options

my $VER   = "0.01-ALPHA";
my $DEBUG = 1;

# create a new instance of a Config, using the passed filename
sub new {
    my $self  = {};
    my $class = shift;
    bless( $self, $class );

    ( $self->{ fileName } ) = @_;
    $self->{ configOptions } = {};

    # if we're an empty constructor, return
    if ( !defined( $self->{ fileName } ) ) {
        return $self;
    }

    # otherwise, load our config
    $self->file();

    return $self;
}

# load a file, returning an associative array of values
sub file {
    my ( $self ) = @_;

    die "Config filename not specified" unless ( $self->{ fileName } );

    die "$0 cannot open $self->{fileName} for reading"
      unless ( -e $self->{ fileName } && -r $self->{ fileName } );

    open( F, $self->{ fileName } );

    while ( <F> ) {

        # Strip spaces
        s/^\s+//;
        s/\s+$//;
        s/\s*=\s*/=/g;
        s/\s*\=/\ \=\ /;
        s/\=\s*/\ \=\ /;

        # Eliminate comments
        s/^\s*\#.*//;

        # Bad entries should now be empty
        next unless length;

        # read in the option
        # $self->set( split ( /\s*=\s*/, $_, 2 ) );
        m/(\S+)\s*=\s*(.+)/;
        $self->set( $1, $2 );

        #print "parse: $1 => $2\n";
    }

    close F;
}

# getOption( key )
#
# returns the option if it's defined, otherwise return ""
sub get {
    my ( $self, $key ) = @_;

    # see if we're defined
    my $hash = $self->{ configOptions };
    if ( !defined( $hash->{ $key } ) ) {
        return undef;
    }

    return $hash->{ $key };
}

# setOption( key, value )
#
# sets the option based on key
sub set {
    my ( $self, $key, $value ) = @_;

    my $hash = $self->{ configOptions };
    $hash->{ $key } = $value;
}

sub getKeys {
    my ( $self ) = @_;

    my %hash = $self->{ configOptions };
    return keys %hash;
}

sub getHash {
    my ( $self ) = @_;

    my %hash = $self->{ configOptions };
    return %hash;
}

END { }

1;

