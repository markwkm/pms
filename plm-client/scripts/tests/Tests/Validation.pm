package Tests::Validation;

use PLM::Validation::Suite;

sub validation_pass {
    return PLM::Validation::Suite::validate( "test_suite", "foo", "bar" );
}

sub validation_fail {
    return PLM::Validation::Suite::validate( "test_fail" );
}

1;
