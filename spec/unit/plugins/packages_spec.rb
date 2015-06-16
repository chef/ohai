# Author:: Christopher M. Luciano (<cmlucian@us.ibm.com>)
# Copyright::
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

describe Ohai::System, "plugin packages" do

  context "on debian" do

    let (:plugin) do
      get_plugin("packages").tap do |plugin|
        plugin[:platform_family] = 'debian'
      end
    end

    let(:stdout) do
      File.read(File.join(SPEC_PLUGIN_PATH, 'dpkg-query.output'))
    end

    before(:each) do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:shell_out)
        .with("dpkg-query -W")
        .and_return(mock_shell_out(0, stdout, ""))
      plugin.run
    end

    it "calls dpkg query" do
      expect(plugin).to receive(:shell_out)
        .with("dpkg-query -W")
        .and_return(mock_shell_out(0, stdout, ""))
      plugin.run
    end

    it "gets the packages and versions" do
      expect(plugin[:packages]['vim-common'][:version]).to eq("2:7.4.052-1ubuntu3")
    end
  end

  context "on fedora" do

    let (:plugin) do
      get_plugin("packages").tap do |plugin|
        plugin[:platform_family] = 'fedora'
      end
    end

    let(:format) { Shellwords.escape '%{NAME}\t%{VERSION}\t%{RELEASE}\n' }

    let(:stdout) do
      File.read(File.join(SPEC_PLUGIN_PATH, 'rpmquery.output'))
    end

    before(:each) do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:shell_out).with("rpm -qa --queryformat #{format}").and_return(mock_shell_out(0, stdout, ""))
      plugin.run
    end

    it "calls rpm -qa" do
      expect(plugin).to receive(:shell_out)
        .with("rpm -qa --queryformat #{format}")
        .and_return(mock_shell_out(0, stdout, ""))
      plugin.run
    end

    it "gets the packages and versions/release" do
      expect(plugin[:packages]['vim-common'][:version]).to eq("7.2.411")
      expect(plugin[:packages]['vim-common'][:release]).to eq("1.8.el6")
    end
  end

  context "on windows" do

    require 'wmi-lite'

    let (:plugin) do
      get_plugin("packages").tap do |plugin|
        plugin[:platform_family] = 'windows'
      end
    end

   let(:w32_product) do
     File.read(File.join(SPEC_PLUGIN_PATH, 'wmiproduct.output'))
    end

    before(:each) do
      allow(plugin).to receive(:collect_os).and_return(:windows)
      plugin.run
    end

    it "gets the packages and versions/release" do
      expect(plugin[:packages]['chefdk-0.6.2-1.msi'][:version]).to eq("0.6.2.1")
    end

  end

end
