#!/usr/bin/perl -w

use PLM::Util;
use Apache::Constants qw( :common );
use Apache::Util qw( unescape_uri );

$ENV{ PATH } = "/bin:/usr/bin";
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

my $log    = getLog( "ASP::plm_report_results.pl" );
my $config = getConfig();

my $dsn     = $config->get( "dsn" );
my $dsnuser = $config->get( "dsnuser" );
my $dsnpass = $config->get( "dsnpass" );
my $dbh     = DBI->connect( $dsn, $dsnuser, $dsnpass );

my $url = $config->get( "plm_http" );

my $r      = shift;
my %params = $r->args;
my $search_string;
if ( $params{ 'regex_search' } ) {
    $search_string = $params{ 'regex_search' };
} else {
    $search_string = $params{ 'sql_search' };
}

my $name_string;
if ( $params{ 'name' } ) {
    $name_string = $params{ 'name' };
} else {
    $name_string = $search_string;
}

# This is not right, where do my pluses go?
$search_string =~ s/ /+/g;

$r->send_http_header( 'text/html' );

$r->print( <<END );
<html>
<head>
 <title>Linux Kernel Build Report</title>
 <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1">
</head>
<body BGCOLOR="white">
 <h1 align="center">OSDL - Linux Kernel PLM Run Results</h1>
 <h2>$name_string Series</h2>
 <p align="center">
 <table border="1" cellpadding="2" cellspacing="0">
  <tr><th>Patch Name [ID]</th>
END

$sql = "SELECT name " . "FROM plm_filter " . "ORDER BY plm_filter_type_id, id";
my $sth = $dbh->prepare( $sql );
$sth->execute();
my @row = $sth->fetchrow_array;
while ( @row ) {
    $r->print( "<th>$row[ 0 ]</th>" );
    @row = $sth->fetchrow_array;
}
$r->print( "</tr>\n" );

$sql =
  "SELECT pfr.plm_patch_id, pp.name, pfr.result, pfr.result_detail, "
  . "       pf.name, pfr.id, pfrs.code "
  . "FROM plm_patch pp, plm_filter pf, plm_filter_request pfr, "
  . "     plm_filter_request_state pfrs ";
if ( $params{ 'regex_search' } ) {
    $sql .= "WHERE pp.name REGEXP '$search_string' = 1 ";
} else {
    $sql .= "WHERE pp.name LIKE '$search_string' ";
}
$sql .= "  AND pp.id = pfr.plm_patch_id "
  . "  AND pf.id = pfr.plm_filter_id "
  . "  AND pfr.plm_filter_request_state_id = pfrs.id "
  . "ORDER BY pp.id DESC, pf.plm_filter_type_id, pf.id";
$log->msg( 3, "$sql" );
$sth = $dbh->prepare( $sql );
$sth->execute();
@row = $sth->fetchrow_array;
my $kernel = $row[ 1 ];

while ( @row ) {
    $r->print( "<tr><td>$row[ 1 ] [<a href=\"$url"
          . "/plm?module=patch_info&patch_id=$row[ 0 ]\">$row[ 0 ]</a>]</td>" );
    while ( $kernel eq $row[ 1 ] ) {
        $r->print( "<td align=\"center\"" );
        $r->print( "bgcolor=\"salmon\"" )     if ( $row[ 2 ] eq "FAIL" );
        $r->print( "bgcolor=\"lightgreen\"" ) if ( $row[ 2 ] eq "PASS" );
        $r->print( ">" );
        if ( $row[ 2 ] ) {
            $r->print( "<a href=\"$url"
                    . "/plm?module=filter_output&id=$row[ 5]\">$row[ 2 ]</a>" );
        } else {
            $r->print( "$row[ 6 ]" );
        }
        if ( $row[ 4 ] =~ /Regress/ ) {
            my @fields = split ( /, /, $row[ 3 ] );
            $r->print( "<br/>$fields[ 0 ]<br/>$fields[ 1 ]" );
        }
        $r->print( "</td>" );
        @row = $sth->fetchrow_array;
    }
    $r->print( "</tr>\n" );
    $kernel = $row[ 1 ];
}

$r->print( <<END );
 </table>
 </p>
<hr>
<font size="-2">Copyright &copy; Open Source Development Lab &nbsp;
 <a href="http://www.osdl.org/">http://www.osdl.org</a> &nbsp;
 Generated by stp_plm_report.  &nbsp;
 Send issues and feature requests to stp at osdl.org.
</font>
</body>
</html>
END

