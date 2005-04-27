package PLM::RPC::Supervisor;

use SOAP::MIME;
use MIME::Entity;

use DBI::DBD;
use PLM::Util;
use Mail::Mailer;

require Exporter;
@ISA = qw( Exporter );

@EXPORT =
  qw( get_applies_tree get_request set_filter_request_state submit_result );

BEGIN { }

my $log    = getLog( "PLM::RPC::Supervisor" );
my $config = getConfig();

$ENV{ PATH } = "/usr/local/bin/:/bin:/usr/bin";    # Required for ccache support
$ENV{ CCACHE_DIR } = $config->get( "ccache_dir" ) || "/tmp/plm-ccache";
$ENV{ CCACHE_NLEVELS } = $config->get( "ccache_nlevels" ) || 3;

# This starts the DB connection pooling for the startup of the script
my $dsn     = $config->get( "dsn" );
my $dsnuser = $config->get( "dsnuser" );
my $dsnpass = $config->get( "dsnpass" );
my $dbh     = DBI->connect( $dsn, $dsnuser, $dsnpass );

# Set state values.
my $state_queued    = 1;
my $state_pending   = 2;
my $state_running   = 3;
my $state_completed = 4;
my $state_canceled  = 5;
my $state_failed    = 6;

my $next_request;    # This really should be renamed.
my $patch_id = 0;
my $location;
my $command;
my $plm_user_id;
my $software;

sub _cleanup_stale_requests {

    # I wonder if it's better to combine this isn't one massive UPDATE.
    my $sql = "SELECT id, runtime " . "FROM plm_filter " . "WHERE rsf = 1";
    $log->msg( 3, "$sql" );
    my $sth = $dbh->prepare( $sql );
    $sth->execute();
    my @row = $sth->fetchrow_array;
    while ( @row ) {
        my $time = time() - ( $row[ 1 ] || 4000 );
        $sql =
          "UPDATE plm_filter_request "
          . "SET plm_filter_request_state_id = $state_queued "
          . "WHERE plm_filter_request_state_id != $state_completed "
          . "  AND plm_filter_request_state_id != $state_queued "
          . "  AND plm_filter_request_state_id != $state_failed "
          . "  AND plm_filter_request_state_id != $state_canceled "
          . "  AND started < $time "
          . "  AND plm_filter_id = $row[0]";
        $log->msg( 3, "$sql" );
        panic( "Unable to cleanup stale requests." )
          unless $dbh->do( $sql );
        @row = $sth->fetchrow_array;
    }
}

