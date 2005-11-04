
package PLM::Test::Harness;

use Time::localtime;
use Time::HiRes qw(gettimeofday tv_interval);
use PLM::Util;

my $log = getLog( "PLM::Test::Harness" );

# instanciate a new Harness
sub new {
    my $self = {};
    bless $self;
    shift;

    # set the number of tests and the number of completed tests both to zero
    $self->{ numTests }       = 0;
    $self->{ completedTests } = 0;

    $log->msg( 3, "New PLM::Test::Harness object created" );

    return $self;
}

# run a test, record the results
sub test {
    my $self = shift;

    my ( $testname, $expectedResult, @args ) = @_;

    # log that we're starting
    $log->msg( 2, "Starting Test: $testname" );

    # which test number are we on?
    my $testnum = $self->{ numTests };

    # increment the number of tests
    $self->{ numTests }++;

    # add the test to the results
    $self->{ "test" . $testnum } = $testname;

    # Set our timestamp
    $self->{ "start" . $testnum } = [ gettimeofday ];

    # actually execute the test
    my $returnValue = $testname->( @args );

    # Calculate the elapsed time
    $self->{ "time" . $testnum } = tv_interval( $self->{ "start" . $testnum } );

    # did we pass the test or not?
    my $passfail = 0;

    if ( $returnValue eq $expectedResult ) {
        $passfail = 1;
    }

    $self->{ "expected" . $testname } = $expectedResults;
    $self->{ "actual" . $testname }   = $returnValue;

    # set our results
    $self->{ "results" . $testnum } = $passfail;

    # show that we've completed another test
    $self->{ completedTests }++;

    # log that we're ending
    $log->msg( 2, "Ending Test: $testname" );
}

# prints a report if requested, and returns the percentage of successful
# tests
sub report {
    my ( $self ) = shift;

    my ( $verbose ) = @_;

    if ( !defined( $verbose ) ) {
        $verbose = 2;
    }

    # number of passed/failed tests
    my $pass = 0;
    my $fail = 0;

    if ( $verbose >= 1 ) {
        print "Test Results\n";
        print "------------\n";

        print "\n";
        print $self->{ completedTests } . " tests completed.\n";
    }

    # if we're really verbose, iterate through the results
    if ( $verbose >= 2 ) {
        print "\n";
    }

    for ( my $i = 0; $i < $self->{ numTests }; $i++ ) {
        if ( $verbose >= 2 ) {
            print $self->{ "test" . $i };
            print " " x ( 60 - length( $self->{ "test" . $i } ) );

        }

        if ( $self->{ "results" . $i } ) {
            if ( $verbose >= 2 ) {
                print "[ PASS ]  ";
            }

            if ( $verbose >= 3 ) {
                print( int( $self->{ "time" . $i } * 1000000 ) / 1000000 );
            }

            print "\n";

            $pass++;
        } else {
            if ( $verbose >= 2 ) {
                print "[ FAIL ]\n";
            }
            $fail++;
        }
    }

    my $percentage = int( 10000 * $pass / ( $pass + $fail ) ) / 100;

    if ( $verbose >= 1 ) {
        print "\n";
        print "Total PASS: " . $pass . "\n";
        print "Total FAIL: " . $fail . "\n\n";
        print "Percentage Passed: " . $percentage . "\n\n";
    }

    return $percentage;
}

1;
