#
# Author:: Pavel Yudin (<pyudin@parallels.com>)
# Copyright:: Copyright (c) 2015 Pavel Yudin
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Ohai::System, "Windows virtualization platform" do
  let(:plugin) { get_plugin("windows/virtualization")}

  before(:each) do
    allow(plugin).to receive(:collect_os).and_return(:windows)
    allow(plugin).to receive(:powershell_exists?).and_return(false)
  end

  describe "when we are checking for parallels" do
    it "should set parallels guest if powershell exists and it's output contains 'Parallels Software International Inc.'" do
      allow(plugin).to receive(:powershell_exists?).and_return(true)
      bios=<<-BIOS
SMBIOSBIOSVersion : 10.2.0 (28956) rev 0
Manufacturer      : Parallels Software International Inc.
Name              : Default System BIOS
SerialNumber      : Parallels-92 05 B4 56 97 11 4F FA B1 95 1A FF 8E F9 DD CE
Version           : PRLS   - 1
      BIOS
      shellout = double("shellout")
      allow(shellout).to receive(:stdout).and_return(bios)
      allow(plugin).to receive(:shell_out).with('powershell.exe "Get-WmiObject -Class Win32_BIOS"').and_return(shellout)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("parallels")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:parallels]).to eq("guest")
    end

    it "should not set parallels guest if powershell exists and it's output not contain 'Parallels Software International Inc.'" do
      allow(plugin).to receive(:ioreg_exists?).and_return(true)
      bios=<<-BIOS
SMBIOSBIOSVersion : 4.6.5
Manufacturer      : American Megatrends Inc.
Name              : BIOS Date: 10/23/12 15:38:23 Ver: 04.06.05
SerialNumber      : 334281-001
Version           : Dealin - 1072009
      BIOS
      shellout = double("shellout")
      allow(shellout).to receive(:stdout).and_return(bios)
      allow(plugin).to receive(:shell_out).with('powershell.exe "Get-WmiObject -Class Win32_BIOS"').and_return(shellout)
      plugin.run
      expect(plugin[:virtualization]).to eq({'systems' => {}})
    end
  end
end