sub _email_filter_results {
    my $sql;
    $sql =
      "SELECT pu.email, pu.name, pp.name, pp.id "
      . "FROM plm_user pu, "
      . "     plm_filter_request pfr, "
      . "     plm_patch pp "
      . "WHERE pu.id = pfr.plm_user_id "
      . "  AND pfr.id = $next_request "
      . "  AND pp.id = pfr.plm_patch_id";
    $log->msg( 3, "$sql" );
    my $sth = $dbh->prepare( $sql );
    $sth->execute();
    my $email;
    my $username;
    my $patch_name;
    ( $email, $username, $patch_name, $patch_id ) = $sth->fetchrow_array;
    $log->msg( 3, "$username <$email>: $patch_name [$patch_id]" );

    return unless $email;
    
    # now check if the filters are done.
    $sql = "SELECT count(id) " .
           "FROM plm_filter_request " .
           "WHERE plm_patch_id = $patch_id " . 
           "AND plm_filter_request_state_id IN ( 1, 2, 3 )";
    $sth = $dbh->prepare( $sql );
    $sth->execute();
    ( $not_done ) = $sth->fetchrow_array;

    return if ( $not_done );

    my $body;
    $body =
      "Patch $patch_name (submitted by $username <$email>) has been "
      . "accepted by the PLM as patch #$patch_id.\n\n"
      . "The filter results are:\n";

    $sql =
      "SELECT pf.name, pfr.result, pfr.result_detail, pp.plm_applies_id "
      . "FROM plm_filter pf, plm_filter_request pfr, plm_patch pp "
      . "WHERE pfr.plm_filter_id = pf.id "
      . "  AND pfr.plm_patch_id = pp.id "
      . "  AND pp.id = $patch_id ";
      #. "  AND pfr.id = $next_request";
    $log->msg( 3, "$sql" );
    $sth = $dbh->prepare( $sql );
    $sth->execute();
    my $iter=0;
    my @row=();
    my $appliesID;
    while ( @row = $sth->fetchrow_array() ){
       $iter++;

       my $filter_name   = $row[ 0 ];
       my $result        = $row[ 1 ];
       my $result_detail = $row[ 2 ];
       $appliesID     = $row[ 3 ];
   
       my $tmp = "  $filter_name";
       $tmp .= " " x ( 19 - length( $filter_name ) );
       $tmp .= $result;
       $tmp .= " " x ( 4 - length( $result ) ) . "  $result_detail\n";
       $body .= $tmp;

       $filter_name="";
       $result="";
       $result_detail="";
    }

    #@row = $sth->fetchrow_array;
    panic( "Unable to retrieve filter request information. [$next_request]" )
      unless ( $iter > 0 );

    @row=();

    $body .= "\nThis patch applies to:\n";
    my $current_patch_id = $appliesID;
#    $sql =
#      "SELECT pp.name, pp.id, pp.plm_applies_id"
#      . "FROM plm_patch pp "
#      . "WHERE pp.id = $current_patch_id ";
#    $log->msg( 3, "$sql" );
#    $sth = $dbh->prepare( $sql );
#    $sth->execute();
#    @row = $sth->fetchrow_array;

    if ( $current_patch_id > 0 ) {
        while ( $current_patch_id > 0 ) {
            $sql              =
              "SELECT pp.name, pp.id, pp.plm_applies_id "
              . "FROM plm_patch pp "
              . "WHERE pp.id = $current_patch_id ";
            $sth = $dbh->prepare( $sql );
            $log->msg( 3, "$sql" );
            $sth->execute();
            @row = $sth->fetchrow_array;
            $body .= "  [$row[1]]\t$row[0]\n";
            $current_patch_id = $row[ 2 ];
        }
    } else {
        $body .= "\tNone, this is a baseline patch.\n";
    }

    my $plm_http = $config->get( 'plm_http' ) || "http://localhost/perl";

    $body .= "\nFor patch details, download and filter run logs:\n"
      . "$plm_http/plm?module=patch_info&patch_id=$patch_id\n\n"
      . "-The Patch Lifecycle Manager";

    $log->msg( 3,
              "Mailing Results:  '[PLM] #$patch_id $patch_name ($filter_name)' $email" );

    my $from = $config->get( "support_email" );
    my $mailer = Mail::Mailer->new();
    $mailer->open(
                   {
                     From    => $from,
                     To      => $email,
                     Subject => "[PLM] #$patch_id $patch_name ($filter_name)",
                   }
    );

    print $mailer $body;
    $mailer->close();

}

 # This method only called from plm_build_tree.pl.  It should be moved.
sub get_applies_tree {
    shift;                  # Package name, may be including package if called from SOAP 
    my ( $current_patch_id ) = @_;
    my @tree = ( $current_patch_id );

    my $next_patch = _get_target_patch( $current_patch_id );
    while ( $next_patch != 0 ) {
        push @tree, $next_patch;
        $next_patch = _get_target_patch( $next_patch );
    }
    return \@tree;
}

sub _get_next_available_request {
    my ( $my_type ) = @_;
    $log->msg( 3, "Checking for filter requests for type: $my_type" );

    # Generate the SELECT statement to get a filter id.
    my @list = split /:/, $my_type;
    my $filter_type_list = join ( "', '", @list );
    my $sql =
      "SELECT pfr.id, pfr.plm_patch_id, pf.location, pf.command, pf.runtime, ps.name "
      . "FROM plm_filter_type pft, plm_filter pf, plm_filter_request pfr, "
      . "     plm_software ps, plm_patch pp "
      . "WHERE pft.code IN ('$filter_type_list') "
      . "AND (pft.id = pf.plm_filter_type_id "
      . "     OR pf.plm_filter_type_id = 0) "
      . "AND pf.id = pfr.plm_filter_id "
      . "AND pfr.plm_filter_request_state_id = $state_queued "
      . "AND pfr.plm_patch_id = pp.id "
      . "AND pp.plm_software_id = ps.id "
      . "ORDER BY pfr.priority, pfr.id "
      . "LIMIT 1";
    $log->msg( 3, "$sql" );

    # Execute the statement.
    my $sth = $dbh->prepare( $sql );
    $sth->execute();
    my @row = $sth->fetchrow_array;
    return @row if ( @row );

    # There are no available tests to run
    $log->msg( 3, "No filter requests found." );
    return 0;
}

