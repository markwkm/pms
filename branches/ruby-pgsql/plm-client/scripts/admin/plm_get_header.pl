#!/usr/bin/perl -w

use LWP::Simple;
use Config::Simple;

#
# Our headers are in Zope so not directly accessible...
#   This script copies them to a file my CGI can access.
#
# Usage:  plm_get_header.pl <header_URL> <footer_URL>
#

# These should not change often.
# Each entry needs 3 items indent:  Type, link, title, Indent
# Type is 'folder', 'link' or 'document'

@sidebar_entries=( ['link', '/plm-cgi/plm?module=home', 'PLM', '0'],
                   ['document', '/plm/PLM-HOWTO.html', 'PLM How-to', '2'],
                   ['link', '/plm-cgi/plm?module=userpage', 'User Page', '2'],
                   ['link', '/plm-cgi/plm?module=search', 'Search', '2'],
                   ['link', '/plm-cgi/plm?module=addpatch', 'Add Patch', '2'],
                   ['link', '/plm-cgi/plm?module=logout', 'Logout', '2'],
                   ['link', 'http://developer.osdl.org/dev/plm', 'PLM Development', '2'],
                   ['link', '/lab_activities/kernel_testing/stp/', 'STP', '0']
);


$config_file=shift;
if (!$config_file){
   $config_file='/etc/plm/plm_get_header.cfg';
}

print "Loading values from config file:  $config_file\n";
Config::Simple->import_from("$config_file", \%Config);

$out_file=$Config{'outfile'};
print "Opening output file:  " . $out_file . "\n";

open OF, ">$out_file";


# Not necessary because header has label.
#print OF "Content-type:text/html\n\n";

$content = get ($Config{"headerURL"});
$content =~ s/standard_html_header/<a href=\'\/plm-cgi\/plm?module=home\'>PLM<\/a>/;
$content =~ s/<base href.*>//;
print "Open $Config{'headerURL'}\n";
print OF ($content);

print  OF "CONTENT_INSERT<BR>\n";

print "Open $Config{'logoURL'}\n";
$content= get ($Config{"logoURL"});
print OF ($content);

print_side_begin();
foreach $entry (@sidebar_entries){
    print_side_entry($entry)
}
print_side_end();

$content= get ($Config{"footerURL"});
print "Open $Config{'footerURL'}\n";
print OF ($content);

close OF;

exit;


sub print_side_begin{
    print OF '<p class="quicklinks"></p>';
}


sub print_side_entry{
    my $array_ref=shift;
    my ($this_type, $this_link, $this_title, $indent)=@{$array_ref};
    my $spacer="";
    while ($indent){
        $indent-=1;
        $spacer="&nbsp\;" . $spacer;
    }
    $this_title= $spacer . $this_title;
    print OF "<a class=\"quicklinks\" href=$this_link>$this_title</a>\n";
}


sub print_side_end{
    print OF '<p class="quicklinks"></p>';
}
