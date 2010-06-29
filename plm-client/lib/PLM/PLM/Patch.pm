# PLM::Patch Package
#
# Author: 	Nathan Dabney
# Date:		01/04/02
#
# Presents a method reference to a User object in the PLM data space.

package PLM::PLM::Patch;

@ISA = qw(PLM::PLM);
#@ISA = qw(PLM::PLM Exporter);

use strict;
#use Exporter;
use File::MMagic;
use PLM::DB::Handle;
use PLM::PLM;
use MIME::Base64;
use PLM::PLM::Filter;
use PLM::PLM::FilterRequest;
use PLM::Util;
use PLM::Util::TempFile;

BEGIN { }

my $cfg = getConfig();
my $log = getLog( "PLM::PLM::Patch" );

sub new {
    my $self = {};
    my $type = shift;
    bless $self, $type;

    $self->SUPER::new( "plm_patch" );

    $self->addElement( "content",        "" );
    $self->addElement( "content_format", "plaintext" );

    return $self;
}

sub debug {
    my ( $self, $debug ) = @_;

    if ( defined( $debug ) ) {
        $log->debug( $debug );
    }

    return $log->debug;
}

sub add {
    my $self = shift;

    if ( !$self->SUPER::add( @_ ) ) {
        $log->msg( 0, "There was a problem adding the patch" );
        return 0;
    }

    $log->msg( 2, "Validating patch content format type" );

    if ( $self->getValue( "content_format" ) eq "VOID" ) {
        $log->msg( 0, "Addition of patch metadata OK - content VOID" );
        $self->auto_request_filter();
        return $self->getValue( "id" );
    }

    $self->autodetect_content();

    return 0 unless ( $self->set_md5sum() );

    unless ( $self->handle_wrapping( "plaintext:bzip2" ) ) {
        $log->msg( 0, "Failure in handling patch content" );
        return 0;
    }

    if ( $self->patch_save( $self->getValue( "id" ) ) ) {
        $log->msg( 2, "Addition of patch successful" );
        $self->auto_request_filter();
        return $self->getValue( "id" );
    }

    $log->msg( 0, "Addition of patch failed for unknown reason" );
    $self->delete( $self->getValue( "id" ) );
    return 0;
}

sub delete {
    my ( $self, $patch_id ) = @_;
    my $dbh = getDBHandle();

    if ( !$self->SUPER::delete( $patch_id ) ) {
        $log->msg( 0, "There was a problem deleting the patch" );
        return 0;
    }

    $dbh->delete( "plm_filter_request", "plm_patch_id = $patch_id" );

    if ( !$self->patch_delete( $patch_id ) ) {
        $log->msg( 0, "There was a problem deleting the patch from disk" );
        return 0;
    }

    return 1;
}

sub set_md5sum {
    my $self = shift;
    my $sum;

    $sum = $self->detect_md5sum();

    unless ( $sum ) {
        $log->msg( 0, "Failure in set of md5sum" );
        return 0;
    }

    $self->setValue( "md5sum", $sum );

    return 1;
}

sub detect_md5sum {
    my $self = shift;

    my ( $fh, $name ) = getTempFileHandle();

    return 0 unless $name;

    unless ( $self->handle_wrapping( "plaintext" ) ) {
        $log->msg( 0, "Failure in handling patch content" );
        return 0;
    }

    print $fh $self->getValue( 'content' ) || return 0;
    seek( $fh, 0, 0 );

    my $sum = `md5sum $name | cut -d" " -f1`;
    chomp $sum;

    return $sum;
}

# Use 'magic' to determine file-type
sub autodetect_content {
    my $self = shift;

    #  If "content_format" is set, it overrides autodetect
    #  and uuencode and base64 is supported.
    return if ( $self->getValue( "content_format" ) );

    # Autodetect only works on text, gzip and bzip2 files
    my $mm;
    $mm = '/etc/mime-magic'      if ( -f '/etc/mime-magic' );
    $mm = '/usr/share/etc/magic' if ( -f '/usr/share/etc/magic' );
    $mm = '/etc/magic'           if ( ( !$mm ) && ( -f '/etc/magic' ) );
    if (! $mm){
        $log->msg( 0, "No system mime magic file was found." );
    }

    $log->msg( 3, "using mime magic file: '$mm'" );

    my $magic = new File::MMagic( $mm );

    my $type = $magic->checktype_contents( $self->getValue( "content" ) );

    my $found = "plaintext";

    $found = "plaintext:gzip"  if ( $type =~ /gzip/ );
    $found = "plaintext:bzip2" if ( $type =~ /bzip2/ );

    $log->msg( 1, "patch content detected [$type] => [$found]" );

    $self->setValue( "content_format", $found );
}

sub patch_save {
    my ( $self, $id ) = @_;
    my $path    = $cfg->get( "repository_path" );
    my $content = $self->getValue( "content" );

    return 1 if ( $self->getValue( "content_format" ) eq "VOID" );

    panic( "bad repository_path" ) unless $path;

    $path .= "/patch-$id.bz2";
    open( F, ">$path" )
      || panic( "patch_save: can't open patch target [$path]" );
    print F $content;
    close F;

    return 0 unless ( -f $path );

    return 1;
}

