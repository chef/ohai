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

# The linux-vrf-table-* fixtures were recorded in a network namespace on
# Ubuntu 24.04 (iproute2 6.1): veth v0 is enslaved to VRF "blue" (table 10),
# which holds the default routes. A routing table other than main also holds
# the kernel's local, broadcast and multicast routes, which ip prints with the
# route type before the destination.
describe Ohai::System, "Linux Network Plugin with default_route_table set to a VRF's table" do
  def fixture(name)
    File.read(File.join(SPEC_PLUGIN_PATH, "linux-vrf-table-#{name}.output"))
  end

  let(:ohai) { Ohai::System.new }
  let(:plugin) { get_plugin("linux/network", ohai) }
  let(:network_plugin) { get_plugin("network", ohai) }
  let(:routes) { plugin[:network][:interfaces]["v0"][:routes] }

  before do
    Ohai.config[:plugin][:network][:default_route_table] = "10"
    allow(plugin).to receive(:collect_os).and_return(:linux)
    allow(plugin).to receive(:which).with("ip").and_return("/sbin/ip")
    allow(plugin).to receive(:which).with("ethtool").and_return(nil)
    allow(plugin).to receive(:file_exist?).with("/proc/net/if_inet6").and_return(true)
    allow(plugin).to receive(:file_directory?).and_return(false)
    allow(plugin).to receive(:shell_out).with("ip addr").and_return(mock_shell_out(0, fixture("ip_addr"), ""))
    allow(plugin).to receive(:shell_out).with("ip -d -s link").and_return(mock_shell_out(0, fixture("ip_d_s_link"), ""))
    allow(plugin).to receive(:shell_out).with("ip -f inet neigh show").and_return(mock_shell_out(0, fixture("ip_neigh4"), ""))
    allow(plugin).to receive(:shell_out).with("ip -f inet6 neigh show").and_return(mock_shell_out(0, fixture("ip_neigh6"), ""))
    allow(plugin).to receive(:shell_out).with("ip -o -f inet route show table 10").and_return(mock_shell_out(0, fixture("ip_route4_table10"), ""))
    allow(plugin).to receive(:shell_out).with("ip -o -f inet6 route show table 10").and_return(mock_shell_out(0, fixture("ip_route6_table10"), ""))
  end

  it "collects the interfaces" do
    plugin.run
    expect(plugin[:network][:interfaces].keys).to include("lo", "blue", "v0")
  end

  it "uses the table's default routes" do
    plugin.run
    expect(plugin[:network][:default_interface]).to eq("v0")
    expect(plugin[:network][:default_gateway]).to eq("198.51.100.1")
    expect(plugin[:network][:default_inet6_interface]).to eq("v0")
    expect(plugin[:network][:default_inet6_gateway]).to eq("2001:db8:1::1")
  end

  it "does not record local, broadcast or multicast routes as destinations" do
    plugin.run
    expect(routes.map { |r| r[:destination] }).to contain_exactly("default", "198.51.100.0/24", "2001:db8:1::/64", "fe80::/64", "default")
  end

  it "sets ipaddress and ip6address from the default interface" do
    plugin.run
    network_plugin.run
    expect(ohai.data[:ipaddress]).to eq("198.51.100.2")
    expect(ohai.data[:ip6address]).to eq("2001:db8:1::2")
  end
end
