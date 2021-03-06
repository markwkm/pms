#!/usr/bin/perl -w

use PLM::Util;
use Apache::Constants qw( :common );
use Apache::Util qw( escape_uri );

$ENV{ PATH } = "/bin:/usr/bin";
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

my $kernel =
  'Linux 2.4=linux-2.4.[0-9]+$:'
  . 'Linux 2.4 Release Canidates=patch-2.4.[0-9]+-rc:'
  . 'Linux 2.4 Prelreases=patch-2.4.[0-9]+-pre:'
  . 'Alan Cox\'s Linux 2.4=patch-2.4.[0-9]+-ac:'
  . 'Itanium Linux 2.4=linux-2.4.[0-9]+-ia64:'
  . 'Linux 2.5=linux-2.5.[0-9]+$:'
  . 'Linux 2.5 Preleases=patch-2.5.[0-9]+-pre:'
  . 'OSDL DCL Linux 2.5=^osdl-:'
  . 'Alan Cox\'s Linux 2.5=patch-2.5.[0-9]+-ac:'
  . 'Andrew Morton\'s Linux 2.5=2.5.[0-9]+-mm:'
  . 'Martin J. Bligh\'s and Linux Scalability Effort\'s Linux 2.5=patch-2.5.[0-9]+-mjb:'
  . 'Itanium Linux 2.5 Patches=linux-2.5.[0-9]+-ia64';

my $log    = getLog( "ASP::plm_report.pl" );
my $config = getConfig();

my $dsn     = $config->get( "dsn" );
my $dsnuser = $config->get( "dsnuser" );
my $dsnpass = $config->get( "dsnpass" );
my $dbh     = DBI->connect( $dsn, $dsnuser, $dsnpass );

my $r = shift;

$r->send_http_header( 'text/html' );

$r->print( <<END );
<html>
<head>
 <title>Linux Kernel Build Report</title>
 <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1">
</head>
<body BGCOLOR="white">
 <h1 align="center">OSDL - Linux Kernel PLM Run Results</h1>
 <p align="center">
 <table border="0">
END

for ( split /:/, $kernel ) {
    @text = split /=/, $_;
    my $sql =
      "SELECT COUNT(*) " . "FROM plm_patch " . "WHERE name REGEXP '$text[ 1 ]'";
    my $sth = $dbh->prepare( $sql );
    $sth->execute();
    my @row = $sth->fetchrow_array;
    if ( @row ) {
        my $display_html = escape_uri( $text[ 1 ] );
        my $name_html    = escape_uri( $text[ 0 ] );
        $r->print(
"<tr><td><b><a href=\"plm_report_results.pl?regex_search=$display_html&name=$name_html\">$text[ 0 ]</a></b> - $row[ 0 ] Patches</td></tr>\n"
        );
    }
}

$r->print( <<END );
 </table>
<hr>
 <table>
  <tr>
   <td>
    <p>
    Search by using regular expressions. (Examples: <a href="http://www.mysql.com/doc/en/Regexp.html">http://www.mysql.com/doc/en/Regexp.html</a>)
    </p>
    <p>
    <form method="get" action="plm_report_results.pl">
     <input type="text" name="regex_search">
     <input type="submit" value="Search">
    </form>
    </p>
   </td>
   <td>
    <p>
    Search by using SQL wildcards. (Examples: % to match any number of characters, or _ to match any single character.)
    </p>
    <p>
    <form method="get" action="plm_report_results.pl">
     <input type="text" name="sql_search">
     <input type="submit" value="Search">
    </form>
    </p>
   </td>
  </tr>
 </table>
<hr>
<font size="-2">Copyright &copy; Open Source Development Lab &nbsp;
 <a href="http://www.osdl.org/">http://www.osdl.org</a> &nbsp;
 Generated by stp_plm_report.  &nbsp;
 Send issues and feature requests to stp at osdl.org.
</font>
</body>
</html>
END

