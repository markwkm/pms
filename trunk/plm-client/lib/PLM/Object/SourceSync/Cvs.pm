# an XML object for a speccific source_sync

package PLM::Object::SourceSync::Cvs;
@ISA = qw( PLM::Object::SourceSync);

use PLM::Object::SourceSync;

use strict;
use warnings;

my $FALSE=0;
my $TRUE=1;

sub new {
    my $pkg = shift;
    my $self = {};

    bless $self, $pkg;
    $self->SUPER::new();

    return $self;
}

#  The following scripts all happen on a plm client. 


#
# This script is to return an appropriate name for the CVS pull
# an increment or a date?  The argument is the software_type.
#
sub fix_name{
   my $ref=shift;
   my $name=shift;  # This is the date/remote_identifier
   my $repository=shift;  # This is the cvs module name

   $name=~s/\s\w+$//g;
   $name=~s/ /-/g;
   $name=~s/://g;
   $repository .= "-cvs-$name";
   return $repository;

}

sub name_checks{
    my $ref=shift;
    my $patch_name=shift;
  
    # For CVS, there are no check here.
    return $FALSE;
}

# Can file type retrieved properly, from mime type, BEFORE the download?
# This also is only for type 'TAR', and should be made configurable in SourceSync?
#  That's why I put it here.
#
# For CVS 'plaintext' seems appropriate, these will only be bases 
# just now, so it is not important.
sub get_file_type{
    return 'plaintext';
}

# this is the same as for TAR.
sub isa_base{
    my $ref=shift;
    if ($ref->getValue('baseline') =~ m/Y/i){
        return $TRUE;
    } 
    return $FALSE;
}

# For CVS the applies version should be the last CVS base pull.  
#  However, we will not be doing this just yet.
sub get_applies_version {
    my $ref=shift;
    my $file = shift;
    my $repository = shift;
    my $applies_regex=$ref->getValue('applies_regex');
    my $applies;

    if ( $applies_regex ){
        my $version;
        $applies =~ s/patch/$repository/;
    }
    return $applies;
}

1;