sub patch_delete {
    my ( $self, $id ) = @_;
    my $path    = $cfg->get( "repository_path" );
    my $content = $self->getValue( "content" );

    return 1 if ( $self->getValue( "content_format" ) eq "VOID" );

    panic( "bad repository_path" ) unless $path;

    $path .= "/patch-$id.bz2";
    #system "rm -f $path";

    #return 0 if ( -f $path );

    return 1;
}

sub patch_retrieve {
    my ( $self, $id ) = @_;
    my $path = $cfg->get( "repository_path" );

    panic( "bad repository_path" ) unless $path;

    $path .= "/patch-$id.bz2";
    if ( -f $path ) {
        my $content = `cat $path`;
        $self->setValue( "content_format", "plaintext:bzip2" );
        $self->setValue( "content",        $content );
        return 1;
    } else {
        $log->msg( 1, "File missing - setting content_format = VOID" );
        $self->setValue( "content_format", "plaintext" );
        $self->setValue( "content",        "Patch Unavailable" );
        return 1;
    }
}

sub get_depend {
    my ( $self, $type, $patchID ) = @_;
    my $dbh = getDBHandle();
    my $table="plm_patch";

    unless ( $type =~ /apply|obsolete/ ) { return 0 }
    unless ( $dbh->valid( $patchID ) ) { return 0 }

    #if ( $type =~ /apply/ )    { $table = "plm_applies" }
    #if ( $type =~ /obsolete/ ) { $table = "plm_obsoletes" }

    $log->msg( 3, "Building a $type list for patch $patchID" );

    my $ref = $dbh->getAll( "plm_applies_id", $table, "id = $patchID AND plm_applies_id IS NOT NULL AND plm_applies_id != 0" );
    my @list = ();

    if ( $ref ) {
        $log->msg( 4, "get_depend: found " . @{ $ref } . " matches" );
        for ( @{ $ref } ) {
            push @list, ${ $_ }{ plm_applies_id };
        }
    }

    return @list;
}

sub depended_on {
    my ( $self, $patchID ) = @_;
    my $dbh = getDBHandle();

    return -1 unless ( $dbh->valid( $patchID ) );

    return -1 unless ( $self->verify_id( $patchID ) );

    $log->msg( 3, "Checking to see if patch $patchID is depended on" );

    my $ref = $dbh->get( "*", "plm_patch", "plm_applies_id=$patchID" );
    return 1 if $ref;

    $log->msg( 2, "patch $patchID does not have any upward dependencies" );

    return 0;
}

#
# Builds up the internal: @apply_list
#

sub _build_apply_list {
    my ( $self, $id ) = @_;
    my $patch = new PLM::PLM::Patch();

    my @parents = $patch->get_depend( "apply", $id );
    for ( @parents ) {
        $self->_build_apply_list( $_ );
    }

    push @{ $self->{ apply_list } }, $id;
}

#
# Starts the process for building the applies list
#

sub build_applies_tree {
    my $self  = shift;
    my $apply = new PLM::PLM::Patch();
    my $txt   = "";

    $self->{ apply_list } = ();

    $self->_build_apply_list( $self->getValue( "id" ) );

    pop @{ $self->{ apply_list } };
    my $next = pop @{ $self->{ apply_list } };
    while ( $next ) {
        $apply->load( $next );
        $txt .= $apply->getValue( "name" ) . " ($next)<br>";
        $next = pop @{ $self->{ apply_list } };
    }

    chomp $txt;
    $self->setValue( "applies_tree", $txt );

    $self->{ apply_list } = ();
}

#
# Grabs the actual content of the patch (for download...)
#

sub get {
    my ( $self, $id ) = @_;

    unless ( $id ) { panic( "missing id in get()" ) }

    return undef unless ( $self->load( $id ) );

    if ( $self->patch_retrieve( $id ) ) {
        $log->msg( 1, "Content for patch $id retrieved OK" );
    } else {
        $log->msg( 0, "ERROR in retrieving patch $id" );
        return 0;
    }

    if ( $self->getValue( "content_format" ) eq "VOID" ) {
        return 1;
    }

    $self->handle_wrapping( "plaintext:bzip2:uuencode" );

    unless ( $self->getValue( "id" ) eq $id ) {
        $log->msg( 1, "Unknown error on get() populating XML" );
        return 0;
    }

    return 1;
}

