#!/usr/bin/perl

#
# This class will access the information in a CVS repository.  
#
package PLM::Archive::Cvs;

# This should probably be turned into a child class of PLM/Source.pm
#  or XML/Source.pm.  I would rather not do that until I am sure of 
#  what changes are going to occur to the Object/Data Passing Models.

# Load module for CVS access
use Cvs;
# For base64 encoding
use MIME::Base64();

our $TRUE=1;
our $FALSE=0;

our $DEBUG = $FALSE;

if ($DEBUG){
    use Data::Dumper;
}

#
# Constructor, needs a parent class to inherit 'new' for all these
#
sub new {
    my $package = shift;
    my $source_object=shift;    # This is the local XML Source object, will not work remotely
    my $source_sync_object=shift;    # This is the local XML Source Sync object, will not work remotely
    #my $remote_identifier = shift;

    # cvs options
    my $sc_connect_string = $source_object->getValue( 'root_location' );  # -d
    my $sc_password = $source_object->getValue( 'source_password' ) || "";

    # command options
    # my $sc_branch = $source_object->getValue( 'sc_branch' );  # Not yet 
    my $sc_module = $source_object->getValue( 'sc_module' );
    my $last_remote_identifier = '';
    if ($source_sync_object){
        $last_remote_identifier = $source_sync_object->getValue('last_timestamp'); # Do not need this for a pull
    }

# Needed Data:  CVSRoot, web page information, list with relative path and files in archive.
#                    list  with URLS to check and their depths
#
     my $ref = {
                 'connect_string' => $sc_connect_string,
                 'password' => $sc_password,
                 'module' => $sc_module,
                 'remote_identifier' => "",
                 'page_content' => '',
                 'last_remote_identifier' => $last_remote_identifier,
                 'archive_files' => ( [ ] ),
               };
     if ($DEBUG){
         print Data::Dumper::Dumper(%{$ref});
     }
     bless $ref, $package;
     return $ref;            
}

=head1 FUNCTION get_files
#
# Return a reference to the final list of 'remote_indentifier' 
# and NULL placeholder to keep the structure the same as for TAR
#  There will only be one item for CVS, the current head's identifier,
#  or if that was already pulled an empty list
#  Program flow:
#    * Date tag for the current head comes from remote identifier.
#    * Find the last plm pull from head base or patch; as is set here
#    * If they are the same return no item
#    * else return head's date tag as remote identifier.
#    ( Note the cvs server should be in your timezone for now , this 
#          will be fixed by adding a timezone to the date)
#
=cut

sub get_files {
    my $ref = shift;

    #  Do this until the 'active_urls' are all gone
    if ($DEBUG){
        print Data::Dumper::Dumper(%{$ref});
    }
    $ref->_set_remote_identifier();

    if ($ref->{'last_remote_identifier'}){
        if ( $ref->_cvs_rdiff() ) {
            push @{$ref->{'archive_files'} } , [ $ref->{'remote_identifier'}, "" ];
            $ref->{'last_remote_identifier'} = $ref->{'remote_identifier'};
        }
    } else {
        # This case is the first one.
        push @{$ref->{'archive_files'} } , [ $ref->{'remote_identifier'}, "" ];
        $ref->{'last_remote_identifier'} = $ref->{'remote_identifier'};
    }

    # archive_files get an array with [ $remote_identifier, "" ]
    return $ref->{'archive_files'};
}

=head1 FUNCTION get_content_to_file

 Retrieve the item to a local file, passed in as an argument.
  This is always a 'base' source tree: do a cvs checkout and export.
  Make sure exported directory has the correct name.

=cut

sub get_content_to_file{
   my $ref = shift;
   $ref->{'remote_identifier'}=shift;

   if ($DEBUG){
       print "Check CVS Repository $ref->{'connect_string'}\n";
   }
   # Pull item from CVS based on date or tag
   # return 1 if success
   return $ref->_cvs_export();
}

=head1 FUNCTION get_content_to_file

