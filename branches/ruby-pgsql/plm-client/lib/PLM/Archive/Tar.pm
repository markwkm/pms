#!/usr/bin/perl

#
# This class will represent the information in an FTP/Web archive.  
#    It will find all the files and their paths in the archive to 
#    the specified depth.
#
package PLM::Archive::Tar;

# This should probably be turned into a child class of PLM/Source.pm
#  or XML/Source.pm.  I would rather not do that until I am sure of 
#  what changes are going to occur to the Object/Data Passing Models.

# Create a user agent object
use LWP::UserAgent;
# For base64 encoding
use MIME::Base64();
our $DEBUG = 0;

if ($DEBUG){
    use Data::Dumper;
}

#
# Constructor
#
sub new {
     my $package = shift;
     my $source_object=shift;    # This is the local XML Source object, will not work remotely
     my $source_sync_object=shift;    # This is the local XML Source Sync object, will not work remotely
     my $remote_path="";
     my $depth;
     my $parent_URL = $source_object->{ 'root_location' };
     my $top_URL="$parent_URL";
     if ( $source_sync_object ){
         $remote_path = $source_sync_object->{ 'search_location' };
         if ($remote_path){$top_URL.="/" . "$remote_path";}
         $depth = $source_sync_object->{ 'depth' };
     }
     if (! $depth){
        $depth=0;
     }
# Needed Data:  URL, depth, web page information, list with relative path and files in archive.
#                    list  with URLS to check and their depths
#
#  Make the first URL active by putting it in the list
#
     my $ref = {
                 'URL' => $top_URL,
                 'depth' => $depth,
                 'page_content' => '',
                 'active_urls' => ( [ [ "$top_URL", 0 ] ] ),
                 'archive_files' => ( [ ] ),
                 'parent_URL' => $parent_URL 
               };
     if ($DEBUG){
         print Data::Dumper::Dumper(%{$ref});
     }
     bless $ref, $package;
     return $ref;            
}

#
# Return a reference to the final list of files and the relative paths.
# Public function
#
sub get_files {
    my $ref = shift;

    #  Do this until the 'active_urls' are all gone
    while ( $#{@{$ref->{'active_urls'}}} > -1 ){
        if ($DEBUG){
            print Data::Dumper::Dumper(%{$ref});
        }
        if ($ref->_deeper()){
            $ref->get_top_page_content();
            print "----------\n$ref->{'page_content'}\n----------\n" if ($DEBUG > 1);
            $ref->_grep_files();
            shift @{$ref->{'active_urls'}};
         } else {
            print "Do not need '$ref->{'active_urls'}->[0][0]'\n";
            shift @{$ref->{'active_urls'}};
         }
    }
    return $ref->{'archive_files'};
}

#
# Retrieve the web page to a local file, passed in as an argument.
#  
sub get_content_to_file{
   my $ref = shift;
   my $filename=shift;
   my $remote_path=shift;
   if (! $filename){
       return -1;
   }
   my $url = ${$ref->{'active_urls'}}[0][0];
   if ($DEBUG){
       print "Check URL $url\n";
   }

   #
   # Something smarter needs to be done instead of throwing in "/"'s at the
   # end of the url, at the beginning of the remote_patch and inbetween.  URL's
   # are being generating with "///"'s in them.
   #
   if ($remote_path){
       $url=$url . "/" . $remote_path;
   }
   $url=$url . "/" . $filename;
   $ref->{'remote_identifier'}=$filename;

   $ua = LWP::UserAgent->new;
   $ua->agent("PLM/0.1 patch spider http://developer.osdl.org/dev/stp/");
   # Create a request
   my $req = HTTP::Request->new(GET => $url );
   my $res = $ua->request($req, $filename);
   return $res->is_success;
}

#
# Retrieve the next web page. from the active_urls list.
#
sub get_top_page_content{

    my $ref = shift;
    my $filename=shift;
    my $remote_path=shift;
    my $url = ${$ref->{'active_urls'}}[0][0];
    if ($filename){ 
        $url=$ref->{'parent_URL'};
        if ($url !~ m/\/$/){ $url .= "/";}
        if ($remote_path){ $url .= $remote_path; }
        if ($url !~ m/\/$/){ $url .= "/";}
        $url.= $filename ;
    }
    if ($DEBUG){
        print "Check URL $url\n";
    }
    $ua = LWP::UserAgent->new;
    $ua->agent("PLM/0.1 patch spider http://developer.osdl.org/dev/stp/");
    # Create a request
    my $req = HTTP::Request->new(GET => $url );
    
    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);
    # Check the outcome of the response
    if ($res->is_success) {
        # Populate our $page_content
        #print $res->content;
        $ref->{ 'page_content' } = $res->content;
        return 1;
    } else {
        #print "The URL ${url} is inaccessible.\n";
        return 0;
    }

}