sub handle_wrapping {
    my ( $self, $format_target ) = @_;
    my ( @wrap, @type, @target );

    @type = split /:/, $self->getValue( "content_format" );

    unless ( defined $type[ 0 ] ) {
        $type[ 0 ] = "";
    }

    return ( 1 ) if ( $type[ 0 ] eq "VOID" );   # For internal redirect versions

    @target = split /:/, $format_target;

    $log->msg( 2, "Patch Content: [@type] -> [@target]" );

    if ( $type[ 0 ] ne $target[ 0 ] ) {
        $log->msg( 0, "Base format problem, rejecting" );
        return 0;
    }

    my $x;
    for ( $x = 0;
        defined $type[ $x ]
        && defined $target[ $x ]
        && $type[ $x ] eq $target[ $x ];
        $x++
      )
    {
        $log->msg( 2, "Format $type[$x] does not need to change" );
    }

    if ( $x < @type ) {
        for ( my $y = @type - 1; $y >= $x; $y-- ) {
            push @wrap, $type[ $y ];
        }
        $self->unwrap( @wrap );
    }

    @wrap = ();
    if ( $x < @target ) {
        for ( my $y = $x; $y < @target; $y++ ) {
            push @wrap, $target[ $y ];
        }
        $self->wrap( @wrap );
    }

    $self->setValue( "content_format", join ( ':', @target ) );
    return 1;
}

sub unwrap {
    my $self = shift;
    my @wrap = @_;
    my $temp = createTempFile( "plm_patch_unwrap" );

    $log->msg( 2, "unwrap: @wrap" );

    my $cmd = "cat $temp";
    my $tmp_format = $self->getValue( "content_format" );
    my $tmp_format_orig= $tmp_format;
    for ( @wrap ) {
        my $var=$_;
        # Check for supported formats
        if ( $var =~ m/base64/){
             my $tmp_content = MIME::Base64::decode($self->getValue( "content" ));
             $self->setValue( "content", $tmp_content );
             $tmp_format =~ s/\:base64//;
             $self->setValue( "content_format", $tmp_format );
        } elsif ( $var =~ m/uuencode/){
             $cmd .= " | uudecode"; 
             $tmp_format =~ s/\:uudecode//;
        } elsif ( $var =~ m/bzip2/){
             $cmd .= " | bunzip2"; 
             $tmp_format =~ s/\:bzip2//;
        } elsif ( $var =~ m/gzip/){
             $cmd .= " | gunzip"; 
             $tmp_format =~ s/\:gzip//;
        } else { 
             $log->msg( 0, "unwrap: $var is not supported." );
             return 1;
        }
        $tmp_format =~ s/\:$var//;
    }
    open( FILE, ">$temp" ) || panic( "temp unavail: $temp" );
    print FILE $self->getValue( "content" );
    close FILE;

    if ( $tmp_format != $tmp_format_orig){
        $self->setValue( "content_format", $tmp_format );
    }

    $log->msg( 2, "CMD: $cmd" );

    my $text = `$cmd`;
    if ($?){
        panic("Unwrap Command Failed: $cmd" );
    }
    $self->setValue( "content", $text );
    undef $text;

    system "rm -f $temp";
}

sub wrap {
    my $self = shift;
    my @wrap = @_;
    my $temp = createTempFile( "plm_patch_wrap" );

    $log->msg( 2, "wrap: @wrap" );

    my $cmd = "cat $temp";
    for ( @wrap ) {
        if ( $_ =~ m/base64/){
             my $tmp_content = MIME::Base64::encode($self->getValue( "content" ));
             $self->setValue( "content", $tmp_content );
        }
        if ( $_ eq "uuencode" ) { $cmd .= " | uuencode -" }
        if ( $_ eq "gzip" )     { $cmd .= " | gzip" }
        if ( $_ eq "bzip2" )    { $cmd .= " | bzip2" }
    }

    open( FILE, ">$temp" ) || panic( "temp unavail: $temp" );
    print FILE $self->getValue( "content" );
    close FILE;

    $log->msg( 2, "CMD: $cmd" );

    my $text = `$cmd`;
    if ($?){
        panic("Wrap Command Failed: $cmd" );
    }
    $self->setValue( "content", $text );
    undef $text;

    system "rm -f $temp";
}

sub verify {
    my $self = shift;

    return $self->verify_id( @_ );
}

sub auto_request_filter {
    my $self   = shift;
    my $filter = new PLM::PLM::Filter();

    my $software = $self->getValue( "plm_software_id" );

    my $ref =
      $filter->search_sql(
                  { plm_software_id => "0' OR plm_software_id = '$software" } );

    unless ( $ref && @{ $ref } ) {
        $log->msg( 0, "Unable to find any filter to request against" );
        return;
    }
    else {
        $log->msg( 2, "Found " . @{ $ref } . " filter to request against" );
    }

    my $user = $self->getValue( "plm_user_id" );

    for ( @{ $ref } ) {
        panic( "bad filter ID in auto_request: $_" ) unless $_;

        $log->msg( 1, "Auto-requesting filter " . ${ $_ }{ id } );

        my $request = new PLM::PLM::FilterRequest();

        $request->setValue( "plm_filter_id", ${ $_ }{ id } );
        $request->setValue( "plm_user_id",   $user );
        $request->setValue( "priority",      1 );
        $request->setValue( "plm_patch_id",  $self->getValue( "id" ) );

        $request->add();
    }
}

END { }

1;

