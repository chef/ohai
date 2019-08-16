#
#  Author:: Nimesh Pathi <nimesh.patni@msystechnologies.com>
#  Copyright:: Copyright (c) 2018 Chef Software, Inc.
#  License:: Apache License, Version 2.0
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

require "spec_helper"
require "ipaddress"

describe Ohai::System, "Windows Network Plugin" do
  let(:plugin) { get_plugin("windows/network") }

  before do
    allow(plugin).to receive(:collect_os).and_return(:windows)
  end

  describe "#interface_code" do
    let(:interface_idx) { 1 }
    let(:index) { 2 }
    context "when interface index is given" do
      it "Returns a valid string having hexadecimal interface_index" do
        index = nil
        expect(plugin.interface_code(interface_idx, index)).to eq("0x1")
      end
    end
    context "when interface index is not given" do
      it "Returns a valid string having hexadecimal index" do
        interface_idx = nil
        expect(plugin.interface_code(interface_idx, index)).to eq("0x2")
      end
    end
  end

  describe "#prefer_ipv4" do
    let(:inet4) { "192.168.1.1" }
    let(:inet6) { "fe80::2fe:c8ff:fef5:c88f" }
    context "When Array is not passed" do
      it "Returns nil" do
        expect(plugin.prefer_ipv4("Invalid")).to be_nil
      end
    end
    context "When no address is passed in Array" do
      it "Returns nil" do
        expect(plugin.prefer_ipv4([])).to be_nil
      end
    end
    context "Preferred chances of IPV4 address" do
      it "Returns the address when only IPV4 address is passed" do
        expect(plugin.prefer_ipv4([inet4])).to eq(inet4)
      end
      it "Returns the address when IPV6 is also present at latter place" do
        expect(plugin.prefer_ipv4([inet4, inet6])).to eq(inet4)
      end
      it "Returns the address when IPV6 is also present at former place" do
        expect(plugin.prefer_ipv4([inet6, inet4])).to eq(inet4)
      end
    end
    context "Preferred chances of IPV6 address" do
      it "Returns the address when only IPV6 address is passed" do
        expect(plugin.prefer_ipv4([inet4])).to eq(inet4)
      end
      it "Does not return the address if IPV4 is also present at former place" do
        expect(plugin.prefer_ipv4([inet4, inet6])).not_to eq(inet6)
      end
      it "Does not return the address if IPV4 is also present at latter place" do
        expect(plugin.prefer_ipv4([inet6, inet4])).not_to eq(inet6)
      end
    end
  end

  describe "#favored_default_route_windows" do
    let(:interface1) do
      { "index" => 1,
        "interface_index" => 1,
        "ip_connection_metric" => 10,
        "default_ip_gateway" => ["fe80::2fe:c8ff:fef5:c88f", "192.168.1.1"] }
    end
    let(:iface_config) { { 1 => interface1 } }
    context "When a hash is not passed" do
      it "Returns nil" do
        expect(plugin.favored_default_route_windows("Invalid")).to be_nil
      end
    end
    context "When no interface is passed in Hash" do
      it "Returns nil" do
        expect(plugin.favored_default_route_windows({})).to be_nil
      end
    end
    context "When an interface configuration is passed" do
      context "without default_ip_gateway" do
        it "Returns nil" do
          interface1["default_ip_gateway"] = nil
          expect(plugin.favored_default_route_windows(iface_config)).to be_nil
        end
      end
      context "with default_ip_gateway" do
        it "Returns a hash with details" do
          expect(plugin.favored_default_route_windows(iface_config)).to be_a(Hash)
          expect(plugin.favored_default_route_windows(iface_config)).not_to be_empty
        end
        it "Returns the default_gateway in IPV4 format" do
          expect(plugin.favored_default_route_windows(iface_config)).to include(default_ip_gateway: "192.168.1.1")
        end
      end
    end
    context "When multiple interfaces are passed" do
      let(:interface2) do
        { "index" => 2,
          "interface_index" => 3,
          "ip_connection_metric" => 20,
          "default_ip_gateway" => ["192.168.1.2"] }
      end
      let(:iface_config) do
        { 1 => interface1,
          2 => interface2 }
      end
      it "Returns the default route as least metric interface" do
        expect(plugin.favored_default_route_windows(iface_config)).to include(interface_index: 1)
      end
      it "Returns its default_gateway in IPV4 format" do
        expect(plugin.favored_default_route_windows(iface_config)).to include(default_ip_gateway: "192.168.1.1")
      end
    end
  end
end
