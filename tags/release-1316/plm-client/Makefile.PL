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
            web_user        => 'www', # 'apache',
            web_group       => 'www', # 'apache',
            httpd_dir       => '/etc/httpd/conf',
            html_dir        => '/var/www/plm/html',
            img_dir         => '/var/www/plm/html/images',
            cgi_dir         => '/var/www/plm/cgi-bin',
            private_cgi_dir => '/var/www/plm/asp-private',
            branding_dir    => '/var/www/plm/template',
            DESTDIR         => undef
            );

# Set DESTDIR in the command line in the .spec file for the 'build' location
# perl Makefile.PL DESTDIR=%{buildroot}
# The spec later moves it to the install location
# On gentoo, this will be the final location.

my @pass_args;
while (my $arg = shift @ARGV) {
    my ($key, $value) = split /=/, $arg;
    if (exists $args{$key}) {
        $args{$key} = $value;
    } else {
        push @pass_args, $arg;
    }
}
@ARGV = @pass_args;

die "This requires MakeMaker version > 5.45.  You have '$ExtUtils::MakeMaker::VERSION'.\n"
    unless ($ExtUtils::MakeMaker::VERSION > 5.45);

my %opts = (
            'INSTALLDIRS'   => 'site',
            'NAME'          => $args{name},
            'VERSION_FROM'  => 'lib/PLM/Util.pm',
            'AUTHOR'        => 'Open Source Development Lab',
            'EXE_FILES'     => [ qw(
                                     scripts/admin/asp_supervisor.pl
                                     scripts/admin/plm_add_software.pl
                                     scripts/admin/plm_get_header.pl
                                     scripts/admin/plm_reset_request.pl
                                     scripts/admin/plm_user
                                     scripts/admin/plm_add_filter.pl
                                     scripts/admin/plm_filter_check.pl
                                     scripts/admin/plm_report.pl
                                     scripts/admin/plm_source_sync.pl
                                     scripts/admin/plm_add_filter_type.pl
                                     scripts/admin/plm_filter_output.pl
                                     scripts/admin/plm_request_filter.pl
                                     scripts/admin/plm_status.pl
                                     scripts/client/plm_build_tree.pl
                                     scripts/client/plm_build_app.pl
                                     scripts/client/plmsend
                                     scripts/client/server-dead.sh
                                     scripts/email-gateway/egate.pl
                                     scripts/RPC/plm_report.pl
                                     scripts/RPC/plm_report_results.pl
                                     scripts/tests/call_rpc.pl
                                     contrib/eidetic-sync.pl
                                     ) ],
            'PREREQ_FATAL' => 0,
            'PREREQ_PM' => {
                'SOAP::Lite' => 0,
                'DBI' => 0,
                'DBD::mysql' => 0,
                'Carp'           => 0,
                'File::Spec'     => 0.82,
                'DBI'            => 1.21,
                'Config::Simple' => 0,
                'File::Temp'     => 0.12,
                'CGI'            => 2.81,
                'Compress::Zlib' => 1.33,
                'MailTools'      => 1.58,
                'SOAP::Lite'     => 0.55,
                'SOAP::MIME'     => 0.55,
                'XML::Simple'    => 2.12,
            },
            );


# This puts us in the site_perl directory, not dependant on any version
# of perl.
if (defined($Config{'sitelib_stem'}) && $Config{'sitelib_stem'} ne "") {
    print "stem is: $Config{'sitelib_stem'}\n";
    $opts{'INSTALLSITELIB'} = "";
    $opts{'INSTALLSITELIB'} = $args{'DESTDIR'}
                if (($] >= 5.008 && $] < 5.008005) ||
                    $ExtUtils::MakeMaker::VERSION =~ /5\.9[1-6]|6\.0[0-5]/);
    #if ($] >= 5.008 ||
    #    $ExtUtils::MakeMaker::VERSION =~ /5\.9[1-6]|6\.0[0-5]/);
        $opts{'INSTALLSITELIB'} .= $Config{'sitelib_stem'};
}

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
    $text .= install_clause(catfile('config', 'plm_get_header.cfg'),  $etcdir, 0);

    # Install cgi-bin files
    my $cgi_dir = catdir( $destdir, $args{cgi_dir} );
    $text .= install_clause(catfile('scripts', 'RPC', 'getpatch'),  $cgi_dir, 1);
    $text .= install_clause(catfile('scripts', 'RPC', 'plm'),  $cgi_dir, 1);
    $text .= install_clause(catfile('scripts', 'RPC', 'plm_server.pl'),  $cgi_dir, 1);
    $text .= install_clause(catfile('scripts', 'RPC', 'plm_report.pl'),  $cgi_dir, 1);
    $text .= install_clause(catfile('scripts', 'RPC', 'plm_report_results.pl'),  $cgi_dir, 1);

    my $private_cgi_dir = catdir( $destdir, $args{private_cgi_dir} );
    $text .= install_clause(catfile('scripts', 'RPC', 'plm_private_server.pl'),  $private_cgi_dir, 1);

    # Install Web header and footer
    my $html_dir = catdir( $destdir, $args{html_dir} );
    $text .= install_clause(catfile('docs', 'PLM-HOWTO.html'), $html_dir);

    # Install Web header and footer
    my $branding_dir = catdir( $destdir, $args{branding_dir} );
    $text .= install_clause(catfile('branding', 'default_header.html'), $branding_dir);
    $text .= install_clause(catfile('branding', 'default_footer.html'), $branding_dir);
    $text .= install_clause(catfile('branding', 'home.html'), $branding_dir);

    return $text;
}

