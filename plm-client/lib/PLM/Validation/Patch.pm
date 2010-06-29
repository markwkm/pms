
# validation test suite
# user tests go in here, such as authentication checks

package PLM::Validation::Patch;

use PLM::Validation::Suite;

# check against patch depend type
sub isDepend {
    my $name = shift;

    my ( $username, $password, $depend ) = @_;

    if ( ( defined( $depend )
         && ( ( $depend =~ /apply/i ) || ( $depend =~ /obsolete/i ) ) ) )
    {
        return 1;
    }

    else {
        PLM::Validation::Suite::setFailureMessage( "isDepend: not apply|obsolete " );
        return 0;
    }
}

1;
