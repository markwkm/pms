# an XML object for a source_sync

package PLM::Object::SourceSync::Tar;
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

#  The following scripts all happen on a plm client.  They would be easy enough to turn
#    into functions for the PLM::Source object, but this seemed appropriate at the time.


# This script is to do the appropriate name fix is one is required, or return the name unedited.
sub fix_name{
   my $ref=shift;
   my $name=shift;
   my $tmp=$ref->{ 'name_substitution' };
   if ( $tmp ) {
        my $expression = '$name =~ s' . "$tmp";
        eval $expression;
        if ($@){
            return "";
        }
        return $name;
   }
   return $name;
}

sub name_checks{
    my $ref=shift;
    my $patch_name=shift;
  
    if ( $ref->_patch_not_wanted($patch_name) ){
         return $TRUE;
    } elsif ( $ref->_patch_wanted($patch_name) ){
         return $FALSE;
    }
    return $TRUE;
}

# Use the 'wanted' match to eliminate files
sub _patch_wanted{
    my $ref=shift;
    my $patch_name=shift;
    my $match_pattern=$ref->{ 'wanted_regex' };
    if ( $patch_name !~ m/$match_pattern/ ){
        return( $FALSE );
    } else {
        return $TRUE;
    }
}


# Use the 'not_wanted' match to eliminate files
sub _patch_not_wanted{
    my $ref=shift;
    my $patch_name=shift;
    if($patch_name =~ m/dontuse/){
        return( $TRUE );
    }
    my $match_pattern=$ref->{ 'not_wanted_regex' };
    if ( $patch_name =~ m/$match_pattern/ ){
        return( $TRUE );
    }
    return( $FALSE );
}

# Can file type retrieved properly, from mime type, BEFORE the download?
# This also is only for type 'TAR', and should be made configurable in SourceSync?
#  That's why I put it here.
sub get_file_type{
    my $ref=shift;
    my $file_name=shift;
    my $file_type;

    if ( $file_name =~ /\.gz$/ ) {
        $file_type='gzip';
    } elsif ( $file_name =~ /\.bz2$/ ) {
        #  Text files over 4M were causing upload failures.  We now upload as bzip2/base64encode
        $file_type='bzip2';
    } elsif ( $file_name =~ /\.dif$/ ) {
        $file_type='plaintext';
    } else {
        $file_type="";
    }
    return $file_type;
}

sub isa_base{
    my $ref=shift;
    return $ref->{ 'baseline' };
}

sub get_applies_version {
        my $ref=shift;
        my $file = shift;
        my $repository = shift;
        my $applies_regex=$ref->{ 'applies_regex' };
        my $applies;

        if ( $applies_regex ){
            my $version;
            #  This allows for a simple match, or a complicated replace if needed.
            #  I needed it for the rc and pre versions to subtract to the current version.
            #
            if ( ${applies_regex} =~m/^s\//){
                $version = $file;
                my $expression = '$version =~ ' . "${applies_regex}";
                eval $expression;
                if ($@){
                    return "";
                }
            } else {
                ($version) = $file =~ m/${applies_regex}/;
                if (! $version){
                    return "";
                }
            }
            $applies = $version;
        } else {
            # Default match to 3 or 4 or 5 digit sets
            # should this subtract a version from the last group?
            # Use find_applies?
            ($applies) = $file =~ m/.*(\d+\.\d+\.\d+\.\d+\.\d+|\d+\.\d+\.\d+\.\d+|\d+\.\d+\.\d+).*/;
        }
        if (! $applies){
            return "";
        }
        # with repo name pre-pended.
        $applies =~ s/patch/$repository/;
        if ($applies !~ m/^$repository/) {
            $applies = "$repository" . "-" . "$applies";
        }
        return $applies;

}

1;