sub get_request {
    shift;                  # Package name, may be including package if called from SOAP 
    my ( $my_type ) = @_;

    _cleanup_stale_requests();
 
    # This is an application lock.  Otherwise the request goes out too many times.
    my $rv = _get_lock('get_request', '5');
    return 0 unless ( $rv );

    ( $next_request, $patch_id, $location, $command, $runtime, $software ) =
      _get_next_available_request( $my_type );

    if (! $next_request) {
        _release_lock('get_request');
        return 0;
    }

    my $time = time();
    my $sql  =
      "UPDATE plm_filter_request "
      . "SET plm_filter_request_state_id = $state_pending, "
      . "    started = $time "
      . "WHERE plm_filter_request_state_id = $state_queued "
      . "  AND id = $next_request";

    $rv = $dbh->do( $sql );
    _release_lock('get_request');
    if ( ! $rv ) {
        return 0;
    } else {
        my @data;
        push  @data, $next_request, $patch_id, $location, $command, $runtime, $software ;
        return \@data;
    }
}

sub set_filter_request_state {
    shift;                  # Package name, may be including package if called from SOAP 
    my ( $request_id, $state ) = @_;
    my $sql =
      "UPDATE plm_filter_request "
      . "SET plm_filter_request_state_id = $state "
      . "WHERE id = $request_id ";
    return 0 unless ( $dbh->do( $sql ) );
    return 1;
}

sub submit_result {
    shift;                  # Package name, may be including package if called from SOAP 
    my ( $request_id, $filter_result, $output ) = @_;
    $log->msg( 0, "request # $request_id = $filter_result" );

    # SOAP uploads were timing out, changed to attachment.
    if (ref  $output eq 'SOAP::SOM' ){
        $log->msg( 0, "Inside attachment conditional for submit_result." );
        foreach my $part (@{$output->parts}) {
           $log->msg( 0, "Attachment found! (".ref($$part). ", " . ref($part) . ", " . $part  . ")");
           $output = $$part->bodyhandle->as_string;
        }
    } # Else content var is set.

    # I know there's a better way to do this...  
    # In this function: $next_request = $request_id
    $next_request = $request_id;

    my $modified_result;
    my $result_detail;

    if ( $filter_result =~ /RESULT: (\w+)/ ) {
        $modified_result = $1;
    } else {
        warn "Missing required information from results (result)";
    }

    # Set the plm_filter_request_state_id depending on the result.
    my $state;
    if ( $modified_result eq "PASS" ) {
        $state = $state_completed;
    } else {
        $state = $state_failed;
    }

    if ( $filter_result =~ /RESULT-DETAIL: (.+)$/ ) {
        $result_detail = $1;
    } else {
        warn "Missing required information from results (result-detail)";
    }

    my @data;
    push @data, $output;
    my $time = time();
    my $sql  =
      "UPDATE plm_filter_request "
      . "SET result = '$modified_result', "
      . "    result_detail = '$result_detail', "
      . "    output = ?, "
      . "    completed = $time, "
      . "    plm_filter_request_state_id = $state "
      . "WHERE id = $request_id ";
    $log->msg( 3, "$sql" );
    panic( "Unable to update Request" )
      unless $dbh->do( $sql, undef, @data );

    _email_filter_results();

    _cleanup_stale_requests();
}

sub _get_target_patch {
    my ( $current_patch_id ) = @_;

    $sql =
      "SELECT plm_applies_id "
      . "FROM plm_patch "
      . "WHERE id = $current_patch_id";
    $log->msg( 3, "$sql" );
    $sth = $dbh->prepare( $sql );
    $sth->execute();
    if ( $DBI::rows > 0 ) {
        @row = $sth->fetchrow_array;
        return $row[ 0 ];
    }
    return 0;
}

sub _get_lock {
    # Only one of these locks will work per session.
    # A second lock will release the first.
    my ( $lock_name, $wait_time) = @_;
    my $sth = $dbh->prepare( "SELECT GET_LOCK(\'$lock_name\', $wait_time)" );
    $sth->execute;
    my @result = $sth->fetchrow_array;
    return $result[0];  # NULL or 0, we did not get the lock, 1 we got it
}

sub _release_lock {
    my ( $lock_name) = @_;
    my $sth = $dbh->prepare( "SELECT RELEASE_LOCK(\'$lock_name\')" );
    $sth->execute;
    my @result = $sth->fetchrow_array;
    return $result[0]; # NULL or 0, we did not release the lock, 1 we released it
}

END { }

1;
