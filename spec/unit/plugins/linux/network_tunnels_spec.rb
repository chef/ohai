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

# The linux-tunnels-* fixtures were recorded in a network namespace on Ubuntu
# 24.04 (iproute2 6.1) with gre1, gretap1, ipip1, sit1, ip6tnl1, ip6gre1, gnv1
# (geneve) and vx1 (vxlan) tunnels, plus the gre0, ipip (tunl0), sit0, ip6tnl0
# and ip6gre0 fallback devices the kernel creates. For layer 3 tunnels, ip
# prints the tunnel's local endpoint where an Ethernet interface has its MAC
# address:
#
#   link/gre 192.0.2.1 peer 192.0.2.2
#   link/tunnel6 2001:db8:8::1 peer 2001:db8:8::2 permaddr 9665:c4f0:bf7e::
describe Ohai::System, "Linux Network Plugin with tunnel interfaces" do
  def fixture(name)
    File.read(File.join(SPEC_PLUGIN_PATH, "linux-tunnels-#{name}.output"))
  end

  let(:plugin) { get_plugin("linux/network") }
  let(:interfaces) { plugin[:network][:interfaces] }

  def lladdrs(name)
    interfaces[name].fetch(:addresses, {}).select { |_, a| a[:family] == "lladdr" }.keys
  end

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

  it "does not record an IPv6 tunnel's endpoint as its MAC address" do
    %w{ip6tnl0 ip6tnl1 ip6gre0 ip6gre1}.each do |name|
      expect(lladdrs(name)).to be_empty, "#{name} has lladdr #{lladdrs(name)}"
    end
  end

  it "records only MAC addresses as lladdr" do
    interfaces.each_key do |name|
      expect(lladdrs(name)).to all(match(/\A\h\h(:\h\h)+\z/))
    end
  end

  it "sets the encapsulation of layer 3 tunnels" do
    expect(interfaces["gre1"][:encapsulation]).to eq("gre")
    expect(interfaces["ipip1"][:encapsulation]).to eq("ipip")
    expect(interfaces["sit1"][:encapsulation]).to eq("sit")
    expect(interfaces["ip6tnl1"][:encapsulation]).to eq("tunnel6")
    expect(interfaces["ip6gre1"][:encapsulation]).to eq("gre6")
  end

  it "keeps the MAC address of layer 2 tunnels" do
    expect(lladdrs("gretap1")).to eq(["CE:75:8D:8E:E9:0C"])
    expect(lladdrs("vx1")).to eq(["E6:10:D3:AB:B9:82"])
    expect(interfaces["gnv1"][:encapsulation]).to eq("Ethernet")
  end
end
