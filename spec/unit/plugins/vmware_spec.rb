#
# Author:: "Christopher M. Luciano" <cmlucian@us.ibm.com>
# Copyright (C) 2015 IBM Corp.
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
require 'spec_helper'

describe Ohai::System, "plugin vmware" do

  let(:plugin) { get_plugin("vmware") }
  let(:path) { "/usr/bin/vmware-toolbox-cmd" }

  context "vmware toolbox" do

    def setup_stubs
      allow(File).to receive(:exist?).and_return(true)
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:shell_out).with("#{path} stat speed").and_return(mock_shell_out(0, "2000 MHz", nil))
      allow(plugin).to receive(:shell_out).with("#{path} stat hosttime").and_return(mock_shell_out(0, "04 Jun 2015 19:21:16", nil))
      allow(plugin).to receive(:shell_out).with("#{path} stat sessionid").and_return(mock_shell_out(0, "0x0000000000000000", nil))
      allow(plugin).to receive(:shell_out).with("#{path} stat balloon").and_return(mock_shell_out(0, "0 MB", nil))
      allow(plugin).to receive(:shell_out).with("#{path} stat swap").and_return(mock_shell_out(0, "0 MB", nil))
      allow(plugin).to receive(:shell_out).with("#{path} stat memlimit").and_return(mock_shell_out(0, "4000000000 MB", nil))
      allow(plugin).to receive(:shell_out).with("#{path} stat memres").and_return(mock_shell_out(0, "0 MB", nil))
      allow(plugin).to receive(:shell_out).with("#{path} stat cpures").and_return(mock_shell_out(0, "0 MHz", nil))
      allow(plugin).to receive(:shell_out).with("#{path} stat cpulimit").and_return(mock_shell_out(0, "4000000000 MB", nil))
      allow(plugin).to receive(:shell_out).with("#{path} upgrade status").and_return(mock_shell_out(0, "VMware Tools are up-to-date.", nil))
      allow(plugin).to receive(:shell_out).with("#{path} timesync status").and_return(mock_shell_out(0, "Disabled", nil))
      plugin.run
    end

    before(:each) do
      setup_stubs
    end

    context "the vmware toolbox cmd" do

      it "gets the speed" do
        expect(plugin[:vmware][:speed]).to eq("2000 MHz")
      end

      it "gets the hosttime" do
        expect(plugin[:vmware][:hosttime]).to eq("04 Jun 2015 19:21:16")
      end

      it "gets tools update status" do
        expect(plugin[:vmware][:upgrade]).to eq("VMware Tools are up-to-date.")
      end
    end
  end
end
