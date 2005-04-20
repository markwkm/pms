#!/usr/bin/perl -w

# Mark Wong January 12, 2005 Initial
# JL        January 15, 2005 Use same version source headers, print
#                            results to stdout. 
#                            Print Little header
# Mark Wong January 14, 2005 Perled it.

use strict;

print "\n";
print "Welcome to the [ Sparse on PostgreSQL ] Filter V0.1\n";
print "\n";
print "This filter configures the postgresql source and then\n";
print "runs sparse on all the *.c files, excluding the contrib.\n";
print "\n";

my $HOME = `pwd`;
chomp $HOME;
my $CONFIG_LOG = $HOME . "/config.log";

my $close_image = "http://www.osdl.org/docsys/images/tigris/icon_arrowfolderopen2_sml.gif";
my $open_image = "http://www.osdl.org/docsys/images/tigris/icon_arrowfolderclosed1_sml.gif";

my $WARN_COUNT = 0;
my $ERROR_COUNT = 0;

# Create a line of the result file
sub logme
{
    system "echo @_ >> $HOME/result.filter";
    print "@_\n";
}

#
# TEST: Did the patch program report an error
#
if ( -f "patch.error" ) {
    logme( "RESULT: FAIL" );
    logme( "RESULT-DETAIL: Patch did not apply cleanly, cannot build" );
    exit( 1 );
}

chdir "postgresql";
system "./configure --enable-thread-safety --enable-debug >> $CONFIG_LOG 2>&1";
chdir "src";

print "</pre>\n";
print '<ul id="collapsibleList">';
print "\n";

my %close_list;
my @filelist = `find . -name '*.c'`;
foreach my $file ( @filelist ) {
    chomp $file;
    my @sparse_output = `sparse -I$HOME/postgresql/src/include -I$HOME/postgresql/src/interfaces/libpq $file 2>&1`;
    if ( @sparse_output > 0 ) {
        $close_list{ $file } = 1;
        print '<li><script type="text/javascript">document.writeln(\'<img id="' . $file . 'Image" src="' . $open_image . '" alt="Open list" onClick="toggle(\\\'' . $file . 'Image\\\', \\\'' . $file . 'List\\\');">\');</script>' . $file . '</li>';
        print "\n";
        print '    <ul id="' . $file . 'List">';
        print "\n";
        foreach my $line ( @sparse_output ) {
            chomp $line;
            print "    <li>$line</li>\n";
            if ( $line =~ /warning:/ ) {
                ++$WARN_COUNT;
            } elsif ( $line =~ /error:/ ) {
                ++$ERROR_COUNT;
            }
        }
        print "    </ul>\n";
    }
}
print "</ul>\n";

print '<script type="text/javascript">';
print "\n";
print '    document.getElementById(\'collapsibleList\').style.listStyle = "none"';
print "\n";
foreach my $file ( keys %close_list ) {
    print '    document.getElementById(\'' . $file . 'List\').style.display = "none";';
    print "\n";
}
print '    function toggle(image, list) {';
print "\n";
print '        var listElementStyle = document.getElementById(list).style;';
print "\n";
print '        if (listElementStyle.display == "none") {';
print "\n";
print '            listElementStyle.display = "block";';
print "\n";
print '            document.getElementById(image).src="' . $close_image . '";';
print "\n";
print '            document.getElementById(image).alt="Close list";';
print "\n";
print '        } else {';
print "\n";
print '            listElementStyle.display="none";';
print "\n";
print '            document.getElementById(image).src="' . $open_image . '";';
print "\n";
print '            document.getElementById(image).alt="Open list";';
print "\n";
print '        }';
print "\n";
print '    }';
print "\n";
print "</script>\n";
print "<pre>\n";

if ( $ERROR_COUNT == 0 ) {
    logme( "RESULT: PASS" );
} else {
    logme( "RESULT: FAIL" );
}
logme( "RESULT-DETAIL: $WARN_COUNT warnings, $ERROR_COUNT errors" );

