#
# Author:: Sean Walbran (<seanwalbran@gmail.com>)
# Copyright:: Copyright (c) 2009-2016 Chef Software, Inc.
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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "Solaris virtualization platform" do
  let(:plugin) { get_plugin("solaris2/virtualization") }

  before(:each) do
    @psrinfo_pv = <<~PSRINFO_PV
      The physical processor has 1 virtual processor (0)
        x86 (GenuineIntel family 6 model 2 step 3 clock 2667 MHz)
              Intel Pentium(r) Pro
PSRINFO_PV

    allow(plugin).to receive(:collect_os).and_return(:solaris2)

    # default to all requested Files not existing
    allow(File).to receive(:exist?).with("/usr/sbin/psrinfo").and_return(false)
    allow(File).to receive(:exist?).with("/usr/sbin/smbios").and_return(false)
    allow(File).to receive(:exist?).with("/usr/sbin/zoneadm").and_return(false)
    allow(plugin).to receive(:shell_out).with("/usr/sbin/smbios").and_return(mock_shell_out(0, "", ""))
    allow(plugin).to receive(:shell_out).with("#{Ohai.abs_path( "/usr/sbin/psrinfo" )} -pv").and_return(mock_shell_out(0, "", ""))
  end

  describe "when we are checking for kvm" do
    before(:each) do
      expect(File).to receive(:exist?).with("/usr/sbin/psrinfo").and_return(true)
    end

    it "should run psrinfo -pv" do
      expect(plugin).to receive(:shell_out).with("#{Ohai.abs_path( "/usr/sbin/psrinfo" )} -pv")
      plugin.run
    end

    it "Should set kvm guest if psrinfo -pv contains QEMU Virtual CPU" do
      allow(plugin).to receive(:shell_out).with("#{Ohai.abs_path( "/usr/sbin/psrinfo" )} -pv").and_return(mock_shell_out(0, "QEMU Virtual CPU", ""))
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("kvm")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:kvm]).to eq("guest")
    end

    it "should not set virtualization if kvm isn't there" do
      expect(plugin).to receive(:shell_out).with("#{Ohai.abs_path( "/usr/sbin/psrinfo" )} -pv").and_return(mock_shell_out(0, @psrinfo_pv, ""))
      plugin.run
      expect(plugin[:virtualization][:systems]).to eq({})
    end
  end

  describe "when we are parsing smbios" do
    before(:each) do
      expect(File).to receive(:exist?).with("/usr/sbin/smbios").and_return(true)
    end

    it "should run smbios" do
      expect(plugin).to receive(:shell_out).with("/usr/sbin/smbios")
      plugin.run
    end

    it "should set vmware guest if smbios detects VMware Virtual Platform" do
      vmware_smbios = <<~VMWARE
        ID    SIZE TYPE
        1     72   SMB_TYPE_SYSTEM (system information)

          Manufacturer: VMware, Inc.
          Product: VMware Virtual Platform
          Version: None
          Serial Number: VMware-50 3f f7 14 42 d1 f1 da-3b 46 27 d0 29 b4 74 1d

          UUID: a86cc405-e1b9-447b-ad05-6f8db39d876a
          Wake-Up Event: 0x6 (power switch)
VMWARE
      allow(plugin).to receive(:shell_out).with("/usr/sbin/smbios").and_return(mock_shell_out(0, vmware_smbios, ""))
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("vmware")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:vmware]).to eq("guest")
    end

    it "should run smbios and not set virtualization if nothing is detected" do
      expect(plugin).to receive(:shell_out).with("/usr/sbin/smbios")
      plugin.run
      expect(plugin[:virtualization][:systems]).to eq({})
    end
  end

  describe "when we are parsing DMI data" do

    it "sets virtualization attributes if the appropriate DMI data is present" do
      plugin[:dmi] = { system: {
                                  manufacturer: "Amazon EC2",
                                  product: "c5n.large",
                                  version: nil,
                               },
                     }
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("amazonec2")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:amazonec2]).to eq("guest")
    end

    it "sets empty virtualization attributes if nothing is detected" do
      plugin[:dmi] = { system: {
                                  manufacturer: "Supermicro",
                                  product: "X10SLH-N6-ST031",
                                  version: "0123456789",
                               },
                     }
      plugin.run
      expect(plugin[:virtualization]).to eq({ "systems" => {} })
    end
  end

  it "should not set virtualization if no tests match" do
    plugin.run
    expect(plugin[:virtualization][:systems]).to eq({})
  end
end
