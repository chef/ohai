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

# The linux-ipv6-states-* fixtures were recorded in a network namespace on
# Ubuntu 24.04 (iproute2 6.1). v0 has four global IPv6 addresses in one /64:
#
#   2001:db8:6::5   dadfailed tentative  (the peer on the link already uses it)
#   2001:db8:6::10
#   2001:db8:6::11  deprecated           (preferred_lft 0)
#   2001:db8:6::12  home
#
# and the IPv6 default route is via fe80::1 on v0.
describe Ohai::System, "Network Plugin with IPv6 addresses in different states" do
  def fixture(name)
    File.read(File.join(SPEC_PLUGIN_PATH, "linux-ipv6-states-#{name}.output"))
  end

  let(:ohai) { Ohai::System.new }
  let(:linux_plugin) { get_plugin("linux/network", ohai) }
  let(:plugin) { get_plugin("network", ohai) }

  before do
    allow(linux_plugin).to receive(:collect_os).and_return(:linux)
    allow(linux_plugin).to receive(:which).with("ip").and_return("/sbin/ip")
    allow(linux_plugin).to receive(:which).with("ethtool").and_return(nil)
    allow(linux_plugin).to receive(:file_exist?).with("/proc/net/if_inet6").and_return(true)
    allow(linux_plugin).to receive(:file_directory?).and_return(false)
    allow(linux_plugin).to receive(:shell_out).with("ip addr").and_return(mock_shell_out(0, fixture("ip_addr"), ""))
    allow(linux_plugin).to receive(:shell_out).with("ip -d -s link").and_return(mock_shell_out(0, fixture("ip_d_s_link"), ""))
    allow(linux_plugin).to receive(:shell_out).with("ip -f inet neigh show").and_return(mock_shell_out(0, fixture("ip_neigh4"), ""))
    allow(linux_plugin).to receive(:shell_out).with("ip -f inet6 neigh show").and_return(mock_shell_out(0, fixture("ip_neigh6"), ""))
    allow(linux_plugin).to receive(:shell_out).with("ip -o -f inet route show table main").and_return(mock_shell_out(0, fixture("ip_route4_main"), ""))
    allow(linux_plugin).to receive(:shell_out).with("ip -o -f inet6 route show table main").and_return(mock_shell_out(0, fixture("ip_route6_main"), ""))
    linux_plugin.run
  end

  it "does not pick an address that failed duplicate address detection" do
    plugin.run
    expect(plugin[:ip6address]).not_to eq("2001:db8:6::5")
  end

  it "prefers a preferred address over a deprecated one" do
    plugin.run
    expect(plugin[:ip6address]).to eq("2001:db8:6::10")
  end

  it "still reports the unusable addresses on the interface" do
    plugin.run
    tags = plugin[:network][:interfaces]["v0"][:addresses].transform_values { |a| a[:tags] }
    expect(tags).to include("2001:db8:6::5" => %w{dadfailed tentative}, "2001:db8:6::11" => %w{nodad deprecated})
  end
end
