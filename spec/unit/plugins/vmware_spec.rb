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

require_relative "../../spec_helper.rb"

describe Ohai::System, "plugin vmware" do
  let(:plugin) { get_plugin("vmware") }
  let(:path) { "/usr/bin/vmware-toolbox-cmd" }

  before(:each) do
    allow(plugin).to receive(:collect_os).and_return(:linux)
  end

  context "on vmware guest with toolbox installed" do
    before(:each) do
      allow(File).to receive(:exist?).with("/usr/bin/vmware-toolbox-cmd").and_return(true)
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
      plugin[:virtualization] = Mash.new
      plugin[:virtualization][:systems] = Mash.new
      plugin[:virtualization][:systems][:vmware] = Mash.new
      plugin.run
    end

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

  context "on vmware guest without toolbox" do
    it "should not create a vmware attribute" do
      plugin[:virtualization] = Mash.new
      plugin[:virtualization][:systems] = Mash.new
      plugin[:virtualization][:systems][:vmware] = Mash.new
      allow(File).to receive(:exist?).with("/usr/bin/vmware-toolbox-cmd").and_return(false)
      expect(plugin).not_to have_key(:vmware)
    end
  end

  context "on vbox guest" do
    it "should not create a vmware attribute" do
      plugin[:virtualization] = Mash.new
      plugin[:virtualization][:systems] = Mash.new
      plugin[:virtualization][:systems][:vbox] = Mash.new
      expect(plugin).not_to have_key(:vmware)
    end
  end
end
