#
# spec file for package yast2-power-management
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-power-management
Version:        3.1.0
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:	        System/YaST
License:        GPL-2.0
BuildRequires:	update-desktop-files yast2-testsuite perl-XML-Writer yast2
BuildRequires:  yast2-devtools >= 3.0.6
Requires:	gettext
BuildArchitectures: noarch

# .etc.policykit agent
Requires:	yast2 >= 2.14.7

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:	YaST2 - Power Management Configuration

%description
This package contains the YaST2 component for Power management
configuration.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install


%files
%defattr(-,root,root)
%dir %{yast_yncludedir}/power-management
%{yast_yncludedir}/power-management/*
%{yast_clientdir}/power-management.rb
%{yast_clientdir}/power-management_*.rb
%{yast_moduledir}/PowerManagement.*
%{yast_desktopdir}/power-management.desktop
%{yast_scrconfdir}/*
%{yast_schemadir}/autoyast/rnc/power-management.rnc
%doc %{yast_docdir}
