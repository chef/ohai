# Author:: Christopher M. Luciano (<cmlucian@us.ibm.com>)
# Author:: Shahul Khajamohideen (<skhajamohid1@bloomberg.net>)
# Copyright (C) 2015 IBM Corp.
# Copyright (C) 2015 Bloomberg Finance L.P.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"

describe Ohai::System, "plugin packages" do
  context "when on debian" do
    let(:plugin) do
      get_plugin("packages").tap do |plugin|
        plugin[:platform_family] = "debian"
      end
    end

    let(:format) { '${Package}\t${Version}\t${Architecture}\t${db:Status-Status}\n' }

    let(:stdout) do
      File.read(File.join(SPEC_PLUGIN_PATH, "dpkg-query.output"))
    end

    before do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:shell_out)
        .with("dpkg-query -W -f='#{format}'")
        .and_return(mock_shell_out(0, stdout, ""))
      plugin.run
    end

    it "calls dpkg query" do
      expect(plugin).to receive(:shell_out)
        .with("dpkg-query -W -f='#{format}'")
        .and_return(mock_shell_out(0, stdout, ""))
      plugin.run
    end

    it "gets packages and versions - arch" do
      expect(plugin[:packages]["libc6"][:version]).to eq("2.19-18+deb8u3")
      expect(plugin[:packages]["libc6"][:arch]).to eq("amd64")
      expect(plugin[:packages]["libc6"][:status]).to eq("installed")
    end

    it "gets packages and versions - noarch" do
      expect(plugin[:packages]["tzdata"][:version]).to eq("2015g-0+deb8u1")
      expect(plugin[:packages]["tzdata"][:arch]).to eq("all")
      expect(plugin[:packages]["tzdata"][:status]).to eq("installed")
    end

    it "gets packages and versions - removed" do
      expect(plugin[:packages]["systemd-timesyncd"][:version]).to eq("247.3-6")
      expect(plugin[:packages]["systemd-timesyncd"][:arch]).to eq("amd64")
      expect(plugin[:packages]["systemd-timesyncd"][:status]).to eq("config-files")
    end
  end

  context "when on fedora" do
    let(:plugin) do
      get_plugin("packages").tap do |plugin|
        plugin[:platform_family] = "fedora"
      end
    end

    let(:format) { '%{NAME}\t%|EPOCH?{%{EPOCH}}:{0}|\t%{VERSION}\t%{RELEASE}\t%{INSTALLTIME}\t%{ARCH}\n' }

    let(:stdout) do
      File.read(File.join(SPEC_PLUGIN_PATH, "rpmquery.output"))
    end

    before do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:shell_out).with("rpm -qa --qf '#{format}'").and_return(mock_shell_out(0, stdout, ""))
      plugin.run
    end

    it "calls rpm -qa" do
      expect(plugin).to receive(:shell_out)
        .with("rpm -qa --qf '#{format}'")
        .and_return(mock_shell_out(0, stdout, ""))
      plugin.run
    end

    it "gets packages and versions/release - arch" do
      expect(plugin[:packages]["glibc"][:version]).to eq("2.17")
      expect(plugin[:packages]["glibc"][:release]).to eq("106.el7_2.6")
      expect(plugin[:packages]["glibc"][:epoch]).to eq("0")
      expect(plugin[:packages]["glibc"][:installdate]).to eq("1463486666")
      expect(plugin[:packages]["glibc"][:arch]).to eq("x86_64")
    end

    it "gets packages and versions/release - noarch" do
      expect(plugin[:packages]["tzdata"][:version]).to eq("2016d")
      expect(plugin[:packages]["tzdata"][:release]).to eq("1.el7")
      expect(plugin[:packages]["tzdata"][:epoch]).to eq("0")
      expect(plugin[:packages]["tzdata"][:installdate]).to eq("1463486618")
      expect(plugin[:packages]["tzdata"][:arch]).to eq("noarch")
    end

    it "handles multiple packages with the same name" do
      expect(plugin[:packages]["kernel"][:version]).to eq("3.10.0")
      expect(plugin[:packages]["kernel"][:release]).to eq("862.el7")
      expect(plugin[:packages]["kernel"][:epoch]).to eq("0")
      expect(plugin[:packages]["kernel"][:installdate]).to eq("1521745632")
      expect(plugin[:packages]["kernel"][:arch]).to eq("x86_64")
      # and now the version list:
      expect(plugin[:packages]["kernel"]["versions"].first[:version]).to eq("3.10.0")
      expect(plugin[:packages]["kernel"]["versions"].first[:release]).to eq("862.2.3.el7")
      expect(plugin[:packages]["kernel"]["versions"].first[:epoch]).to eq("0")
      expect(plugin[:packages]["kernel"]["versions"].first[:installdate]).to eq("1526310781")
      expect(plugin[:packages]["kernel"]["versions"].first[:arch]).to eq("x86_64")
      expect(plugin[:packages]["kernel"]["versions"].last[:version]).to eq("3.10.0")
      expect(plugin[:packages]["kernel"]["versions"].last[:release]).to eq("862.el7")
      expect(plugin[:packages]["kernel"]["versions"].last[:epoch]).to eq("0")
      expect(plugin[:packages]["kernel"]["versions"].last[:installdate]).to eq("1521745632")
      expect(plugin[:packages]["kernel"]["versions"].last[:arch]).to eq("x86_64")

    end
  end

  context "when on arch" do
    let(:plugin) do
      get_plugin("packages").tap do |plugin|
        plugin[:platform_family] = "arch"
      end
    end

    let(:stdout) do
      File.read(File.join(SPEC_PLUGIN_PATH, "pacman.output"))
    end

    before do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:shell_out).with("LANG=C pacman -Qi").and_return(mock_shell_out(0, stdout, ""))
      plugin.run
    end

    it "calls LANG=C pacman -Qi" do
      expect(plugin).to receive(:shell_out)
        .with("LANG=C pacman -Qi")
        .and_return(mock_shell_out(0, stdout, ""))
      plugin.run
    end

    it "gets packages and versions/release - normal case" do
      expect(plugin[:packages]["acl"][:version]).to eq("2.2.52-3")
      expect(plugin[:packages]["acl"][:installdate]).to eq("1500780345")
      expect(plugin[:packages]["acl"][:arch]).to eq("x86_64")
    end

    it "gets packages and versions/release - multiline optdeps" do
      expect(plugin[:packages]["abcde"][:version]).to eq("2.8.1-2")
      expect(plugin[:packages]["abcde"][:installdate]).to eq("1493998583")
      expect(plugin[:packages]["abcde"][:arch]).to eq("any")
    end
  end

  context "when on windows", :windows_only do

    let(:plugin) do
      get_plugin("packages").tap do |plugin|
        plugin[:platform_family] = "windows"
      end
    end

    let(:win_reg_double) do
      instance_double("Win32::Registry")
    end

    let(:win_reg_keys) do
      [ "{22FA28AB-3C1B-438B-A8B5-E23892C8B567}",
        "{0D4BCDCD-6225-4BA5-91A3-54AFCECC281E}" ]
    end

    let(:i386_reg_type) do
      Win32::Registry::KEY_READ | 0x100
    end

    let(:x86_64_reg_type) do
      Win32::Registry::KEY_READ | 0x200
    end

    let(:win_reg_output) do
      [{ "DisplayName" => "NXLOG-CE",
         "DisplayVersion" => "2.8.1248",
         "Publisher" => "nxsec.com",
         "InstallDate" => "20150511",
        },
       { "DisplayName" => "Chef Development Kit v0.7.0",
         "DisplayVersion" => "0.7.0.1",
         "Publisher" => "\"Chef Software, Inc. <maintainers@chef.io>\"",
         "InstallDate" => "20150925" }]
    end

    shared_examples "windows_package_plugin" do
      it "gets package info" do
        plugin.run
        expect(plugin[:packages]["Chef Development Kit v0.7.0"][:version]).to eq("0.7.0.1")
        expect(plugin[:packages]["Chef Development Kit v0.7.0"][:publisher]).to eq("\"Chef Software, Inc. <maintainers@chef.io>\"")
        expect(plugin[:packages]["Chef Development Kit v0.7.0"][:installdate]).to eq("20150925")

        expect(plugin[:packages]["NXLOG-CE"][:version]).to eq("2.8.1248")
        expect(plugin[:packages]["NXLOG-CE"][:publisher]).to eq("nxsec.com")
        expect(plugin[:packages]["NXLOG-CE"][:installdate]).to eq("20150511")
      end
    end

    before do
      allow(plugin).to receive(:collect_os).and_return(:windows)
      allow(win_reg_double).to receive(:open).with(win_reg_keys[0]).and_return(win_reg_output[0])
      allow(win_reg_double).to receive(:open).with(win_reg_keys[1]).and_return(win_reg_output[1])
      allow(win_reg_double).to receive(:each_key).and_yield(win_reg_keys[0], 0).and_yield(win_reg_keys[1], 1)
    end

    describe "on 32 bit ruby" do
      before do
        stub_const("::RbConfig::CONFIG", { "target_cpu" => "i386" } )
        allow(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).with('Software\Microsoft\Windows\CurrentVersion\Uninstall', i386_reg_type).and_yield(win_reg_double)
        allow(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).with('Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall', i386_reg_type).and_yield(win_reg_double)
      end

      it_behaves_like "windows_package_plugin"
    end

    describe "on 64 bit ruby" do
      before do
        stub_const("::RbConfig::CONFIG", { "target_cpu" => "x86_64" } )
        allow(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).with('Software\Microsoft\Windows\CurrentVersion\Uninstall', x86_64_reg_type).and_yield(win_reg_double)
        allow(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).with('Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall', x86_64_reg_type).and_yield(win_reg_double)
      end

      it_behaves_like "windows_package_plugin"
    end

    describe "on unknown ruby" do
      before do
        stub_const("::RbConfig::CONFIG", { "target_cpu" => nil } )
        allow(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).with('Software\Microsoft\Windows\CurrentVersion\Uninstall', Win32::Registry::KEY_READ).and_yield(win_reg_double)
        allow(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).with('Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall', Win32::Registry::KEY_READ).and_yield(win_reg_double)
      end

      it_behaves_like "windows_package_plugin"
    end
  end

  context "when on aix" do
    let(:plugin) { get_plugin("packages") }

    let(:stdout) do
      File.read(File.join(SPEC_PLUGIN_PATH, "lslpp.output"))
    end

    before do
      allow(plugin).to receive(:collect_os).and_return(:aix)
      allow(plugin).to receive(:shell_out).with("lslpp -L -q -c").and_return(mock_shell_out(0, stdout, ""))
      plugin.run
    end

    it "calls lslpp -L -q -c" do
      expect(plugin).to receive(:shell_out)
        .with("lslpp -L -q -c")
        .and_return(mock_shell_out(0, stdout, ""))
      plugin.run
    end

    it "gets packages with version" do
      expect(plugin[:packages]["chef"][:version]).to eq("12.5.1.1")
    end

    it "properly parses package names for RPMs" do
      expect(plugin[:packages]["wget"][:version]).to eq("1.9.1-3")
    end
  end

  context "when on freebsd" do
    let(:plugin) { get_plugin("packages") }

    let(:stdout) do
      File.read(File.join(SPEC_PLUGIN_PATH, "pkg-query.output"))
    end

    before do
      allow(plugin).to receive(:collect_os).and_return(:freebsd)
      allow(plugin).to receive(:shell_out).with('pkg query -a "%n %v"').and_return(mock_shell_out(0, stdout, ""))
      plugin.run
    end

    it 'calls pkg query -a "%n %v"' do
      expect(plugin).to receive(:shell_out)
        .with('pkg query -a "%n %v"')
        .and_return(mock_shell_out(0, stdout, ""))
      plugin.run
    end

    it "gets packages with version" do
      expect(plugin[:packages]["rubygem-chef"][:version]).to eq("12.6.0_1")
    end
  end

  context "when on solaris2" do
    let(:plugin) { get_plugin("packages") }

    let(:pkglist_output) do
      File.read(File.join(SPEC_PLUGIN_PATH, "pkglist.output"))
    end

    let(:pkginfo_output) do
      File.read(File.join(SPEC_PLUGIN_PATH, "pkginfo.output"))
    end

    before do
      allow(plugin).to receive(:collect_os).and_return(:solaris2)
      allow(plugin).to receive(:shell_out).with("pkg list -H").and_return(mock_shell_out(0, pkglist_output, ""))
      allow(plugin).to receive(:shell_out).with("pkginfo -l").and_return(mock_shell_out(0, pkginfo_output, ""))
      plugin.run
    end

    it "calls pkg list -H" do
      expect(plugin).to receive(:shell_out)
        .with("pkg list -H")
        .and_return(mock_shell_out(0, pkglist_output, ""))
      plugin.run
    end

    it "calls pkginfo -l" do
      expect(plugin).to receive(:shell_out)
        .with("pkginfo -l")
        .and_return(mock_shell_out(0, pkginfo_output, ""))
      plugin.run
    end

    it "gets ips packages with version" do
      expect(plugin[:packages]["chef"][:version]).to eq("12.5.1")
    end

    it "gets ips packages with version and publisher" do
      expect(plugin[:packages]["system/EMCpower"][:version]).to eq("6.0.0.1.0-3")
      expect(plugin[:packages]["system/EMCpower"][:publisher]).to eq("emc.com")
    end

    it "gets sysv packages with version" do
      expect(plugin[:packages]["chef"][:version]).to eq("12.5.1")
    end

    it "gets sysv packages with version" do
      expect(plugin[:packages]["mqm"][:version]).to eq("7.0.1.4")
    end
  end

  context "when on darwin" do
    let(:plugin) { get_plugin("packages") }

    let(:stdout) do
      File.read(File.join(SPEC_PLUGIN_PATH, "system_profiler_spapplicationsdatatype.output"))
    end

    before do
      allow(plugin).to receive(:collect_os).and_return(:darwin)
      allow(plugin).to receive(:shell_out).with("system_profiler SPApplicationsDataType -xml").and_return(mock_shell_out(0, stdout, ""))
      plugin.run
    end

    it "calls system_profiler SPApplicationsDataType -xml" do
      expect(plugin).to receive(:shell_out)
        .with("system_profiler SPApplicationsDataType -xml")
        .and_return(mock_shell_out(0, stdout, ""))
      plugin.run
    end

    # apple
    it "gets 'Install macOS Catalina' details" do
      expect(plugin[:packages]["Install macOS Catalina"][:version]).to eq("15.6.00")
      expect(plugin[:packages]["Install macOS Catalina"][:source]).to eq("apple")
      expect(plugin[:packages]["Install macOS Catalina"][:lastmodified].to_s).to eq("2020-09-04T04:54:33+00:00")
    end

    # app store
    it "gets 'Slack' details" do
      expect(plugin[:packages]["Slack"][:version]).to eq("4.8.0")
      expect(plugin[:packages]["Slack"][:source]).to eq("mac_app_store")
      expect(plugin[:packages]["Slack"][:lastmodified].to_s).to eq("2020-08-12T22:24:32+00:00")
    end

    # chef
    it "gets 'Chef Workstation' details" do
      expect(plugin[:packages]["Chef Workstation App"][:version]).to eq("0.1.82")
      expect(plugin[:packages]["Chef Workstation App"][:source]).to eq("identified_developer")
      expect(plugin[:packages]["Chef Workstation App"][:lastmodified].to_s).to eq("2020-09-03T03:16:22+00:00")
    end

    # homebrew
    it "gets 'Emacs' details" do
      expect(plugin[:packages]["Emacs"][:version]).to eq("27.1")
      expect(plugin[:packages]["Emacs"][:source]).to eq("unknown")
      expect(plugin[:packages]["Emacs"][:lastmodified].to_s).to eq("2020-08-19T07:08:51+00:00")
    end
  end
end
