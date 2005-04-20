package PLM::RPC::Filter;

require Exporter;
@ISA = qw( Exporter );

@EXPORT = qw(
  filter_request_by_patch
);

# 'strict' does not seem to work with Exporter.
use PLM::PLM::Patch();
use PLM::PLM::Filter();
use PLM::PLM::FilterRequest();
use PLM::PLM::FilterRequestState();
use PLM::Util;

#
# Grab a list of XML objects representing the filter requests against a patch
#

sub filter_request_by_patch {
    shift;    # shift of class

    # We want one long connection to the database for this
    my $dbh = getDBHandle();
    $dbh->connect();

    my $patch_id = shift;

    my $patch         = new PLM::PLM::Patch();
    my $filter        = new PLM::PLM::Filter();
    my $request       = new PLM::PLM::FilterRequest();
    my $request_state = new PLM::PLM::FilterRequestState();

    return "" unless ( $patch_id && $patch_id =~ /^\d+$/ );
    return "" unless ( $patch->verify_id( $patch_id ) );

    my $ref = $request->search_sql( { plm_patch_id => $patch_id } );

    return "" unless ( $ref && @{ $ref } );

    my @ret;
    for ( @{ $ref } ) {
        $r = $request;
        $request->load( ${ $_ }{ 'id' }, $_ );
        $request->disable_sync();

        $filter->load( $request->getValue( "plm_filter_id" ) );
        $request->setValue( "plm_filter", $filter->getValue( "name" ) );

        $request_state->load( $request->getValue( "plm_filter_request_state_id" ) );
        $request->setValue( "state_code",   $request_state->getValue( "code" ) );
        $request->setValue( "state_detail", $request_state->getValue( "detail" ) );

        $request->setValue( "output", "" );
        #  This is a little workaround to get a PLM::PLM:: object without the database connect.
        #    It is to send the data back to the calling procedure..
        my $r;
        $r->{ 'data' }={};
        bless $r, 'PLM::PLM::Filter';
        $r->loadDataOnly($request);
        push @ret, $r;
    }

    return \@ret;
}

1;