# Retrieve the patch via rdiff. from the active_urls list.
#   This must be vs. the applies' tag.  Tricker than TAR.
#   Should I rename to get_diff_patch or ?

=cut

sub get_top_page_content{

    my $ref = shift;
    my $remote_identifier=shift;
    if ($DEBUG){
        print "Check CVS Repository " . $ref->{'connect_string'} . "\n";
    }
    #
    # We must get applies information here.
    #
    #
    # Do CVS rdiff, to get patch
    #
    # Check the outcome of the response
    if ( $ref->_cvs_rdiff() ) {
        # Populate our $page_content
        return $TRUE;
    } else {
        #print "The URL ${url} is inaccessible.\n";
        return $FALSE;
    }

}

#
# Simple base64 encode, 
# Make this to inherit from parent
# if we want to upload 
#
sub base64{
   my $ref=shift;
   return MIME::Base64::encode( $ref->{ 'page_content' } );
} 

# We will need export, rdiff
# We will only ever pull, never update anything.

sub _cvs_export{
     
    use Cvs::Result::Export;
    my $ref = shift;

    # The destination gets renamed to the software type later...
    my $cvs = new Cvs( $ref->{'remote_identifier'}, 
                       cvsroot => $ref->{'connect_string'}, 
                       password => $ref->{'password'} ) or die $Cvs::ERROR;

     
    my $results = new Cvs::Result::Export();
    $results = $cvs->export( $ref->{module}, { date => $ref->{'remote_identifier'} } );
    if ( ! defined $results ){
        print "CVS export error:  $cvs->_error\n";
        return $FALSE;
    } elsif ( ! $results->{success} ) {
        if ( $results->{error} ){
            print "CVS error:  $results->{error}\n";
        } else {
            #
            # For :pserver: even when it completes, 'success' is not marked.
            # However for all legit' failures I saw a CVS Error message.
            #
            if ($ref->{'connect_string'} =~m/^:pserver:/){
                return $TRUE;
            }
            print "CVS error--no message returned\n";
            return $FALSE;
        }
        return $FALSE;
    }
    return $TRUE;
}


# We need the remote identifier for the 'base' too.
sub _cvs_rdiff{
    use Cvs::Result::RdiffList;
    my $ref = shift;

    my $cvs = new Cvs( $destination, 
                       cvsroot => $ref->{ 'connect_string' }, 
                       password => $ref->{'password'} ) or die $Cvs::ERROR;

    my $results = new Cvs::Result::RdiffList();
    $results = $cvs->rdiff( $ref->{'module'}, { to_date => $ref->{'remote_identifier'}, from_date => $ref->{'last_remote_identifier'} } );
    if ( ! defined $results ){
        print "CVS export error:  $cvs->_error\n";
        return $FALSE;
    } elsif ( ! $results->{success} ) {
        print "CVS error:  $results->{error}\n";
        return $FALSE;
    }
    # The results object looks like this successful, empty:
    #{
    #            'success' => 1,
    #            'index' => -1,
    #            'last' => -1,
    #            'items' => []
    #          }, 'Cvs::Result::RdiffList' );
    if ( ! $results->{ 'success' } ){
        # Command failed
        return $FALSE;
    } elsif ( $results->{ 'last' } == -1) {
        # No difference
        return $FALSE;
    } else {
        # There are differences
        my $item;
        foreach $item ($results->{'items'}){
            $ref->{'page_content'}.=$item;
        }
        return $TRUE;
    }
}

sub _set_remote_identifier{
    my $ref = shift;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $tz;
    if ($isdst){
        $tz = 'PDT';
    } else {
        $tz = 'PST';
    } 
    $ref->{'remote_identifier'} = sprintf ( "%02d%02d%02d %02d:%02d:%02d %s", $year%100, $mon + 1, $mday, $hour, $min, $sec, $tz );
}

#
#  After we have retrieved a base source bundle, it may need post-processing.
#
#
sub post_process{
     my $ref=shift;
     
     return $ref->{remote_identifier};
}

return 1;
