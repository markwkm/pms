# $Id$

# This .spec file is for a LSB-compliant package.  Please send LSB related
# bugs regarding this spec file in.  This file really needs to be correct.

# Feel free to write a RedHat specific spec file if you would prefer that install
# method.

%define name plm
%define real_name plm 
%define version 1.3.12 
%define perl_site_perl /usr/lib/perl5/site_perl
%define local_mandir /usr/local/man
%define release 0
%define web_group www
%define web_user www
%define web_home /var/www
%define plm_user plm
%define plm_group plm
%define plm_home /home/plm

Summary: 	Patch Lifecycle Manager
Name: 		%{name}
Version: 	%{version}
Release: 	%{release}
License: 	GPL
Group: 		Development/Tools
Source: 	%{real_name}-%{version}.tar.bz2
Prefix: 	%{_prefix}
Url: 		http://www.osdl.org/plm
# BuildRequires:	none
BuildArch: 	noarch
BuildRoot: 	%{_tmppath}/%{real_name}-buildroot/
Requires: 	perl >= 5.8.0
#Provides:	perl(AppConfig) perl(PLM::BASE::Log) perl(PLM::DB::Handle)


%description
Manages Patches and keeps context information regarding them.

%prep
%setup -n %{real_name}-%{version}

# Add the plm user and group
%pre
finger %{plm_user}|grep "Login.*%{plm_user}" > /dev/null
if [ $? -ne 0 ]; then
    /usr/sbin/groupadd %{plm_user}; /usr/sbin/useradd -c 'PLM Owner' -d %{plm_home} -r %{plm_user} -g%{plm_user}
fi

#%post
# This was for moving the log to plm ownership.
#if [ -f /var/log/plm.log ]; then mv /var/log/plm.log /var/log/plm/plm.log ; fi
#ln -s /var/log/plm/plm.log /var/log/plm.log

%build
rm -f Makefile
%{__perl} Makefile.PL INSTALLSITELIB=$RPM_BUILD_ROOT%{perl_site_perl} INSTALLSITEMAN3DIR=$RPM_BUILD_ROOT%{local_mandir}/man3
rm -f MANIFEST
make manifest
make OPTIMIZE="$RPM_OPT_FLAGS" INSTALLSITELIB=$RPM_BUILD_ROOT%{perl_site_perl} INSTALLSITEMAN3DIR=$RPM_BUILD_ROOT%{local_mandir}/man3
make test

%install
rm -rf $RPM_BUILD_ROOT
%__mkdir_p $RPM_BUILD_ROOT%{perl_site_perl}
%makeinstall INSTALLSITELIB=$RPM_BUILD_ROOT%{perl_site_perl} INSTALLSITEMAN3DIR=$RPM_BUILD_ROOT%{local_mandir}/man3
%__mkdir_p $RPM_BUILD_ROOT%{prefix}/local/bin
%__mkdir_p $RPM_BUILD_ROOT%{web_home}/plm/asp-private
%__mkdir_p $RPM_BUILD_ROOT%{web_home}/plm/cgi-bin
%__mkdir_p $RPM_BUILD_ROOT%{web_home}/plm/template
%__mkdir_p $RPM_BUILD_ROOT%{web_home}/plm/html/images
%__mkdir_p $RPM_BUILD_ROOT/etc
%__mkdir_p $RPM_BUILD_ROOT/etc/plm
%__mkdir_p $RPM_BUILD_ROOT/var/spool/ccache
%__mkdir_p $RPM_BUILD_ROOT/var/log/plm
%__mkdir_p $RPM_BUILD_ROOT%{plm_home}
%__cp -a scripts/admin/* $RPM_BUILD_ROOT%{prefix}/local/bin
%__cp scripts/client/*.pl $RPM_BUILD_ROOT%{prefix}/local/bin
%__cp scripts/client/plmsend $RPM_BUILD_ROOT%{prefix}/local/bin
%__cp scripts/client/server-dead.sh $RPM_BUILD_ROOT%{plm_home}
%__cp scripts/email-gateway/egate.pl $RPM_BUILD_ROOT%{prefix}/local/bin/egate.pl
%__cp contrib/eidetic-sync.pl $RPM_BUILD_ROOT%{prefix}/local/bin/eidetic-sync.pl
%__cp -a scripts/tests docs
# This script has apache security
mv scripts/RPC/plm_private_server.pl $RPM_BUILD_ROOT%{web_home}/plm/asp-private
# The rest have looser permissions
%__cp scripts/RPC/* $RPM_BUILD_ROOT%{web_home}/plm/cgi-bin
%__cp branding/*html $RPM_BUILD_ROOT%{web_home}/plm/template
%__cp website/docs/PLM-HOWTO.html $RPM_BUILD_ROOT%{web_home}/plm/html/PLM-HOWTO.html
%__cp -a website/docs/images/* $RPM_BUILD_ROOT%{web_home}/plm/html/images
%__cp config/plm.cfg $RPM_BUILD_ROOT/etc
%__cp config/plm_get_header.cfg $RPM_BUILD_ROOT/etc/plm
#%__cp -a blib/lib/* $RPM_BUILD_ROOT/%{perl_site_perl}/
#%__cp -a /usr/lib/perl5/site_perl/PLM/* $RPM_BUILD_ROOT/%{perl_site_perl}/

%clean 
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc COPYING docs/FAQ docs/ISSUES docs/*.dia docs/*HOWTO* docs/README*
%doc config/*.gpg 
%attr(0440,%{plm_user},%{plm_user}) %config /etc/*
%attr(0440,%{plm_user},%{plm_user}) %config /etc/plm/*
%{prefix}/local/bin/*
%attr(0775,%{plm_user},%{plm_group}) %{plm_home}/server-dead.sh
%attr(0775,%{web_user},%{web_group}) %{web_home}/plm/asp-private/plm_private_server.pl
%attr(0775,%{web_user},%{web_group}) %{web_home}/plm/cgi-bin/*
%attr(0775,%{web_user},%{web_group}) %{web_home}/plm/template/*
%attr(0775,%{web_user},%{web_group}) %{web_home}/plm/html/PLM-HOWTO.html
%attr(0775,%{web_user},%{web_group}) %{web_home}/plm/html/images/*
%attr(0775,%{plm_user},%{plm_group}) /var/log/plm
%attr(0775,-,%{plm_group}) /var/spool/ccache
%{perl_site_perl}
%{local_mandir}/*/*

