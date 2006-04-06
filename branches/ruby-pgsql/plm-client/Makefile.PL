use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use ExtUtils::MakeMaker;
require 5.006000;
use strict;

use File::Basename;
use File::Spec::Functions qw|:ALL|;
use Config;

# Grab out any custom cmdline args
my %args = (
            pkg_name        => 'plm',
            name            => 'plm',
            DESTDIR         => undef
            );

# Set DESTDIR in the command line in the .spec file for the 'build' location
# perl Makefile.PL DESTDIR=%{buildroot}
# The spec later moves it to the install location
# On gentoo, this will be the final location.

my @pass_args;
foreach my $arg (@ARGV) {
    my ($key, $value) = split /=/, $arg;
    if (exists $args{$key}) {
        $args{$key} = $value;
    } else {
        push @pass_args, $arg;
    }
}

die "This requires MakeMaker version > 5.45.  You have '$ExtUtils::MakeMaker::VERSION'.\n"
    unless ($ExtUtils::MakeMaker::VERSION > 5.45);

my %opts = (
            'INSTALLDIRS'   => 'site',
            'NAME'          => $args{name},
            'VERSION_FROM'  => 'lib/PLM/Util.pm',
            'AUTHOR'        => 'Open Source Development Labs, Inc.',
            'EXE_FILES'     => [ qw(
                                     scripts/admin/asp_supervisor.pl
                                     scripts/admin/plm_add_software.pl
                                     scripts/admin/plm_get_header.pl
                                     scripts/admin/plm_reset_request.pl
                                     scripts/admin/plm_user
                                     scripts/admin/plm_add_filter.pl
                                     scripts/admin/plm_filter_check.pl
                                     scripts/admin/plm_source_sync.pl
                                     scripts/admin/plm_add_filter_type.pl
                                     scripts/admin/plm_filter_output.pl
                                     scripts/admin/plm_request_filter.pl
                                     scripts/admin/plm_status.pl
                                     scripts/client/plm_build_tree.pl
                                     scripts/client/plm_build_app.pl
                                     scripts/client/plm_information.pl
                                     scripts/client/plmsend
                                     scripts/client/server-dead.sh
                                     scripts/email-gateway/egate.pl
                                     scripts/tests/call_rpc.pl
                                     contrib/eidetic-sync.pl
                                     ) ],
            'PREREQ_FATAL' => 0,
            'PREREQ_PM' => {
                'SOAP::Lite' => 0,
                'Carp'           => 0,
                'File::Spec'     => 0.82,
                'Config::Simple' => 0,
                'File::Temp'     => 0.12,
                'Compress::Zlib' => 1.33,
                'MailTools'      => 1.58,
                'SOAP::Lite'     => 0.55,
            },
            );

WriteMakefile( %opts );

sub install_clause {
    my ($source, $target_dir, $overwrite) = @_;
    $overwrite = 1 unless (defined($overwrite));

    my $text = '';

    $text .= "install :: $source\n";
    $text .= "\t\${MKPATH} $target_dir\n";
    $text .= "\t\${CHMOD} a+rx $target_dir\n";
    if ($source) {
        if (-d $source) {
            # If we're copying a directory, update all permissions of subdirs & files
            $text .= "\tfind $source -type d | xargs \${CHMOD} a+rx\n";
            $text .= "\tfind $source -type f | xargs \${CHMOD} a+r\n";
        }
        if ($overwrite) {
            # Copy everything recursively excluding CVS dirs and preserving permissions
            $text .= "\t\${RSYNC} -Cpr $source $target_dir\n";
        } elsif (-f $source) {
            # Don't over-write
            # (This assumes we're installing a _file_, not a directory tree)
            my $dest_file = catfile( $target_dir, basename( $source ) );
            $text .= "\tif [ -f $dest_file ]; ";
            $text .= "then \${CP} $source $dest_file.dist; ";
            $text .= "else \${CP} $source $dest_file; fi\n";
            $text .= "\t\${CHMOD} -R a+r $dest_file\n";
        } else {
            die "Can't install directory '$source' unless overwrite=1\n";
        }
    }
    $text .= "\n";
    return $text;
}

#
# This portion is to create directories and install anything in non-standard places
#
sub MY::postamble {
    my $self = shift;
    my $text = '';

    $text .= "RSYNC=rsync\n";
    $text .= "CHOWN=chown\n\n";

    # This establishes the base path under which everything should
    # be installed.  Normally this will just be '/', but the user installing
    # this can override it to be whatever they prefer.
    my $destdir = $args{DESTDIR} || rootdir();

    my $logdir = catdir( $destdir, 'var', 'log', $args{pkg_name} );
    $text .= install_clause('', $logdir, 0);

    my $ccache_dir = catdir( $destdir, 'var', 'spool', 'ccache' );
    $text .= install_clause('', $ccache_dir, 0);

    my $etcdir   = catdir( $destdir,  'etc', $args{pkg_name} );
    $text .= install_clause(catfile('config', 'plm.cfg'),  $etcdir, 0);

    return $text;
}

