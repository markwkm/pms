
# validation test suite
# used specifically for testing, one test returns
# a pass, the other a fail
package PLM::Validation::Test;

use PLM::Validation::Suite;

# pass this test always
sub passTest {
    return 1;
}

# fail this test always
sub failTest {
    PLM::Validation::Suite::setFailureMessage( "failTest: auto-failure" );

    return 0;
}

1;

