#
# Author:: Sean Walbran (<seanwalbran@gmail.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Ohai::System, "Solaris virtualization platform" do
  let(:plugin) { get_plugin("solaris2/virtualization") }

  before do
    @psrinfo_pv = <<~PSRINFO_PV
      The physical processor has 1 virtual processor (0)
        x86 (GenuineIntel family 6 model 2 step 3 clock 2667 MHz)
              Intel Pentium(r) Pro
    PSRINFO_PV

    allow(plugin).to receive(:collect_os).and_return(:solaris2)
    # the plugin checks zoneadm with File.executable?, not file_exist?
    allow(File).to receive(:executable?).and_call_original
    allow(File).to receive(:executable?).with("/usr/sbin/zoneadm").and_return(false)

    # default to all requested Files not existing
    allow(plugin).to receive(:file_exist?).with("/usr/sbin/psrinfo").and_return(false)
    allow(plugin).to receive(:file_exist?).with("/usr/sbin/smbios").and_return(false)
    allow(plugin).to receive(:file_exist?).with("/usr/sbin/zoneadm").and_return(false)
    allow(plugin).to receive(:shell_out).with("/usr/sbin/smbios").and_return(mock_shell_out(0, "", ""))
    allow(plugin).to receive(:shell_out).with("#{Ohai.abs_path( "/usr/sbin/psrinfo" )} -pv").and_return(mock_shell_out(0, "", ""))
  end

  describe "when we are checking for kvm" do
    before do
      expect(plugin).to receive(:file_exist?).with("/usr/sbin/psrinfo").and_return(true)
    end

    it "runs psrinfo -pv" do
      expect(plugin).to receive(:shell_out).with("#{Ohai.abs_path( "/usr/sbin/psrinfo" )} -pv")
      plugin.run
    end

    it "sets kvm guest if psrinfo -pv contains QEMU Virtual CPU" do
      allow(plugin).to receive(:shell_out).with("#{Ohai.abs_path( "/usr/sbin/psrinfo" )} -pv").and_return(mock_shell_out(0, "QEMU Virtual CPU", ""))
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("kvm")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:kvm]).to eq("guest")
    end

    it "does not set virtualization if kvm isn't there" do
      expect(plugin).to receive(:shell_out).with("#{Ohai.abs_path( "/usr/sbin/psrinfo" )} -pv").and_return(mock_shell_out(0, @psrinfo_pv, ""))
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

  it "does not set virtualization if no tests match" do
    plugin.run
    expect(plugin[:virtualization][:systems]).to eq({})
  end

  # Oracle Solaris 11.4 on an OCI VM.Standard.E5.Flex: psrinfo shows the
  # host's CPU model rather than a QEMU/KVM CPU name, so only DMI shows KVM
  describe "on a KVM guest that passes the host CPU model through" do
    let(:psrinfo_pv) do
      [
        "The physical processor has 2 virtual processors (0-1)",
        "  x86 (AuthenticAMD A10F11 family 25 model 17 step 1 clock 2600 MHz)",
        "\tAMD EPYC 9J14 96-Core Processor",
      ].join("\n") + "\n"
    end

    before do
      allow(plugin).to receive(:file_exist?).with("/usr/sbin/psrinfo").and_return(true)
      allow(plugin).to receive(:shell_out).with("#{Ohai.abs_path( "/usr/sbin/psrinfo" )} -pv").and_return(mock_shell_out(0, psrinfo_pv, ""))
      allow(File).to receive(:executable?).and_call_original
      allow(File).to receive(:executable?).with("/usr/sbin/zoneadm").and_return(true)
      allow(plugin).to receive(:shell_out).with("zoneadm list -pc").and_return(mock_shell_out(0, "0:global:running:/::solaris:shared:-:none::\n", ""))
      plugin[:dmi] = { system: { manufacturer: "QEMU", product: "Standard PC (Q35 + ICH9, 2009)", version: "pc-q35-7.2" } }
      plugin.run
    end

    it "detects the KVM guest from DMI" do
      expect(plugin[:virtualization][:systems][:kvm]).to eq("guest")
    end

    it "reports the global zone as a zone host" do
      expect(plugin[:virtualization][:systems][:zone]).to eq("host")
      expect(plugin[:virtualization]).not_to have_key(:guests)
    end
  end
end
