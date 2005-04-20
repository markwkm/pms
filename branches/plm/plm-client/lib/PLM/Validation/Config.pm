
no strict 'refs';

package PLM::Validation::Config;

# packages that contain our test routines must be included here
use PLM::Validation::Test;
use PLM::Validation::User;
use PLM::Validation::Patch;

# add test validations into the new subroutine
sub new {
    my $self = {};
    bless $self;

    # here's where we put in our definitions
    # test validation
    my @test_suite =
      ( \&PLM::Validation::Test::passTest );

    $self->{ "test_suite" } = \@test_suite;

    my @test_fail = ( \&PLM::Validation::Test::failTest );

    $self->{ "test_fail" } = \@test_fail;

    my @user_add = (
                        \&PLM::Validation::User::isAuthenticatedAdmin
    );

    $self->{ "user_add" } = \@user_add;


    my @user_delete = (
                        \&PLM::Validation::User::isAuthenticatedAdmin
    );

    $self->{ "user_delete" } = \@user_delete;

    my @user_password = (
                          \&PLM::Validation::User::isAuthenticated
    );

    $self->{ "user_password" } = \@user_password;

    my @user_set_option = (
                            \&PLM::Validation::User::isAuthenticated,
                            \&PLM::Validation::User::canSetOption
    );

    $self->{ "user_set_option" } = \@user_set_option;

    my @user_get_option = (
                            \&PLM::Validation::User::isAuthenticated
    );

    $self->{ "user_get_option" } = \@user_get_option;

    my @user_get_info = (
                          \&PLM::Validation::User::isAuthenticated
    );

    $self->{ "user_get_info" } = \@user_get_info;

    # patch code
    my @patch_add = (
                      \&PLM::Validation::User::isAuthenticated
    );

    $self->{ "patch_add" } = \@patch_add;

    my @patch_find_by_name = (
                               \&PLM::Validation::User::isAuthenticated
    );

    $self->{ "patch_find_by_name" } = \@patch_find_by_name;

    my @patch_search = ();

    $self->{ "patch_search" } = \@patch_search;


    my @software_add_software = (
                                  \&PLM::Validation::User::isAuthenticatedAdmin
    );

    $self->{ "software_add_software" } = \@software_add_software;


    my @software_delete_software = (
                                     \&PLM::Validation::User::isAuthenticatedAdmin
    );

    $self->{ "software_delete_software" } = \@software_delete_software;

    return $self;
}

sub getTests {
    my ( $self, $testName ) = @_;

    return $self->{ $testName };
}

1;
