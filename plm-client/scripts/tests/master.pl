#!/usr/bin/perl -w

use strict;
use Test::Harness;
use Tests::ASP;
use Tests::User;
use Tests::Patch;
use Tests::Software;
use Tests::Validation;
use Tests::Note;
use Tests::XML;

# Give me a random number...
my $r = int( rand( getppid() * 2 + time() ) );

# Create a unique username for testing purposes
chomp( my $user = "DEBUG_" . `hostname -s` );
$user .= "_$r";
chomp( my $god = "DEBUG_GOD_" . `hostname -s` );
$god .= "_$r";

my $pass    = "PASS_" . $r % 100;
my $godpass = $pass . "1";

my $patch = get_patch();

# Yay
my $harness = new Test::Harness();

# Use these to bail early...
#$harness->report( 3 );
#exit (0);

# Setup the God User
$harness->test( "Tests::User::add", 1, $god, $godpass );
$harness->test( "Tests::User::set_option", 1, $god, "admin_flag", 1 );
$harness->test(
                "Tests::User::set_option", 1,
                $god,                      "email",
                $god . "\@homey.com"
);

# ASP interfaces
$harness->test( "Tests::ASP::user_verify",     1, $god,  $godpass );
$harness->test( "Tests::ASP::user_add",        0, $god,  $godpass );
$harness->test( "Tests::ASP::user_add",        1, $user, $pass );
$harness->test( "Tests::ASP::user_set_option", 1, $god,  $godpass, $user,
                "admin_flag", 1 );
$harness->test( "Tests::ASP::user_get_option", 1, $god, $godpass, $user,
                "admin_flag" );
$harness->test(
                "Tests::ASP::patch_add", 1,
                $god,                    $godpass,
                $patch->toString()
);
$harness->test( "Tests::ASP::user_password", 1, $user, $pass, $pass . "_" );
$harness->test( "Tests::ASP::user_verify", 1, $user, $pass . "_" );
$harness->test( "Tests::ASP::user_delete", 1, $god, $godpass, $user );
$harness->test(
                "Tests::ASP::user_find_by_email", $god,
                $god . "\@homey.com"
);

# SOAP interfaces
$harness->test( "Tests::ASP::SOAP_user_verify",   1, $god,  $godpass );
$harness->test( "Tests::ASP::SOAP_user_add",      0, $god,  $godpass );
$harness->test( "Tests::ASP::SOAP_user_add",      1, $user, $pass );
$harness->test( "Tests::ASP::SOAP_user_password", 1, $user, $pass,
                $pass . "_" );
$harness->test( "Tests::ASP::SOAP_user_verify",   1, $user, $pass . "_" );
$harness->test( "Tests::ASP::SOAP_user_verify",   0, $user, $pass );
$harness->test( "Tests::ASP::SOAP_user_password", 1, $user, $pass . "_",
                $pass );
$harness->test( "Tests::ASP::SOAP_user_verify", 1, $user, $pass );
$harness->test( "Tests::ASP::SOAP_patch_add",   1, $god,  $godpass,
                $patch->toString() );
$harness->test( "Tests::ASP::SOAP_user_set_option", 1, $god, $godpass, $user,
                "admin_flag", 0 );
$harness->test( "Tests::ASP::SOAP_user_get_option", 0, $god, $godpass, $user,
                "admin_flag" );
$harness->test( "Tests::ASP::SOAP_user_set_option", 0, $user, $pass, $user,
                "admin_flag", 1 );
$harness->test( "Tests::ASP::SOAP_user_delete", 1, $god, $godpass, $user );

# User interface
$harness->test( "Tests::User::add",      1, $user, $pass );
$harness->test( "Tests::User::add",      0, $user, $pass );
$harness->test( "Tests::User::login_ok", 1, $user, $pass );
$harness->test( "Tests::User::valid_user",       1, $user );
$harness->test( "Tests::User::valid_password",   1, $user, $pass );
$harness->test( "Tests::User::invalid_user",     1, "NOT_A_USER" );
$harness->test( "Tests::User::invalid_password", 1, $user, "BAD_PASS" );
$harness->test( "Tests::User::change_password",  1, $user, $pass . "_" );
$harness->test( "Tests::User::valid_password",   1, $user, $pass . "_" );
$harness->test( "Tests::User::set_option",       1, $user, "admin_flag", 1 );
$harness->test( "Tests::User::get_option",       1, $user, "admin_flag", 1 );
$harness->test( "Tests::User::is_an_admin",      1, $user );
$harness->test( "Tests::User::set_option",       1, $user, "admin_flag", 0 );
$harness->test( "Tests::User::get_option",       1, $user, "admin_flag", 0 );
$harness->test( "Tests::User::is_not_an_admin",  1, $user );
$harness->test( "Tests::User::valid_delete",     1, $user );
$harness->test( "Tests::User::invalid_delete",   1, $user );

