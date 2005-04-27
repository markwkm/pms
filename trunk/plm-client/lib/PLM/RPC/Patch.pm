
# module responsible for patch functions

package PLM::RPC::Patch;

use SOAP::MIME;
use MIME::Entity;

@ISA = qw( Exporter );
@ISA = qw(Exporter SOAP::Server::Parameters); # to get envelope

# symbols to export by default
@EXPORT = qw(
  patch_add
  patch_find_by_name
  patch_get
  patch_get_list
  patch_get_value
  patch_get_software_name
);

use strict;
use PLM::Validation::Suite;
use PLM::PLM::Patch;
use PLM::Object::Patch;
use PLM::PLM::PatchACL;
use PLM::Util;

require Exporter;

my $log = getLog( "PLM::RPC::Patch" );

my @applies_list = ();    # The apply tree of death

BEGIN { }

my $config = getConfig();

# add a patch
sub patch_add {
    my $username;
    my $patch = new PLM::PLM::Patch();
    my $acl   = new PLM::PLM::PatchACL();

    shift;                 # Package name, may be including package if called from SOAP
    $username = $_[ 0 ];

    # Run standard validation
    unless ( PLM::Validation::Suite::validate( "patch_add", @_ ) ) {
        $log->msg( 0, "Unable to authenticate patch_add for user: $_[0]" );
        return 0;
    }

    $log->msg( 3, "Converting the raw text to XML" );
    $patch->loadDataOnly( $_[ 2 ] );

    $log->msg( 3, "Checking Patch namespace before patch add" );
    if ( $acl->patch_name_acl(
                               $patch->getValue( "plm_software_id" ),
                               $patch->getValue( "name" ),
                               $patch->getValue( "plm_user_id" )
        ) )
    {
        $log->msg( 0, "Patch add failed ACL check" );
        return 0;
    }

    # Get the single attachment
    my $envelope = pop;
    $log->msg( 2, "Patch add getting attached file. " . $#_ . ", " . ref( $envelope) . ", "  . $envelope);
    if (ref  $envelope eq 'SOAP::SOM'){
        $log->msg( 0, "Inside envelope exists conditional." );
        foreach my $part (@{$envelope->parts}) {
           $log->msg( 0, "Attachment found! (".ref($$part). ", " . ref($part) . ", " . $part  . ")");
           my $content = $$part->bodyhandle->as_string;
           # Content is set already if the attachment is empty
           if ($content){ 
               $patch->setElementValue( 'content', $content);
           }
        }
    }  # Else the content variable is set as for web interface uploads, or is a base.

    $log->msg( 2, "Attempting to patch_add for: [$username]" );
    my $ret = $patch->add();

    return $ret;
}

# delete a patch
sub patch_delete {
    shift;                  # Package name, may be including package if called from SOAP
    my ( $username, $password, $patch_id ) = @_;
    my $patch = new PLM::PLM::Patch();
    my $user  = new PLM::PLM::User();

    $log->msg( 1, "$username is attempting to delete patch $patch_id" );

    my $user_id = $user->login( $username, $password );

    unless ( $user_id ) {
        $log->msg( 0, "Invalid login" );
        return 0;
    }

    unless ( $user->is_admin( $username ) ) {
        $patch->load( $patch_id );
        unless ( $user_id eq $patch->getValue( "plm_user_id" ) ) {
            $log->msg( 0, "Refused access to delete patch" );
            return 0;
        }
    }

    if ( $patch->depended_on( $patch_id ) ) {
        $log->msg( 0, "Cannot delete patch, has depends" );
        return 0;
    }

    $log->msg( 2, "Patch delete access granted" );

    my $ret = $patch->delete( $patch_id );

    return $ret;
}

# Check to see if anybody depens on a patch id
sub patch_can_delete {
    shift;                  # Package name, may be including package if called from SOAP
    my ( $username, $password, $patch_id ) = @_;
    my $patch = new PLM::PLM::Patch();
    my $user  = new PLM::PLM::User();

    my $user_id = $user->login( $username, $password );

    unless ( $user_id ) {
        $log->msg( 0, "SECURITY: Invalid login at patch_can_delete" );
        return 0;
    }

    unless ( $user->is_admin( $username ) ) {
        $patch->load( $patch_id );
        unless ( $user_id eq $patch->getValue( "plm_user_id" ) ) {
            return 0;
        }
    }

    if ( $patch->depended_on( $patch_id ) ) {
        return 0;
    }

    return 1;
}

# patch get
sub patch_get {
    shift;                  # Package name, may be including package if called from SOAP
    my ( $data ) = @_;
    my $patch = new PLM::PLM::Patch();

    my $ret = $patch->get( $data );

    return "PANIC: MISSING PATCH OR BAD REQUEST" unless ( $ret );

    return $patch;
}

=head1 FUNCTION patch_get_list

Pass a ref to list of patch ID's get a ref to list of 'reverse' flags.

=cut 

sub patch_get_list {
    shift;
    my $field = shift;
    my $array_ref = shift;
    my $id;
    my $return_array_ref="";
    $patch = new PLM::PLM::Patch();
    foreach  $id (@{$array_ref}){
        $patch->load( $id );
        ($value) = $patch->getValue( $field );
        push @{$return_array_ref}, $value;
    }
    return $return_array_ref;
}


# patch_get_value
# This should be written to get 1 or more fields.
sub patch_get_value {
    shift;                  # Package name, may be including package if called from SOAP
    my ( $id, $field ) = @_;
    my $value;
    my $patch;

    $patch = new PLM::PLM::Patch();
    $patch->load( $id );
    ($value) = $patch->getValue( $field );
    ## ($value) = $patch->get_value( $id, $field );

    $log->msg( 1, "PANIC: MISSING PATCH $id OR BAD REQUEST $field" ) unless ( defined $value );

    return $value;
}

sub patch_get_software_name {
    shift;                  # Package name, may be including package if called from SOAP
    my $id = shift;
    my $software_id=0;
    my $software_name='';
   
   my $patch = new PLM::PLM::Patch();
   $patch->load( $id );
   ($software_id) = $patch->getValue( 'plm_software_id' );

   if (! $software_id){
        return '';
   }
   my $software = new PLM::PLM::Software();
   $software->load( $software_id );
   $software_name = $software->getValue( 'name');
   return $software_name;

}

sub patch_find_by_name {
    my $patch = new PLM::PLM::Patch();

    shift;                  # Package name, may be including package if called from SOAP
    my $name = shift;    # Get the patch name

    my $ret = $patch->search_sql( { name => $name } );

    return 0 unless defined $ret;    # return 0 if nothing was found

    return ${ $ret }[ 0 ]{ id };
}

#
# Run a series of sanity checks on the input for a search
#
sub search_sanity_check {
    my %field;
    my $dbh = getDBHandle();

    $field{ id }                 = "int";
    $field{ rsf }                = "int";
    $field{ created }            = "time";
    $field{ deleted }            = "time";
    $field{ modified }           = "time";
    $field{ accessed }           = "time";
    $field{ plm_user_id }        = "int";
    $field{ plm_software_id }    = "int";
    $field{ name }               = "alpha";
    $field{ private_flag }       = "int";
    $field{ submit_flag }        = "int";
    $field{ order }              = "meta";
    $field{ limit }              = "meta";

    my $token = shift;
    my $key   = shift;

    while ( $token ) {
        return 0 unless defined $key;
        return 0 unless $field{ $token };
        if ( $field{ $token } eq "int" ) {
            return 0 unless ( $key =~ /^\d+$/s );
        }
        if ( $field{ $token } eq "time" ) {
            return 0 unless ( $key =~ /^(\<|\>)\d+$/s );
        }
        if ( $field{ $token } eq "alpha" ) {
            $key =~ s/\*/%/g;
            return 0 unless ( $dbh->valid( $key ) );
        }
        if ( $token eq "order" ) {
            $key =~ s/DESC//;

            return 0 unless $field{ $key };
            return 0
              unless ( ( $field{ $key } eq "int" )
                       || ( $field{ $key } eq "alpha" ) );
        }
        if ( $token eq "limit" ) {
            return 0
              unless ( ( $key =~ /^\d+$/s ) || ( $key =~ /^\d+\,\d+$/s ) );
        }

        $token = shift;
        $key   = shift;
    }

    $log->msg( 2, "query passed search sanity check" );

    return 1;
}

#
# Builds up the global: @applies_list
#

sub build_apply_list {
    my $id    = shift;
    my $patch = new PLM::PLM::Patch();
    my $build_apply_list_limit = shift;
    if ( !$build_apply_list_limit){ $build_apply_list_limit=10000;}
    my $i= shift;
    if (! $i) {$i=0;}

    my @parents = $patch->get_depend( "apply", $id );
    for ( @parents ) {
        $i++;
        if ($i > $build_apply_list_limit ){
            last;
        }
        build_apply_list( $_, $build_apply_list_limit, $i );
    }

    push @applies_list, $id;
}

#
# Returns the applies name for a given patch object
#

sub _get_applies_list {
    my $patch = shift;
    my $my_limit = shift;
    my $apply = new PLM::PLM::Patch();
    my $txt   = "";

    build_apply_list( $patch->getValue( "id" ), $my_limit );

    pop @applies_list;
    my $next = pop @applies_list;
    while ( $next ) {
        $apply->load( $next );
        $txt .= $apply->getValue( "name" ) . " ($next)<br>";
        $next = pop @applies_list;
    }

    unless ( $txt ) { $txt = "[ none - baseline ]" }

    $log->msg( 3, "Applies list: $txt" );

    return $txt;
}

#
# Search for patches based on conditions given
#

sub patch_search {
    my $dbh   = getDBHandle();
    my $patch = new PLM::PLM::Patch();
    shift;                  # Package name, may be including package if called from SOAP
    my ( $username, $password ) = ( shift, shift );

    if ( $username ) {
        if ( !PLM::Validation::User::isAuthenticated( $username, $password ) ) {
            $username = "";
        }
    }

    if ( search_sanity_check( @_ ) == 0 ) {
        warn "SECURITY: FAILURE ON SEARCH SANITY CHECK";
        return "";
    }

    my %search;
    my %meta;
    my $token = shift;
    my $key   = shift;

    while ( $token ) {
        $key =~ s/\*/%/g;

        if ( $token eq "order" && $key =~ /DESC$/ ) {
            $key =~ s/(.*)DESC$/$1 DESC/;
        }

        $search{ $token } = $key;

        $token = shift;
        $key   = shift;
    }

    $search{ order } = "id" unless ( defined $search{ order } );
    $search{ limit } = 10   unless ( defined $search{ limit } );

    # Start the database connection (pooling)
    $dbh->connect();

    my $ref = $patch->search_sql( \%search );

    return "" unless ( $ref && @{ $ref } );

    my @ret;
    for ( @{ $ref } ) {
        $patch->load( ${ $_ }{ 'id' } );
        $patch->setValue( "applies_tree", _get_applies_list( $patch, '6' ) );
        my $p = new PLM::Object::Patch();
        $p->loadDataOnly($patch);
        $log->msg( 5, "Adding to return from search: " . $p->getElementValue( 'name' ) );
        push @ret, $p;
    }

    # Close the database connection
    $dbh->disconnect();

    return @ret;
}

#
# Grab all the relevant information about a Patch ID
#
# Does NOT include the content of the actual patch
#

sub patch_get_info {
    shift;                  # Package name, may be including package if called from SOAP
    my $patch = new PLM::PLM::Patch();
    my $id    = shift;
    my $dbh   = getDBHandle();

    return "" unless ( $id =~ /^\d+$/ );    # Does not use Validation
    return "" unless ( $patch->verify( $id ) );    # Does patch exist
    return "" unless ( $patch->load( $id ) );      # Pull the main data in

    # Connect to the database
    $dbh->connect();

    # Get the user information
    my $user = new PLM::PLM::User();
    $user->load( $patch->getValue( 'plm_user_id' ) );
    $patch->setValue( "plm_user_name", $user->getValue( 'name' ) );

    # Get the software information
    my $soft = new PLM::PLM::Software();
    $soft->load( $patch->getValue( 'plm_software_id' ) );
    $patch->setValue( "plm_software_name", $soft->getValue( 'name' ) );

    # Get Applies List
    $patch->setValue( "applies_tree", _get_applies_list( $patch ) );

    # Disconnect (yay for connection pooling)
    $dbh->disconnect();

    return $patch;
}

END { }

1;
