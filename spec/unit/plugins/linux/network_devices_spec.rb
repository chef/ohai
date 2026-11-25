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

# The fixtures used here were captured verbatim from running network operating
# systems booted under QEMU:
#
# cumulus-5.9.2-leaf-*: Cumulus VX 5.9.2 configured as an EVPN leaf. eth0 in the
#   mgmt VRF, BGP unnumbered on swp1/swp2 to a Cumulus VX 5.10.0 spine that
#   originates a default route, an LACP bond (swp3) and a VXLAN device in a
#   VLAN-aware bridge, SVIs in VRF RED with a VRR address, and a stacked VLAN
#   (swp1.100.200). FRR installs routes through kernel nexthop objects, so
#   routes reference "nhid N" instead of carrying "via ... dev ...".
#
# vyos-rolling-router-*: VyOS rolling 2026.11.25 configured with an 802.3ad
#   bond (eth1) with a VLAN and a QinQ (vif-s 200 / vif-c 300) subinterface, a
#   VRF, dummy interfaces and a bridge with a VXLAN member.
describe Ohai::System, "Linux Network Plugin on network devices" do
  def fixture(name)
    File.read(File.join(SPEC_PLUGIN_PATH, "#{name}.output"))
  end

  let(:ohai) { Ohai::System.new }
  let(:plugin) { get_plugin("linux/network", ohai) }
  let(:network_plugin) { get_plugin("network", ohai) }
  let(:interfaces) { plugin[:network][:interfaces] }

  def stub_device(prefix, nexthop: nil)
    allow(plugin).to receive(:collect_os).and_return(:linux)
    allow(plugin).to receive(:which).with("ip").and_return("/sbin/ip")
    allow(plugin).to receive(:which).with("ethtool").and_return(nil)
    allow(plugin).to receive(:file_exist?).with("/proc/net/if_inet6").and_return(true)
    allow(plugin).to receive(:file_directory?).and_return(false)
    allow(plugin).to receive(:shell_out).with("ip addr").and_return(mock_shell_out(0, fixture("#{prefix}-ip_addr"), ""))
    allow(plugin).to receive(:shell_out).with("ip -d -s link").and_return(mock_shell_out(0, fixture("#{prefix}-ip_d_s_link"), ""))
    allow(plugin).to receive(:shell_out).with("ip -f inet neigh show").and_return(mock_shell_out(0, fixture("#{prefix}-ip_neigh4"), ""))
    allow(plugin).to receive(:shell_out).with("ip -f inet6 neigh show").and_return(mock_shell_out(0, fixture("#{prefix}-ip_neigh6"), ""))
    allow(plugin).to receive(:shell_out).with("ip -o -f inet route show table main").and_return(mock_shell_out(0, fixture("#{prefix}-ip_route4_main"), ""))
    allow(plugin).to receive(:shell_out).with("ip -o -f inet6 route show table main").and_return(mock_shell_out(0, fixture("#{prefix}-ip_route6_main"), ""))
    allow(plugin).to receive(:shell_out).with("ip -o nexthop show").and_return(mock_shell_out(0, nexthop ? fixture(nexthop) : "", ""))
  end

  describe "on a Cumulus Linux 5.9 leaf" do
    before do
      stub_device("cumulus-5.9.2-leaf", nexthop: "cumulus-5.9.2-leaf-ip_nexthop")
      plugin.run
    end

    it "reports the link state of a bond member, not its bond_slave state" do
      expect(interfaces["swp3"]["state"]).to eq("up")
    end

    it "reports the link state of a bridge port, not its bridge_slave state" do
      expect(interfaces["bond1"]["state"]).to eq("up")
      expect(interfaces["vxlan48"]["state"]).to eq("unknown")
    end

    it "names a VLAN stacked on a VLAN subinterface without its parent" do
      expect(interfaces.keys).to include("swp1.100.200")
      expect(interfaces.keys.grep(/@/)).to be_empty
      expect(interfaces["swp1.100.200"]["vlan"]["id"]).to eq("200")
    end

    it "keeps the kernel routes of a stacked VLAN" do
      expect(interfaces["swp1.100.200"]["routes"]).to include(include("destination" => "fe80::/64", "family" => "inet6"))
    end

    it "resolves the default route through its nexthop group" do
      expect(plugin[:network][:default_interface]).to eq("swp1")
      expect(plugin[:network][:default_gateway]).to eq("fe80::5054:ff:fe60:1")
      expect(plugin[:network][:default_inet6_interface]).to eq("swp1")
      expect(plugin[:network][:default_inet6_gateway]).to eq("fe80::5054:ff:fe60:1")
    end

    it "records an ECMP default route on every member of the nexthop group" do
      %w{swp1 swp2}.each do |port|
        expect(interfaces[port]["routes"]).to include(include("destination" => "default", "family" => "inet", "proto" => "bgp", "metric" => "20"))
      end
      expect(interfaces["swp2"]["routes"]).to include(include("destination" => "default", "family" => "inet", "via" => "fe80::5054:ff:fe60:2"))
    end

    it "sets ipaddress when the default route leaves through a port without an IPv4 address" do
      network_plugin.run
      expect(ohai.data[:ipaddress]).to eq("10.10.10.1")
    end
  end

  describe "#extract_neighbors" do
    it "names the interface when a neighbor is on an interface it does not know" do
      allow(plugin).to receive(:shell_out).with("ip -f inet neigh show").and_return(mock_shell_out(0, fixture("cumulus-5.9.2-leaf-ip_neigh4"), ""))
      iface = Mash.new("eth0" => Mash.new, "swp1" => Mash.new)
      expect(plugin.logger).to receive(:warn).with("Plugin Network: neighbor list has entries for unknown interface swp2")
      plugin.extract_neighbors({ name: "inet" }, iface, :arp)
      expect(iface["swp1"]["arp"]).to eq("169.254.0.1" => "52:54:00:60:00:01")
    end
  end

  describe "on a Linux system without nexthop objects" do
    it "does not run ip nexthop when no route references one" do
      stub_device("vyos-rolling-router")
      plugin.run
      expect(plugin).not_to have_received(:shell_out).with("ip -o nexthop show")
    end
  end

  describe "on a VyOS router" do
    before do
      stub_device("vyos-rolling-router")
      plugin.run
    end

    it "reports the link state of a bond member, not its bond_slave state" do
      expect(interfaces["eth1"]["state"]).to eq("up")
    end

    it "reports the link state of a bridge port, not its bridge_slave state" do
      expect(interfaces["vxlan10"]["state"]).to eq("unknown")
    end

    it "names a QinQ subinterface without its parent" do
      expect(interfaces.keys).to include("bond0.200.300")
      expect(interfaces.keys.grep(/@/)).to be_empty
      expect(interfaces["bond0.200.300"]["vlan"]).to eq({ "id" => "300", "protocol" => "802.1Q", "flags" => ["REORDER_HDR"] })
      expect(interfaces["bond0.200.300"]["number"]).to eq("0.200.300")
    end

    it "keeps the kernel routes of a QinQ subinterface" do
      expect(interfaces["bond0.200.300"]["routes"]).to include(include("destination" => "192.0.2.128/25", "src" => "192.0.2.129"))
    end

    it "resolves the default route" do
      expect(plugin[:network][:default_interface]).to eq("eth0")
      expect(plugin[:network][:default_gateway]).to eq("10.0.2.2")
    end
  end
end