# Delete God
$harness->test( "Tests::User::valid_delete", 1, $god );

# Patch interface
my $patch_search = { name => "PLM_TEST_PATCH" };

$harness->test( "Tests::Patch::instantiate", 1 );
$harness->test( "Tests::Patch::setValue",    0, "id" );
$harness->test( "Tests::Patch::getValue",    1, "id", "" );
$harness->test( "Tests::Patch::setValue",    1, "id", "999999" );
$harness->test( "Tests::Patch::getValue",    1, "id", "999999" );
$harness->test( "Tests::Patch::add",         1, );
$harness->test( "Tests::Patch::search_sql", 1, $patch_search );
$harness->test( "Tests::Patch::search_sql", 0, { id => -1 } );
$harness->test( "Tests::Patch::get", 1, $patch_search );
$harness->test( "Tests::Patch::get", 0, { plm_user_id => -1 } );
$harness->test( "Tests::Patch::delete", 1 );
$harness->test( "Tests::Patch::delete", 0 );

# Note interface
my $note_search = { plm_user_id => 5, subject => "-TEST NOTE-" };

$harness->test( "Tests::Note::instantiate", 1 );
$harness->test( "Tests::Note::setValue",    0, "id" );
$harness->test( "Tests::Note::getValue",    1, "id", "" );
$harness->test( "Tests::Note::setValue",    1, "id", "999999" );
$harness->test( "Tests::Note::getValue",    1, "id", "999999" );
$harness->test( "Tests::Note::getValue",    0, "id", "" );

$harness->test( "Tests::Note::add",        1, );
$harness->test( "Tests::Note::search_sql", 1, $note_search );
$harness->test( "Tests::Note::search_sql", 0, { id => -1 } );
$harness->test( "Tests::Note::get", 1, $note_search );
$harness->test( "Tests::Note::get", 0, { plm_user_id => -1 } );
$harness->test( "Tests::Note::delete", 1, $note_search );
$harness->test( "Tests::Note::delete", 0, { plm_user_id => -1 } );

# Software interface
$harness->test( "Tests::Software::instantiate",    1 );
$harness->test( "Tests::Software::add_software",   1, "PLM_TEST_$r" );
$harness->test( "Tests::Software::add_software",   0, "PLM_TEST_$r" );
$harness->test( "Tests::Software::delete_software", 1, "PLM_TEST_$r" );
$harness->test( "Tests::Software::delete_software", 0, "PLM_TEST_$r" );

# Validation interfaces
$harness->test( "Tests::Validation::validation_pass", 1 );
$harness->test( "Tests::Validation::validation_fail", 0 );

# XML interfaces
$harness->test( "Tests::XML::instanciate_QDXml",        1 );
$harness->test( "Tests::XML::instanciate_QDXmlElement", 1 );
$harness->test( "Tests::XML::subrec_container",         1 );
$harness->test( "Tests::XML::subrec_modify",            1 );
$harness->test( "Tests::XML::parse",                    1 );

$harness->report( 3 );

sub get_patch {
    my $xml = new XML::Patch();

    $xml->setElementValue( "version",         ".0.-BETA" );
    $xml->setElementValue( "comment",         "This is a TEST PATCH" );
    $xml->setElementValue( "name",            "PLM_TEST_PATCH" );      # XXX _$r
    $xml->setElementValue( "content",         "EMPTY PATCH CONTENT" );
    $xml->setElementValue( "content_format",  "plaintext" );
    $xml->setElementValue( "private_flag",    "1" );
    $xml->setElementValue( "submit_flag",     "1" );
    $xml->setElementValue( "plm_user_id",     "5" );
    $xml->setElementValue( "plm_software_id", "10" );

    return $xml;
}

