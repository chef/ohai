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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Ohai::System, 'plugin packages' do
  context "when the packages plugin is disabled" do
    before do
      Ohai.config[:plugin][:packages][:enabled] = false
      allow(plugin).to receive(:collect_os).and_return(platform_family.to_s)
      plugin.run
    end

    let(:plugin) do
      get_plugin('packages').tap do |plugin|
        plugin[:platform_family] = platform_family
      end
    end

    [:debian, :fedora, :windows, :aix, :solaris2].each do |os|
      context "on #{os}" do
        let(:platform_family) { os }

        it "does not enumerate the packages" do
          expect(plugin[:packages]).to eq(nil)
        end
      end
    end
  end

  context "when the packages plugin is enabled" do
    before do
      Ohai.config[:plugin][:packages][:enabled] = true
    end

    context 'on debian' do
      let(:plugin) do
        get_plugin('packages').tap do |plugin|
          plugin[:platform_family] = 'debian'
        end
      end

      let(:stdout) do
        File.read(File.join(SPEC_PLUGIN_PATH, 'dpkg-query.output'))
      end

      before(:each) do
        allow(plugin).to receive(:collect_os).and_return(:linux)
        allow(plugin).to receive(:shell_out)
          .with('dpkg-query -W')
          .and_return(mock_shell_out(0, stdout, ''))
        plugin.run
      end

      it 'calls dpkg query' do
        expect(plugin).to receive(:shell_out)
          .with('dpkg-query -W')
          .and_return(mock_shell_out(0, stdout, ''))
        plugin.run
      end

      it 'gets packages and versions' do
        expect(plugin[:packages]['vim-common'][:version]).to eq('2:7.4.052-1ubuntu3')
      end
    end

    context 'on fedora' do
      let(:plugin) do
        get_plugin('packages').tap do |plugin|
          plugin[:platform_family] = 'fedora'
        end
      end

      let(:format) { Shellwords.escape '%{NAME}\t%{VERSION}\t%{RELEASE}\n' }

      let(:stdout) do
        File.read(File.join(SPEC_PLUGIN_PATH, 'rpmquery.output'))
      end

      before(:each) do
        allow(plugin).to receive(:collect_os).and_return(:linux)
        allow(plugin).to receive(:shell_out).with("rpm -qa --queryformat #{format}").and_return(mock_shell_out(0, stdout, ''))
        plugin.run
      end

      it 'calls rpm -qa' do
        expect(plugin).to receive(:shell_out)
          .with("rpm -qa --queryformat #{format}")
          .and_return(mock_shell_out(0, stdout, ''))
        plugin.run
      end

      it 'gets packages and versions/release' do
        expect(plugin[:packages]['vim-common'][:version]).to eq('7.2.411')
        expect(plugin[:packages]['vim-common'][:release]).to eq('1.8.el6')
      end
    end

    context 'on windows', :windows_only do
      require 'wmi-lite'

      let(:plugin) do
        get_plugin('packages').tap do |plugin|
          plugin[:platform_family] = 'windows'
        end
      end

      let(:win32_product_output) do
        [{ 'assignmenttype' => 0,
           'caption' => 'NXLOG-CE',
           'description' => 'NXLOG-CE',
           'helplink' => nil,
           'helptelephone' => nil,
           'identifyingnumber' => '{22FA28AB-3C1B-438B-A8B5-E23892C8B567}',
           'installdate' => '20150511',
           'installdate2' => nil,
           'installlocation' => nil,
           'installsource' => 'C:\\chef\\cache\\',
           'installstate' => 5,
           'language' => '1033',
           'localpackage' => 'C:\\Windows\\Installer\\30884.msi',
           'name' => 'NXLOG-CE',
           'packagecache' => 'C:\\Windows\\Installer\\30884.msi',
           'packagecode' => '{EC3A13C4-4634-47FC-9662-DC293CB96F9F}',
           'packagename' => 'nexlog-ce-2.8.1248.msi',
           'productid' => nil,
           'regcompany' => nil,
           'regowner' => nil,
           'skunumber' => nil,
           'transforms' => nil,
           'urlinfoabout' => nil,
           'urlupdateinfo' => nil,
           'vendor' => 'nxsec.com',
           'version' => '2.8.1248',
           'wordcount' => 2 },
           { 'assignmenttype' => 1,
             'caption' => 'Chef Development Kit v0.7.0',
             'description' => 'Chef Development Kit v0.7.0',
             'helplink' => 'http://www.getchef.com/support/',
             'helptelephone' => nil,
             'identifyingnumber' => '{90754A33-404C-4172-8F3B-7F04CE98011C}',
             'installdate' => '20150925', 'installdate2' => nil,
             'installlocation' => nil,
             'installsource' => 'C:\\Users\\skhajamohid1\\Downloads\\',
             'installstate' => 5, 'language' => '1033',
             'localpackage' => 'C:\\WINDOWS\\Installer\\d9e1ca7.msi',
             'name' => 'Chef Development Kit v0.7.0',
             'packagecache' => 'C:\\WINDOWS\\Installer\\d9e1ca7.msi',
             'packagecode' => '{9B82FB86-40AE-4CDF-9DE8-97574F9395B9}',
             'packagename' => 'chefdk-0.7.0-1 (2).msi',
             'productid' => nil,
             'regcompany' => nil,
             'regowner' => nil,
             'skunumber' => nil,
             'transforms' => nil,
             'urlinfoabout' => nil,
             'urlupdateinfo' => nil,
             'vendor' => "\"Chef Software, Inc. <maintainers@chef.io>\"",
             'version' => '0.7.0.1',
             'wordcount' => 2 }]
      end

      before(:each) do
        allow(plugin).to receive(:collect_os).and_return(:windows)
        expect_any_instance_of(WmiLite::Wmi).to receive(:instances_of).with('Win32_Product').and_return(win32_product_output)
        plugin.run
      end

      it 'gets package info' do
        expect(plugin[:packages]['Chef Development Kit v0.7.0'][:version]).to eq('0.7.0.1')
        expect(plugin[:packages]['Chef Development Kit v0.7.0'][:vendor]).to eq("\"Chef Software, Inc. <maintainers@chef.io>\"")
        expect(plugin[:packages]['Chef Development Kit v0.7.0'][:installdate]).to eq('20150925')

        expect(plugin[:packages]['NXLOG-CE'][:version]).to eq('2.8.1248')
        expect(plugin[:packages]['NXLOG-CE'][:vendor]).to eq('nxsec.com')
        expect(plugin[:packages]['NXLOG-CE'][:installdate]).to eq('20150511')
      end
    end

    context 'on aix' do
      let(:plugin) { get_plugin('packages') }

      let(:stdout) do
        File.read(File.join(SPEC_PLUGIN_PATH, 'lslpp.output'))
      end

      before(:each) do
        allow(plugin).to receive(:collect_os).and_return(:aix)
        allow(plugin).to receive(:shell_out).with('lslpp -L -q -c').and_return(mock_shell_out(0, stdout, ''))
        plugin.run
      end

      it 'calls lslpp -L -q -c' do
        expect(plugin).to receive(:shell_out)
          .with('lslpp -L -q -c')
          .and_return(mock_shell_out(0, stdout, ''))
        plugin.run
      end

      it 'gets packages with version' do
        expect(plugin[:packages]['chef'][:version]).to eq('12.5.1.1')
      end
    end

    context 'on solaris2' do
      let(:plugin) { get_plugin('packages') }

      let(:pkglist_output) do
        File.read(File.join(SPEC_PLUGIN_PATH, 'pkglist.output'))
      end

      let(:pkginfo_output) do
        File.read(File.join(SPEC_PLUGIN_PATH, 'pkginfo.output'))
      end

      before(:each) do
        allow(plugin).to receive(:collect_os).and_return(:solaris2)
        allow(plugin).to receive(:shell_out).with('pkg list -H').and_return(mock_shell_out(0, pkglist_output, ''))
        allow(plugin).to receive(:shell_out).with('pkginfo -l').and_return(mock_shell_out(0, pkginfo_output, ''))
        plugin.run
      end

      it 'calls pkg list -H' do
        expect(plugin).to receive(:shell_out)
          .with('pkg list -H')
          .and_return(mock_shell_out(0, pkglist_output, ''))
        plugin.run
      end

      it 'calls pkginfo -l' do
        expect(plugin).to receive(:shell_out)
          .with('pkginfo -l')
          .and_return(mock_shell_out(0, pkginfo_output, ''))
        plugin.run
      end

      it 'gets ips packages with version' do
        expect(plugin[:packages]['chef'][:version]).to eq('12.5.1')
      end

      it 'gets ips packages with version and publisher' do
        expect(plugin[:packages]['system/EMCpower'][:version]).to eq('6.0.0.1.0-3')
        expect(plugin[:packages]['system/EMCpower'][:publisher]).to eq('emc.com')
      end

      it 'gets sysv packages with version' do
        expect(plugin[:packages]['chef'][:version]).to eq('12.5.1')
      end

      it 'gets sysv packages with version' do
        expect(plugin[:packages]['mqm'][:version]).to eq('7.0.1.4')
      end
    end
  end
end
