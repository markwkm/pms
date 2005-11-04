
package PLM::Validation::Suite;

require PLM::Validation::Config;
use PLM::Util;

BEGIN { }

my $log = getLog( "PLM::Validation::Suite" );

# holder for any failure messages
my $failureMessage = "";

sub validate {
    my $name = shift;

    # clear the failure message
    $failureMessage = "";

    my $suite = new PLM::Validation::Config();
    my $tests = $suite->getTests( $name );

    my $count = scalar( @$tests );

    for ( $i = 0; $i < $count; $i++ ) {
        my $test = @$tests[ $i ];

        my $ret = $test->( $name, @_ );

        # did we fail the test?
        if ( $ret == 0 ) {

            # debug statement goes here, print out the failure message
            $log->msg( 4, $failureMessage );
            return 0;
        }
    }

    return 1;
}

# sets the last failureMessage
sub setFailureMessage {
    ( $failureMessage ) = @_;
}

# returns the most recent failureMessage
sub getFailureMessage {
    return $failureMessage;
}

END { }

1;

