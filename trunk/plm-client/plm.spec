# $Id$

# This .spec file uses the Makefile.PL

%define plm_user plm
%define plm_group plm
%define plm_home /home/plm

%define pkgname         plm
%define release         0
# This spacing matches the script
%define version 1.3.15
%define perl_site_perl  /usr/lib/perl5/site_perl
%define namever         %{pkgname}-%{version}
%define filelist        %{namever}-filelist
%define maketest        1

Summary: 	Patch Lifecycle Manager
Name: 		%{pkgname}
Version: 	%{version}
Release: 	%{release}
Vendor:         Open Source Development Labs <plm-devel@lists.sourceforge.net>
Packager:       Open Source Development Labs <plm-devel@lists.sourceforge.net>
License: 	GPL
Group: 		Development/Tools
Source: 	%{pkgname}-%{version}.tar.bz2
Prefix: 	%{_prefix}
Url: 		http://developer.osdl.org/dev/plm
PreReq:         chkconfig
BuildRequires:  perl
BuildArch: 	noarch
BuildRoot: 	%{_tmppath}/%{pkgname}-buildroot/
Requires: 	perl >= 5.6.0
#Provides:	perl(AppConfig) perl(PLM::BASE::Log) perl(PLM::DB::Handle)



%description
Manages patches and keeps context information regarding them.
'Supervisor' client can be set up to run filters on source.

%prep


%setup -n %{namever}
chmod -R u+w %{_builddir}/%{namever}


# Add the plm user and group
%pre
finger %{plm_user}|grep "Login.*%{plm_user}" > /dev/null
if [ $? -ne 0 ]; then
    /usr/sbin/groupadd %{plm_user}; /usr/sbin/useradd -c 'PLM Owner' -d %{plm_home} -r %{plm_user} -g%{plm_user}
fi

%build
CFLAGS="$RPM_OPT_FLAGS"
export INSTALLSITELIB=$RPM_BUILD_ROOT%{perl_site_perl}
export INSTALLSITEMAN3DIR=$RPM_BUILD_ROOT%{local_mandir}/man3
export INSTALLSITEMAN1DIR=$RPM_BUILD_ROOT%{local_mandir}/man1
echo "DEBUG: CLEANING BUILD SPACE"
rm -f Makefile
echo "DEBUG: CREATING THE MAKEFILE"
%{__perl} Makefile.PL DESTDIR=%{buildroot} `%{__perl} -MExtUtils::MakeMaker -e ' print qq|PREFIX=%{buildroot}%{_prefix}/local| if \$ExtUtils::MakeMaker::VERSION =~ /5\.9[1-6]|6\.0[0-5]/ '` 
rm -f MANIFEST
make manifest

make OPTIMIZE="$RPM_OPT_FLAGS"

echo "DEBUG: RUNNING MAKE TEST"
%if %maketest
%{__make} test
%endif


%install
export  INSTALLSITELIB=$RPM_BUILD_ROOT%{perl_site_perl}
[ "%{buildroot}" != "/" ] && rm -rf $RPM_BUILD_ROOT
if [ -e /etc/SuSE-release ]; then
    RPM_BUILD_ROOT=%{buildroot}
export  INSTALLSITELIB=$RPM_BUILD_ROOT%{perl_site_perl}
fi

mkdir -p $RPM_BUILD_ROOT/usr
%{makeinstall} `%{__perl} -MExtUtils::MakeMaker -e ' print \$ExtUtils::MakeMaker::VERSION <= 6.05 ? qq|PREFIX=%{buildroot}%{_prefix}| : qq|DESTDIR=%{buildroot}| '`

# SuSE Linux
if [ -e /etc/SuSE-release ]; then
%{__mkdir_p} %{buildroot}/var/adm/perl-modules
%{__cat} `find %{buildroot} -name "perllocal.pod"`  \
| %{__sed} -e s+%{buildroot}++g                 \
> %{buildroot}/var/adm/perl-modules/%{name}
fi

# remove special files
find %{buildroot} -name "*.pod" -o -name ".packlist" -o -name "*.bs" |xargs -i rm -f {}

# no empty directories
find %{buildroot}%{_prefix} -type d -depth -exec rmdir {} \; 2>/dev/null

##Begin Perl script which generate the filelist
%{__perl} -MFile::Find -le '
find({ wanted => \&wanted, no_chdir => 1}, "%{buildroot}");
print "%defattr(-,root,root)";
# What is this?
#print "%doc  cgi-bin doc Changes INSTALL README";
print "%doc  Changelog  docs/INSTALL-HOWTO docs/README";
for my $x (sort @dirs, @files) {
    # These lines for SuSE, probably break RH
    if ( -e "/etc/SuSE-release" ){
        $y = $x;
        $y .= "\.gz" if $x =~ /(\.1|\.3pm)$/;
    }
    push @ret, $y unless indirs($x);
}
print join "\n", sort @ret;
exit;

sub wanted {
    return if /auto$/;
    local $_ = $File::Find::name;
    my $f = $_; s|^%{buildroot}||;
    return unless length;
    return $files[@files] = $_ if -f $f;
    $d = $_;
    /\Q$d\E/ && return for reverse sort @INC;
    $d =~ /\Q$_\E/ && return
    for qw|/etc %_prefix/man %_prefix/bin %_prefix/share|;
    $dirs[@dirs] = $_;
}

sub indirs {
    my $x = shift;
    $x =~ /^\Q$_\E\// && $x ne $_ && return 1 for @dirs;
}

' > %filelist
##End Perl Script

echo "####"
echo '%attr'"(-,%plm_user,%plm_group) /var/log/%{pkgname}" >> %filelist
echo "####"
cat %filelist
echo "####"
[ -z %filelist ] && {
echo "ERROR: empty %files listing"
exit -1
}
# What is this?
grep -rsl '^#!.*perl'  Changelog docs/INSTALL-HOWTO docs/README |
grep -v '.bak$' | xargs --no-run-if-empty \
%{__perl} -MExtUtils::MakeMaker -e 'MY->fixin(@ARGV)'

%clean 
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

%files -f %filelist

%changelog
* Mon Feb 01 2005  <judith@osdl.org>
- Reworked modelled after STP .spec file.