#
#  Find all the URLS on the page retrieved, classify and store them
#           Clasifications:  keep:  .txt, .gz, .bz2, .tgz, .dif
#                            discard:  .gz.sign, .bz2.sign, .txt(?)
#                            search:  end in /
#
sub _grep_files {
    my $ref = shift;
    my $match; 
    my $quote;

    while ( ($quote, $match) = $ref->{ 'page_content' } =~ m/\<\s*A\s*HREF\s*\=\s*(\'|\")(.*?)(\'|\")\s*\>/gsi ) {
        print "----------\npage_content = $ref->{ 'page_content' }\n----------\n" if ($DEBUG > 1);
        $ref->{ 'page_content' } =~ s/\<\s*A\s*HREF\s*\=\s*(\'|\")(.*?)(\'|\")\s*\>//si;
	     if ( $match =~ m/\.gz$|\.bz2$|\.tgz$|\.dif$/ ) {
            my $directory := $ref->{'active_urls'}->[0][0];
            $directory =~ s/$ref->{'parent_URL'}\/?//;
            # Account for index pages being on the same level
            if ($directory =~ m/htm$|html$/) {
                $directory.='/..';
            }
            push @{$ref->{'archive_files'}} , [ $match, $directory ];
	     } elsif ($match =~ m/\.gz\.sign|\.bz2\.sign|\.txt|\?\w\=\w/) {
	        print "Do not need '$match'\n" if ($DEBUG);
	     } else {
	        # Is this a directory?
            # We need to get rid of parent directory.
            # Explicit and relative urls.
            my $active_url=${$ref->{'active_urls'}}[0][0];
            if ( $active_url =~ m/(http\:\/\/[a-zA-Z_0-9\.]\/)?${match}\/?\w+\/?/ or $match =~ /\.\./ ){
                print "Do not need parent '$match'\n" if ($DEBUG);
                next;
            }
            my $new_depth=$ref->{'active_urls'}->[0][1] + 1;
            print "Directory: $match, $active_url  Depth:  $new_depth\n" if ($DEBUG);
            if ( $ref->_deeper($new_depth) ){
                if ( $active_url =~ m/\/$/ or $match =~ m/^\//){
                    push @{$ref->{'active_urls'}}, ([ "$active_url" . "$match", $new_depth ]);
                } elsif ( $active_url =~ m/htm$|html$/ ) {
                    push @{$ref->{'active_urls'}}, ([ "$active_url". "/../". "$match", $new_depth ]);
                } else {
	                push @{$ref->{'active_urls'}}, ([ "$active_url". "/". "$match", $new_depth ]);
                }
            }
        }
    }
}

#
#  Find out if we are supposed to search further, return 'true' if so
#
sub _deeper {
     my $ref=shift;
     my $new_depth = shift;
     if (! $new_depth) {
        # then check current URL
        print "new_depth = $ref->{'active_urls'}->[0][1]\n" if ($DEBUG);
        $new_depth = $ref->{'active_urls'}->[0][1];
     }
     if ( $new_depth < $ref->{'depth'} + 1 ){
         return 1;
     } else {
         return 0;
     }
}

#
#  Simple base64 encode
#
sub base64{
   my $ref=shift;
   return MIME::Base64::encode( $ref->{ 'page_content' } );
} 

#
#  After we have retrieved a base source bundle, it may need post-processing.
#
#
sub post_process{
     my $ref=shift;

    print "Unpacking source: $ref->{remote_identifier}\n";
    if ( $ref->{remote_identifier} =~ /bz2$/ ) {
        system "tar -jxf $ref->{remote_identifier}";
    }

    if ( $ref->{remote_identifier} =~ /gz$/ ) {
        system "tar -zxf $ref->{remote_identifier}";
    }

    $ref->{remote_identifier} =~ s/(.*)\.tar.*/$1/;

    return $ref->{remote_identifier};
}

return 1;
