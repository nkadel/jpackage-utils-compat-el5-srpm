# 
# Resolves RHEL dependencies on outdated jpackage-utils components.
#
Name:           jpackage-utils-compat-el5
Version:        0.0.2
Release:        0.2%{?dist}%{?repo}
Epoch:          0
Summary:        Compatibility For RHEL5 and JPackage
License:        GPLv2
URL:            http://rmyers.fedorapeople.org/jpackage-utils-compat-el5
Group:          Utilities
BuildRoot:      %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

BuildArch:      noarch
Requires:       /bin/bash

%description
Compatibility for JPackage Utils between RHEL5 and the JPackage Project.

%prep
# no setup

%build
# no building

%install
rm -rf $RPM_BUILD_ROOT

install -dm 755 ${RPM_BUILD_ROOT}%{_bindir}
install -dm 755 ${RPM_BUILD_ROOT}%{_sysconfdir}/java/security
install -dm 755 ${RPM_BUILD_ROOT}%{_sysconfdir}/java/security/security.d

pushd ${RPM_BUILD_ROOT}%{_bindir}

cat > rebuild-security-providers << EOF
#!/bin/bash
# Rebuild the list of security providers in classpath.security

secfiles="/usr/lib/security/classpath.security /usr/lib64/security/classpath.security"

for secfile in \$secfiles; do
  # check if this classpath.security file exists
  [ -f "\$secfile" ] || continue

  sed -i '/^security\.provider\./d' "\$secfile" 

  count=0
  for provider in \$(ls /etc/java/security/security.d)
  do
    count=\$((count + 1))
    echo "security.provider.\${count}=\${provider#*-}" >> "\$secfile"
  done
done
EOF

popd

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{_bindir}/rebuild-security-providers

%changelog
* Thu Feb  7 2013 Nico Kadel-Garcia <nkadel@gmail.com> - 0.2.2-0.2
- Publish at Github
- Specify GPLv2

* Thu Apr 08 2011 Nico Kadel-Garcia <nkadel@gmail.com>
- Flush /etc/security.d from this package

* Thu Sep 24 2009 Nico Kadel-Garcia <nkadel@gmail.com>
- Imported from http://article.gmane.org/gmane.linux.jpackage.general/13607

* Thu Jul  3 2008 Rob Myers <rob.myers at gtri.gatech.edu> - 0:0.0.1-1%{?dist}%{?repo}
- initial release
