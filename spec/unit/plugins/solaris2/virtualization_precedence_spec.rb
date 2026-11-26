# frozen_string_literal: true
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright (c) 2026 Tim Smith
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

# The Solaris plugin checks psrinfo, then DMI, then zones; each detection
# overwrites system and role, so the last match wins.
describe Ohai::System, "Solaris virtualization detection order" do
  let(:plugin) { get_plugin("solaris2/virtualization") }
  let(:psrinfo) { "#{Ohai.abs_path("/usr/sbin/psrinfo")} -pv" }

  # zoneadm list -p prints zoneid:zonename:state:zonepath:uuid:brand:ip-type:
  # r/w:file-mac-profile (zoneadm(8)); these lines are built from that format.
  # A non-global zone lists only itself, with a zonepath of /.
  let(:non_global_zone) { "3:web01:running:/:2f8b6a9c-3d1e-4c7a-9f2b-5e6d7c8a9b0c:solaris:excl:-:none:\n" }
  let(:global_and_two_zones) do
    <<~ZONES
      0:global:running:/::solaris:shared:-:none:
      3:web01:running:/zones/web01:2f8b6a9c-3d1e-4c7a-9f2b-5e6d7c8a9b0c:solaris:excl:-:none:
      -:db01:installed:/zones/db01:8d0e4f2a-6b7c-4e1d-a3f5-9c8b7a6d5e4f:solaris:excl:-:none:
    ZONES
  end

  # psrinfo -pv on a KVM guest, built from the format of psrinfo(8)'s
  # verbose physical processor listing
  def psrinfo_pv(cpu_name)
    "The physical processor has 1 virtual processor (0)\n  x86 (GenuineIntel 306A9 family 6 model 58 step 9 clock 2400 MHz)\n        #{cpu_name}\n"
  end

  def zoneadm(output)
    allow(File).to receive(:executable?).with("/usr/sbin/zoneadm").and_return(true)
    allow(plugin).to receive(:shell_out).with("zoneadm list -pc").and_return(mock_shell_out(0, output, ""))
  end

  before do
    allow(plugin).to receive(:collect_os).and_return(:solaris2)
    allow(plugin).to receive(:file_exist?).and_return(false)
    allow(File).to receive(:executable?).and_call_original
    allow(File).to receive(:executable?).with("/usr/sbin/zoneadm").and_return(false)
  end

  ["Common KVM processor", "Common 32-bit KVM processor"].each do |cpu_name|
    it "reports a kvm guest when psrinfo names a #{cpu_name}" do
      allow(plugin).to receive(:file_exist?).with(Ohai.abs_path("/usr/sbin/psrinfo")).and_return(true)
      allow(plugin).to receive(:shell_out).with(psrinfo).and_return(mock_shell_out(0, psrinfo_pv(cpu_name), ""))
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("kvm")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems]).to eq("kvm" => "guest")
    end
  end

  it "reports a zone guest with its uuid and id inside a non-global zone" do
    zoneadm(non_global_zone)
    allow(plugin).to receive(:shell_out).with("/usr/sbin/zoneadm list -p").and_return(mock_shell_out(0, non_global_zone, ""))
    plugin.run
    expect(plugin[:virtualization][:system]).to eq("zone")
    expect(plugin[:virtualization][:role]).to eq("guest")
    expect(plugin[:virtualization][:systems]).to eq("zone" => "guest")
    expect(plugin[:virtualization][:guest_uuid]).to eq("2f8b6a9c-3d1e-4c7a-9f2b-5e6d7c8a9b0c")
    expect(plugin[:virtualization][:guest_id]).to eq("3")
    expect(plugin[:virtualization]).not_to have_key(:guests)
  end

  it "reports a zone host with every zone in guests in the global zone" do
    zoneadm(global_and_two_zones)
    plugin.run
    expect(plugin[:virtualization][:system]).to eq("zone")
    expect(plugin[:virtualization][:role]).to eq("host")
    expect(plugin[:virtualization][:systems]).to eq("zone" => "host")
    expect(plugin[:virtualization][:guests]).to eq(
      "global" => { "id" => "0", "state" => "running", "root" => "/", "uuid" => "", "brand" => "solaris", "ip" => "shared" },
      "web01" => { "id" => "3", "state" => "running", "root" => "/zones/web01", "uuid" => "2f8b6a9c-3d1e-4c7a-9f2b-5e6d7c8a9b0c", "brand" => "solaris", "ip" => "excl" },
      "db01" => { "id" => "-", "state" => "installed", "root" => "/zones/db01", "uuid" => "8d0e4f2a-6b7c-4e1d-a3f5-9c8b7a6d5e4f", "brand" => "solaris", "ip" => "excl" }
    )
  end

  # today's behavior; see #2018
  it "reports a KVM guest's lone global zone as a zone host" do
    plugin[:dmi] = { system: { manufacturer: "QEMU", product: "Standard PC (Q35 + ICH9, 2009)", version: "pc-q35-7.2" } }
    zoneadm("0:global:running:/::solaris:shared:-:none:\n")
    plugin.run
    expect(plugin[:virtualization][:system]).to eq("zone")
    expect(plugin[:virtualization][:role]).to eq("host")
    expect(plugin[:virtualization][:systems]).to eq("kvm" => "guest", "zone" => "host")
  end
end
