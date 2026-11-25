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

# The linux-interface-names-* fixtures were recorded in a network namespace on
# Ubuntu 24.04 (iproute2 6.1) with dummy interfaces named a+b, x#y,
# br-1a2b3c4d5e6f, fifteen-chars-x, eth0+1, tilde~1, comma,1, excl!1 and end+,
# each with a /32, the label a+b:1 on a second address of a+b, and a route on
# end+. Linux accepts any interface name without "/", ":" or whitespace.
describe Ohai::System, "Linux Network Plugin with unusual interface names" do
  def fixture(name)
    File.read(File.join(SPEC_PLUGIN_PATH, "linux-interface-names-#{name}.output"))
  end

  let(:plugin) { get_plugin("linux/network") }
  let(:interfaces) { plugin[:network][:interfaces] }
  let(:names) { %w{a+b x#y br-1a2b3c4d5e6f fifteen-chars-x eth0+1 tilde~1 comma,1 excl!1 end+} }
  let(:ethtool) { nil }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    allow(plugin).to receive(:which).with("ip").and_return("/sbin/ip")
    allow(plugin).to receive(:which).with("ethtool").and_return(ethtool)
    allow(plugin).to receive(:shell_out).with(array_including("/sbin/ethtool")).and_return(mock_shell_out(0, "", ""))
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

  it "collects every interface" do
    expect(interfaces.keys).to include(*names)
  end

  it "keeps each interface's address on that interface" do
    names.each_with_index do |name, i|
      inet = interfaces[name][:addresses].select { |_, a| a[:family] == "inet" }.keys
      expect(inet).to eq(["192.0.2.#{i + 1}"]), "#{name} has #{inet}"
    end
  end

  it "does not give the loopback other interfaces' addresses" do
    expect(interfaces["lo"][:addresses].keys).to contain_exactly("127.0.0.1", "::1")
    expect(interfaces["lo"][:encapsulation]).to eq("Loopback")
  end

  it "puts a labeled address on the label" do
    expect(interfaces["a+b:1"][:addresses].keys).to eq(["198.51.100.7"])
  end

  it "collects link state and counters for every interface" do
    names.each do |name|
      expect(interfaces[name][:state]).to eq("unknown")
      expect(plugin[:counters][:network][:interfaces][name][:rx][:bytes]).to match(/\A\d+\z/)
    end
  end

  describe "with ethtool installed" do
    let(:ethtool) { "/sbin/ethtool" }

    it "passes each interface name to ethtool as its own argument" do
      %w{x#y a+b comma,1}.each do |name|
        expect(plugin).to have_received(:shell_out).with(["/sbin/ethtool", name])
        %w{-g -l -c -k -a -i}.each do |option|
          expect(plugin).to have_received(:shell_out).with(["/sbin/ethtool", option, name])
        end
      end
    end
  end

  it "keeps the routes of an interface whose name ends in a symbol" do
    expect(interfaces["end+"][:routes]).to include(include("destination" => "203.0.113.0/24", "scope" => "link"))
  end
end
