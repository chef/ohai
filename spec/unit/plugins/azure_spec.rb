#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright (c) 2011-2016 Chef Software, Inc.
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

require_relative "../../spec_helper.rb"
require "open-uri"

describe Ohai::System, "plugin azure" do
  let(:plugin) { get_plugin("azure") }
  let(:hint) do
    {
      "public_ip" => "137.135.46.202",
      "vm_name" => "test-vm",
      "public_fqdn" => "service.cloudapp.net",
      "public_ssh_port" => "22",
      "public_winrm_port" => "5985",
    }
  end

  shared_examples_for "!azure" do
    it "does not set the azure attribute" do
      plugin.run
      expect(plugin[:azure]).to be_nil
    end
  end

  shared_examples_for "azure" do
    it "sets the azure attribute" do
      plugin.run
      expect(plugin[:azure]).to be_truthy
    end
  end

  describe "with azure hint file" do
    before(:each) do
      allow(plugin).to receive(:hint?).with("azure").and_return(hint)
    end

    it "sets the azure cloud attributes" do
      plugin.run
      expect(plugin[:azure]["public_ip"]).to eq("137.135.46.202")
      expect(plugin[:azure]["vm_name"]).to eq("test-vm")
      expect(plugin[:azure]["public_fqdn"]).to eq("service.cloudapp.net")
      expect(plugin[:azure]["public_ssh_port"]).to eq("22")
      expect(plugin[:azure]["public_winrm_port"]).to eq("5985")
    end

  end

  describe "without azure hint file or agent or dhcp options" do
    before(:each) do
      allow(plugin).to receive(:hint?).with("azure").and_return(false)
      allow(File).to receive(:exist?).with("/usr/sbin/waagent").and_return(false)
      allow(Dir).to receive(:exist?).with('C:\WindowsAzure').and_return(false)
      allow(File).to receive(:exist?).with("/var/lib/dhcp/dhclient.eth0.leases").and_return(true)
      @double_file = double("/var/lib/dhcp/dhclient.eth0.leases")
      allow(@double_file).to receive(:each).
        and_yield("lease {").
        and_yield('  interface "eth0";').
        and_yield("  fixed-address 192.168.1.194;").
        and_yield("  option subnet-mask 255.255.255.0;").
        and_yield("  option routers 192.168.1.1;").
        and_yield("  option dhcp-lease-time 86400;").
        and_yield("  option dhcp-message-type 5;").
        and_yield("  option domain-name-servers 8.8.8.8;").
        and_yield("  option dhcp-server-identifier 192.168.1.2;").
        and_yield("  option interface-mtu 1454;").
        and_yield("  option dhcp-renewal-time 42071;").
        and_yield("  option broadcast-address 192.168.1.255;").
        and_yield("  option dhcp-rebinding-time 74471;").
        and_yield('  option host-name "host-192-168-1-194";').
        and_yield('  option domain-name "openstacklocal";').
        and_yield("  renew 2 2016/03/01 01:49:41;").
        and_yield("  rebind 2 2016/03/01 13:22:07;").
        and_yield("  expire 2 2016/03/01 16:40:56;").
        and_yield("}")
      allow(File).to receive(:open).with("/var/lib/dhcp/dhclient.eth0.leases").and_return(@double_file)
    end

    it_behaves_like "!azure"
  end

  describe "with rackspace hint file, no agent, and no dhcp lease" do
    before(:each) do
      allow(plugin).to receive(:hint?).with("rackspace").and_return(true)
      allow(plugin).to receive(:hint?).with("azure").and_return(false)
      allow(File).to receive(:exist?).with("/usr/sbin/waagent").and_return(false)
      allow(Dir).to receive(:exist?).with('C:\WindowsAzure').and_return(false)
      allow(File).to receive(:exist?).with("/var/lib/dhcp/dhclient.eth0.leases").and_return(false)
    end

    it_behaves_like "!azure"
  end

  describe "without azure hint file but with agent on linux" do
    before(:each) do
      allow(plugin).to receive(:hint?).with("azure").and_return(false)
      allow(File).to receive(:exist?).with("/usr/sbin/waagent").and_return(true)
      allow(Dir).to receive(:exist?).with('C:\WindowsAzure').and_return(false)
    end

    it_behaves_like "azure"
  end

  describe "without azure hint file but with agent on windows" do
    before(:each) do
      allow(plugin).to receive(:hint?).with("azure").and_return(false)
      allow(File).to receive(:exist?).with("/usr/sbin/waagent").and_return(false)
      allow(Dir).to receive(:exist?).with('C:\WindowsAzure').and_return(true)
    end

    it_behaves_like "azure"
  end

  describe "without azure hint or agent but with dhcp option" do
    before(:each) do
      allow(plugin).to receive(:hint?).with("azure").and_return(false)
      allow(File).to receive(:exist?).with("/usr/sbin/waagent").and_return(false)
      allow(Dir).to receive(:exist?).with('C:\WindowsAzure').and_return(false)
      allow(File).to receive(:exist?).with("/var/lib/dhcp/dhclient.eth0.leases").and_return(true)
      @double_file = double("/var/lib/dhcp/dhclient.eth0.leases")
      allow(@double_file).to receive(:each).
        and_yield("lease {").
        and_yield('  interface "eth0";').
        and_yield("  fixed-address 10.1.0.5;").
        and_yield('  server-name "RD24BE05C6F140";').
        and_yield("  option subnet-mask 255.255.255.0;").
        and_yield("  option dhcp-lease-time 4294967295;").
        and_yield("  option routers 10.1.0.1;").
        and_yield("  option dhcp-message-type 5;").
        and_yield("  option dhcp-server-identifier 168.63.129.16;").
        and_yield("  option domain-name-servers 168.63.129.16;").
        and_yield("  option dhcp-renewal-time 4294967295;").
        and_yield("  option rfc3442-classless-static-routes 0,10,1,0,1,32,168,63,129,16,10,1,0,1;").
        and_yield("  option unknown-245 a8:3f:81:10;").
        and_yield("  option dhcp-rebinding-time 4294967295;").
        and_yield('  option domain-name "v4wvfurds4relghweduc4zqjmd.dx.internal.cloudapp.net";').
        and_yield("  renew 5 2152/03/10 09:03:39;").
        and_yield("  rebind 5 2152/03/10 09:03:39;").
        and_yield("  expire 5 2152/03/10 09:03:39;").
        and_yield("}")
      allow(File).to receive(:open).with("/var/lib/dhcp/dhclient.eth0.leases").and_return(@double_file)
    end

    it_behaves_like "azure"
  end

end
