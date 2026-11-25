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

# The linux-alias-source-* fixtures were recorded in a network namespace on
# Ubuntu 24.04 (iproute2 6.1). v0 has 198.51.100.2/24 and, labeled v0:1,
# 203.0.113.5/24. The default route leaves from the labeled address:
#
#   default via 203.0.113.1 dev v0 src 203.0.113.5
#   203.0.113.0/24 dev v0 proto kernel scope link src 203.0.113.5
#
# Ohai records a labeled address on a separate "v0:1" interface, while the
# routes name v0.
describe Ohai::System, "Linux Network Plugin with routes from a labeled address" do
  def fixture(name)
    File.read(File.join(SPEC_PLUGIN_PATH, "linux-alias-source-#{name}.output"))
  end

  let(:ohai) { Ohai::System.new }
  let(:plugin) { get_plugin("linux/network", ohai) }
  let(:network_plugin) { get_plugin("network", ohai) }
  let(:routes) { plugin[:network][:interfaces]["v0"][:routes] }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    allow(plugin).to receive(:which).with("ip").and_return("/sbin/ip")
    allow(plugin).to receive(:which).with("ethtool").and_return(nil)
    allow(plugin).to receive(:file_exist?).with("/proc/net/if_inet6").and_return(true)
    allow(plugin).to receive(:file_directory?).and_return(false)
    allow(plugin).to receive(:shell_out).with("ip addr").and_return(mock_shell_out(0, fixture("ip_addr"), ""))
    allow(plugin).to receive(:shell_out).with("ip -d -s link").and_return(mock_shell_out(0, fixture("ip_d_s_link"), ""))
    allow(plugin).to receive(:shell_out).with("ip -f inet neigh show").and_return(mock_shell_out(0, fixture("ip_neigh4"), ""))
    allow(plugin).to receive(:shell_out).with("ip -f inet6 neigh show").and_return(mock_shell_out(0, fixture("ip_neigh6"), ""))
    allow(plugin).to receive(:shell_out).with("ip -o -f inet route show table main").and_return(mock_shell_out(0, fixture("ip_route4_main"), ""))
    allow(plugin).to receive(:shell_out).with("ip -o -f inet6 route show table main").and_return(mock_shell_out(0, fixture("ip_route6_main"), ""))
    plugin.run
  end

  it "keeps the labeled address on the alias" do
    expect(plugin[:network][:interfaces]["v0:1"][:addresses].keys).to eq(["203.0.113.5"])
  end

  it "keeps routes whose source is the labeled address" do
    expect(routes).to include(include("destination" => "default", "via" => "203.0.113.1", "src" => "203.0.113.5"))
    expect(routes).to include(include("destination" => "203.0.113.0/24", "src" => "203.0.113.5"))
  end

  it "reports the default route" do
    expect(plugin[:network][:default_interface]).to eq("v0")
    expect(plugin[:network][:default_gateway]).to eq("203.0.113.1")
  end

  it "sets ipaddress to the default route's source address" do
    network_plugin.run
    expect(ohai.data[:ipaddress]).to eq("203.0.113.5")
    expect(ohai.data[:macaddress]).to eq(plugin[:network][:interfaces]["v0"][:addresses].find { |_, a| a[:family] == "lladdr" }.first)
  end
end

# The linux-loopback-source-* fixtures reproduce issue #792 in a network
# namespace on Ubuntu 24.04 (iproute2 6.1): the default route's source is a /32
# on the loopback (labeled lo:0), not an address of the route's interface v0,
# which also has an aliased address (v0:0).
#
#   default via 198.51.100.58 dev v0 src 203.0.113.64
describe Ohai::System, "Linux Network Plugin with a default route from a loopback address" do
  def fixture(name)
    File.read(File.join(SPEC_PLUGIN_PATH, "linux-loopback-source-#{name}.output"))
  end

  let(:ohai) { Ohai::System.new }
  let(:plugin) { get_plugin("linux/network", ohai) }
  let(:network_plugin) { get_plugin("network", ohai) }
  let(:routes) { plugin[:network][:interfaces]["v0"][:routes] }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    allow(plugin).to receive(:which).with("ip").and_return("/sbin/ip")
    allow(plugin).to receive(:which).with("ethtool").and_return(nil)
    allow(plugin).to receive(:file_exist?).with("/proc/net/if_inet6").and_return(true)
    allow(plugin).to receive(:file_directory?).and_return(false)
    allow(plugin).to receive(:shell_out).with("ip addr").and_return(mock_shell_out(0, fixture("ip_addr"), ""))
    allow(plugin).to receive(:shell_out).with("ip -d -s link").and_return(mock_shell_out(0, fixture("ip_d_s_link"), ""))
    allow(plugin).to receive(:shell_out).with("ip -f inet neigh show").and_return(mock_shell_out(0, fixture("ip_neigh4"), ""))
    allow(plugin).to receive(:shell_out).with("ip -f inet6 neigh show").and_return(mock_shell_out(0, fixture("ip_neigh6"), ""))
    allow(plugin).to receive(:shell_out).with("ip -o -f inet route show table main").and_return(mock_shell_out(0, fixture("ip_route4_main"), ""))
    allow(plugin).to receive(:shell_out).with("ip -o -f inet6 route show table main").and_return(mock_shell_out(0, fixture("ip_route6_main"), ""))
    plugin.run
  end

  it "keeps the default route" do
    expect(routes).to include(include("destination" => "default", "via" => "198.51.100.58", "src" => "203.0.113.64"))
  end

  it "reports the default route" do
    expect(plugin[:network][:default_interface]).to eq("v0")
    expect(plugin[:network][:default_gateway]).to eq("198.51.100.58")
  end

  it "keeps the routes of the interface's aliased address" do
    expect(routes).to include(include("destination" => "10.100.77.130/31", "src" => "10.100.77.131"))
  end

  it "sets ipaddress to the default route's source address" do
    network_plugin.run
    expect(ohai.data[:ipaddress]).to eq("203.0.113.64")
    expect(ohai.data[:macaddress]).to eq(plugin[:network][:interfaces]["v0"][:addresses].find { |_, a| a[:family] == "lladdr" }.first)
  end
end
