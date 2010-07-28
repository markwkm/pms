#!/usr/bin/perl -w

# Mark Wong January 17, 2005 Initial

use strict;

print "\n";
print "Welcome to the [ Sparse on Linux ] Filter V0.1\n";
print "\n";

my $HOME = `pwd`;
chomp $HOME;
my $CONFIG_LOG = $HOME . "/config.log";

my $close_image = "http://www.osdl.org/docsys/images/tigris/icon_arrowfolderopen2_sml.gif";
my $open_image = "http://www.osdl.org/docsys/images/tigris/icon_arrowfolderclosed1_sml.gif";

# We need to keep a list of bullet names in order to close them by
# default later.
my %close_list = ();

# Create a line of the result file
sub logme
{
    system "echo @_ >> $HOME/result.filter";
    print "@_\n";
}

# Run sparse for a given kernel configuration target.
sub run_sparse
{
    my $option = $_[ 0 ];

    # If testing oldconfig, only complete the test if there is a
    # .config.
    return if ( ! -f ".config" && $option eq "oldconfig");
    system "make mrproper > /dev/null 2>&1"
        if ( $option eq "oldconfig" );
    system "make $option > /dev/null 2>&1";

    # Create a bullet for the kernel configuration option.
    $close_list{ $option } = 1;
    print '<li><script type="text/javascript">document.writeln(\'<img id="' . $option . 'Image" src="' . $open_image . '" alt="Open list" onClick="toggle(\\\'' . $option . 'Image\\\', \\\'' . $option . 'List\\\');">\');</script>' . $option . '</li>';
    print "\n";
    print '    <ul id="' . $option . 'List">';
    print "\n";
    my @sparse_output = `make C=2 all 2>&1`;
    my $file = "";
    my @messages = ();
    foreach my $line ( @sparse_output ) {
        chomp $line;
        if ( $line =~ /^  / ) {
            # Sometimes files are repeated, this'll ignore the second
            # isntance.
            if ( @messages > 0 && ! $close_list{ $file } ) {
                $close_list{ $file } = 1;

                # Display just the relative path and filename for each
                # item.
                my $short_filename = $file;
                $short_filename =~ s/^.*CHECK //;

                # Create a bullet for each file that has messages from
                # sparse, and a collapsible bulleted sub-list of each
                # message.
                print '<li><script type="text/javascript">document.writeln(\'<img id="' . $file . 'Image" src="' . $open_image . '" alt="Open list" onClick="toggle(\\\'' . $file . 'Image\\\', \\\'' . $file . 'List\\\');">\');</script>' . $short_filename . '</li>';
                print "\n";
                print '    <ul id="' . $file . 'List">';
                print "\n";
                foreach my $message ( @messages ) {
                    print "    <li>$message</li>\n";
                }
                print "    </ul>\n";
            }
            @messages = ();
            $file = "$option $line";
        } else {
            push @messages, $line;
        }
    }
    print "</ul>\n";
}

print "</pre>\n";
print '<ul id="collapsibleList">';
print "\n";

# This should be a list of all the configurations options for the
# kernel.
#my @config_options = ( "oldconfig", "defconfig", "allmodconfig",
#    "allyesconfig", "allnoconfig" );

# "allmodconfig" and "allyesconfig" are both too big for this
# javascript stuff to work.
my @config_options = ( "oldconfig", "defconfig", "allnoconfig" );
foreach my $option ( @config_options ) {
    run_sparse( $option );
}

print "</ul>\n";

# In order to collapse each bullet, generate the following boatload
# of crap.  If there's an easier way to do this, I haven't found it.
# Nor do I know javascript to begin with...  Or perl for that matter.
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
