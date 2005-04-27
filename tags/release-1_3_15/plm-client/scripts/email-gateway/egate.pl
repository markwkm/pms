#!/usr/bin/perl -w

#Programmed by Nathan Dabney of the Open Source Development Lab
#Copyright (C) 2002 Open Source Development Lab 
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 2 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

# 
# The Patch Lifecycle Manager Email-Gateway
#

use strict;
use Mail::Internet;
use GnuPG::Tie::Decrypt;

#use PLM::Util::Log;
#use PLM::Util::Config;
use PLM::Object::Patch;
use PLM::PLMClient;
use PLM::Util;
use PLM::Util::TempFile;

#
# LOCAL CONFIGURATION
# 

my $now = time();
my $log = getLog( "egate" );
my $cfg = getConfig();
my $rpc = new PLM::PLMClient($cfg);

#
# Process EMAIL on STDIN
#

my $Body_File;    # Filename for the body of the message
my $Header;       # Object for generating reply messages
my $XML;          # Object to send to server

my %Flag;         # Meta-data holding place
my %Info;         # Information parsed from the email meta data
my $Software;     # Flag to point the patch at a certain repository

my $userID;       # ID for the user to add the patch under
my $softwareID;   # ID for the software repository

$Flag{ encrypted_pgp } = 0;
$Flag{ patch }         = 0;

Get_Software_Name();
Read_Email();
Parse_Header();
Parse_Body();
GPG_Decrypt();

$userID = Verify_Login();

unless ( $userID ) {
    $log->msg( 0, "Authentication FAILED, Exiting" );
    exit 1;
}

unless ( $Flag{ patch } ) {
    $log->msg( 0, "No patch content was detected, our work here is done" );
    Email_User( "No patch detected, completed processing", [] );
    exit 0;    # If there is no patch, we are done here
}

Verify_Name();
Verify_Applies();
my $patch_ref=Patch_Work();
Upload_Patch($patch_ref);


#
# Sub-routines
#

sub Get_Software_Name {
    if ( defined $ARGV[ 0 ] ) {
        $Software = $ARGV[ 0 ];
    } else {
        $Software = $cfg->get( "default_software_package" );
    }

    panic( "Missing Repository" ) unless $Software;

    my @data = $rpc->ASP( "software_verify", $Software );
    $softwareID = $data[ 0 ];

    panic( "Bad Repository [$Software] reason: did not resolve" )
      unless $softwareID;
}

sub Read_Email {
    $Body_File = createTempFile( "body" );

    my $message = new Mail::Internet( \*STDIN );

    $Header = $message->head();

    my $body = $message->body();

    open( FILE, ">$Body_File" );
    print FILE @{ $body };
    close FILE;

    $log->msg( 1, "Body of message (" . @{ $body } . ") lines saved" );

    if ( @{ $body } > 3000000 ) {
        $log->msg( 0, "Message too large, sending reject message" );
        my $txt = "The message you sent was " . @{ $body };
        $txt .= " lines long which is\n";
        $txt .= "beyond the limit of 3,000,000.\n\n";
        $txt .= "Please try splitting this up into multiple patches and\n";
        $txt .= "setting up dependencies between them.";

        Email_User( "[PLM] Error", [ $txt ] );
        exit 0;
    }

    undef $message;
    undef $body;
}

sub Parse_Body {
    $log->msg( 2, "Parse_Body( $Body_File )" );
    open( FILE, $Body_File );

    for ( <FILE> ) {
        chomp;
        $log->msg( 3, "PARSE: [$_]" );
        unless ( Parse_For_Flags( $_ ) ) { close FILE; return }

        next if ( !/^#/ );
        Parse_For_MetaData( $_ );
    }

    close FILE;
}

sub Parse_For_Flags {
    $_ = shift;

    if ( /BEGIN\ PGP\ MESSAGE/ ) {
        $log->msg( 1, "Encrypted data found, setting encrypted_pgp" );
        $Flag{ encrypted_pgp } = 1;
        return 0;
    }

    # diff default style
    if ( /^(\<|\>)/ ) { $Flag{ patch } = 1 }

    # diff -u style
    if ( /^(---|\+\+\+)/ ) { $Flag{ patch } = 1 }

    # diff -c style
    if ( /^(\*\*\*)|(\!)/ ) { $Flag{ patch } = 1 }

    if ( $Flag{ patch } ) {
        $log->msg( 1, "Patch content detected" );
        return 0;
    }

    return 1;
}

sub Parse_Header {
    $Info{ user } = undef;
    $Info{ pass } = "";

    $Info{ user } = $Header->get( 'Reply-To' )
      || $Header->get( 'From' )
      || $Header->get( 'Sender' )
      || undef;

    if ( defined $Info{ user } ) {
        chomp $Info{ user };
        $log->msg( 0, "Message received from user: " . $Info{ user } );

        # $Info{ user } = $rpc->ASP( "user_find_by_email", $Info{ user } );
    }
}

sub Parse_For_MetaData {
    $_ = shift;

    if ( /^#+\s*plm.*(username|user):?\s*(\S+)/i ) { $Info{ user } = $2 }

    if ( /^#+\s*plm.*(password|pass):?\s*(\S+)/i ) { $Info{ pass } = $2 }

    if ( /^#+\s*plm.*login:?\s*(\S+)(\s|:)+(\S+)/i ) {
        $Info{ user } = $1;
        $Info{ pass } = $3;
    }

    if ( /^#+\s*plm.*name:?\s*(\S+)/i ) { $Info{ name } = $1 }

    if ( /^#+\s*plm.*private\S*:?\s*(\S+)/i ) {
        my $bool = $1;
        if ( $bool =~ /(no|false|off|0)/ ) {
            $Info{ private_flag } = 0;
        } else {
            $Info{ private_flag } = 1;
        }
    }

    if ( /^#+\s*plm.*submit\S*:?\s*(\S+)/i ) {
        my $bool = $1;
        if ( $bool =~ /(no|false|off|0)/ ) {
            $Info{ submit_flag } = 0;
        } else {
            $Info{ submit_flag } = 1;
        }
    }

    if ( /^#+\s*plm.*applies:?\s*(.*)$/i ) {
        for my $apply_ver ( split /\s*,\s*|\s+|\s*:\s*/, $1 ) {
            $log->msg( 3, "applies entry: $apply_ver" );
            push @{ $Info{ applies } }, $apply_ver;
        }
    }
}

sub GPG_Decrypt {

    unless ( $Flag{ encrypted_pgp } ) {return}    # Not an excrypted message

    $log->msg( 1, "Decrypting body of message" );

    system "mv $Body_File $Body_File.asc";
    system "gpg $Body_File.asc 2> $Body_File.gpg";

    $log->msg( 1, "Done Decrypting Body" );

    Parse_Body();
}

sub Verify_Login {
    my $User = $Info{ user };
    my $Pass = $Info{ pass };

    if ( defined $User && defined $Pass ) {
        my ($userID) = $rpc->ASP( "user_verify", $User, $Pass );
        if ( $userID ) {
            $log->msg( 1, "User $User VERIFIED" );
            $Info{ 'return_email' } = $rpc->ASP( "user_get_email", $User );
            $log->msg( 1, "User e-mail is  $Info{ 'return_email' }  for $User" );
            return $userID;
        } else {
            $log->msg( 1, "User $User NOT VERIFIED" );
            return 0;
        }
    }

    $log->msg( 0, "INVALID OR MISSING USERNAME OR PASSWORD" );
    return 0;
}

sub Verify_Applies {
    unless ( defined $Info{ applies } ) { Reject_Bad_Applies() }

    my @apply = @{ $Info{ applies } };
    my @valid;
    my $OK = 0;

    for ( @apply ) {
        $log->msg( 2, "Verifying existance of patch: $_" );
        my @data = $rpc->ASP( "patch_find_by_name", $_ );
        if ( $data[ 0 ] ) {
            $OK = 1;
            push @valid, $data[0];
        }
    }
    $Info{ applies } = \@valid;

    unless ( $OK ) {
        Reject_Bad_Applies();
    }

    $log->msg( 0, "Message contained applies: @valid" );
    return $OK;
}

sub Reject_Bad_Applies {
    $log->msg( 0, "Rejecting message due to lack of 'applies'" );
    my @msg = (
          "Please re-submit patch with a valid:\n\n",
          "\t#plm applies: #.#.#\n\n",
          "version metadata tag in the comments.  This needs to specify a\n",
          "known version for the software package you are submitting to.\n"
    );
    Email_User( "[PLM] Error in patch submission", \@msg );
    exit 0;
}

sub Verify_Name {
    Reject_Bad_Name( "missing" ) unless defined $Info{ name };
    my $User = $Info{ user };
    my $Pass = $Info{ pass };
    my $Name = $Info{ name };

    my @data = $rpc->ASP( "patch_find_by_name", $Name );

    Reject_Bad_Name( "conflict" ) if ( $data[ 0 ] > 0 );
}

sub Reject_Bad_Name {
    my $Name = $Info{ name };
    my $txt  = shift || "FIXME";

    $log->msg( 0, "Reject patch name '$Name' due to [ $txt ]" );
    my @msg = (
                "Your patch submission has been rejected.\n\n",
                "The name attempted was: $Name\n",
                "Reason given for rejection: $txt\n\n",
                "Please email support if you have any questions\n"
    );
    Email_User( "[PLM] Error in patch submission", \@msg );
    exit 0;
}

#sub Set_Applies {
#    my $id    = shift;
#    my $User  = $Info{ user };
#    my $Pass  = $Info{ pass };
#    my $type  = "apply";
#    my @apply = @{ $Info{ applies } };
#
#    for ( @apply ) {
#        my @data = $rpc->ASP( "patch_find_by_name", $_ );
#        my $dep_id = $data[ 0 ];
#        $log->msg( 0, "Pointing patch $id to version: $dep_id" );
#        $rpc->ASP( "patch_add_depend", $User, $Pass, $type, $id, $dep_id );
#    }
#}

sub Patch_Work {
    my $Patch;
    my $in_sig = 0;

    $log->msg( 1, "Slurping the Patch content into memory" );

    open( FILE,  $Body_File );
    open( PATCH, "| bzip2 | uuencode - > $Body_File.new" )
      || panic( "new patch" );

    for ( <FILE> ) {
        if ( /^.*#.*plm/ ) {next}
        if ( /^-+BEGIN\ (PGP|GPG|GnuPG)\ SIGNATURE-+$/ ) { $in_sig = 1 }
        unless ( $in_sig || /^#.*plm/i ) { print PATCH $_ }
        if ( /^-+END\ (PGP|GPG|GnuPG)\ SIGNATURE-+$/ ) { $in_sig = 0 }
    }

    close FILE;
    close PATCH;

    open( PATCH, "$Body_File.new" );
    for ( <PATCH> ) {
        $Patch .= $_;
    }
    close PATCH;

    $Patch =~ /(.+)\n$/s;    # Uh, extended chomp?  ;-)
    $Patch = $1;

    $log->msg( 2, "Patch slurped into memory" );

    Build_XML_Patch();
    return \$Patch;
}

sub Build_XML_Patch {
    $XML = new PLM::Object::Patch();

    if ( defined $Info{ private_flag } ) {
        $XML->setElementValue( "private_flag", $Info{ private_flag } );
    }

    if ( defined $Info{ submit_flag } ) {
        $XML->setElementValue( "submit_flag", $Info{ submit_flag } );
    }

    $XML->setElementValue( "name",            $Info{ name } );
    $XML->setElementValue( "plm_user_id",     $userID );
    $XML->setElementValue( "content_format",  "plaintext:bzip2:uuencode" );
    $XML->setElementValue( "plm_software_id", $softwareID );
    $XML->setElementValue( "plm_applies_id",  ${$Info{ applies }}[0] );

    $log->msg( 1, "XML Patch Object Populated" );
}

sub Upload_Patch {
    my $patch_ref=shift;
    #my $xml  = $XML->toString;
    my @data = $rpc->ASP( "patch_add", $Info{ user }, $Info{ pass }, $XML, ${ $patch_ref } );

    my $res = $data[ 0 ];
    #undef $xml;
    my $txt;

    if ( $res ) {
        my $sub = "Patch ";
        if ( exists $Info{ name } ) { $sub .= $Info{ name } }
        $sub .= " accepted as Patch ID#$res";
        $log->msg( 0, $sub );
        Email_User( $sub, [ $sub ] );
        Email_Admin( "$Info{user} submitted patch #$res" );
        #Set_Applies( $res );
    } else {
        $log->msg( 0, "ERROR - could not submit patch to ASP server" );
        Email_User( "Error submitting patch, admins have been notified" );
        Email_Admin( "ERROR submitting patch for user $Info{user}" );
    }
}

sub Email_User {
    my $subject  = shift || "[PLM] automatic email";
    my $body_ref = shift || undef;
    my @body;

    if ( $body_ref ) {
        @body = @{ $body_ref };
    } else {
        $body[ 0 ] = "";
    }

    my $Message = new Mail::Internet( $Header->header() );
    my $reply   = $Message->reply();
    my $support = $cfg->get( "support_email" );

    if ( $Info{ 'return_email' } =~ m/\@/ ){
        $reply->head->header_hashref( { 'To' => $Info{ 'return_email' } } );
    } else {
        $log->msg( 0, "No user email in database:  $Info{ 'return_email' }" );
    }
    $reply->head->header_hashref( { 'Reply-To' => $support } );
    $reply->head->header_hashref( { 'Subject'  => $subject } );
    $reply->head->header_hashref(
                           { 'From' => "Patch Lifecycle Manager <$support>" } );

    $reply->body( \@body );

    my @sent = $reply->smtpsend();

    if ( @sent ) {
        for ( @sent ) {
            $log->msg( 0, "Email_User: $_ - $subject" );
        }
    } else {
        $log->msg( 0, "ERROR Unable to Email User" );
    }
}

sub Email_Admin {
    my $subject = shift;
    my $body_ref = shift || undef;
    my @body;

    if ( defined $body_ref ) {
        @body = @{ $body_ref };
    } else {
        $body[ 0 ] = "";
    }

    my $email   = new Mail::Internet();
    my $support = $cfg->get( "support_email" );
    my $admin   = $cfg->get( "admin_email" );

    $email->head->header_hashref(
        {
            To      => $admin,
            From    => "PLM <$support>",
            Subject => $subject
        }
    );

    my @sent = $email->smtpsend();

    unless ( @sent ) {
        $log->msg( 0, "PANIC CANNOT EMAIL ADMIN" );
        $log->msg( 0, "SUBJECT: $subject" );
        exit 1;
    }

    $log->msg( 1, "Email_Admin: $subject" );
}

