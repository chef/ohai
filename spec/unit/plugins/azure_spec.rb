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

require "spec_helper"
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

  let(:response_data) do
    { "compute" => { "location" => "westus",
                     "name" => "timtest",
                     "offer" => "UbuntuServer",
                     "osType" => "Linux",
                     "platformFaultDomain" => "0",
                     "platformUpdateDomain" => "0",
                     "publisher" => "Canonical",
                     "sku" => "16.04-LTS",
                     "version" => "16.04.201707270",
                     "vmId" => "f78151b3-da8b-4bd8-a592-d9ce8a57ea65",
                     "vmSize" => "Standard_DS2_v2" },
      "network" => { "interface" => [ { "ipv4" =>
                                          {  "ipAddress" => [{ "privateIpAddress" => "10.0.1.6", "publicIpAddress" => "40.118.212.225" }],
                                             "subnet" => [{ "address" => "10.0.1.0", "prefix" => "24" }] },
                                        "ipv6" =>
                                          { "ipAddress" => [] },
                                        "macAddress" => "000D3A37F080" }] } }
  end

  before do
    # skips all the metadata logic unless we want to test it
    allow(plugin).to receive(:can_socket_connect?)
      .with(Ohai::Mixin::AzureMetadata::AZURE_METADATA_ADDR, 80)
      .and_return(false)
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
      expect(plugin[:azure]).to have_key(:metadata)
    end
  end

  describe "with azure hint file" do
    before do
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
    before do
      allow(plugin).to receive(:hint?).with("azure").and_return(false)
      allow(File).to receive(:exist?).with("/usr/sbin/waagent").and_return(false)
      allow(Dir).to receive(:exist?).with('C:\WindowsAzure').and_return(false)
      allow(File).to receive(:exist?).with("/var/lib/dhcp/dhclient.eth0.leases").and_return(true)
      @double_file = double("/var/lib/dhcp/dhclient.eth0.leases")
      allow(@double_file).to receive(:each)
        .and_yield("lease {")
        .and_yield('  interface "eth0";')
        .and_yield("  fixed-address 192.168.1.194;")
        .and_yield("  option subnet-mask 255.255.255.0;")
        .and_yield("  option routers 192.168.1.1;")
        .and_yield("  option dhcp-lease-time 86400;")
        .and_yield("  option dhcp-message-type 5;")
        .and_yield("  option domain-name-servers 8.8.8.8;")
        .and_yield("  option dhcp-server-identifier 192.168.1.2;")
        .and_yield("  option interface-mtu 1454;")
        .and_yield("  option dhcp-renewal-time 42071;")
        .and_yield("  option broadcast-address 192.168.1.255;")
        .and_yield("  option dhcp-rebinding-time 74471;")
        .and_yield('  option host-name "host-192-168-1-194";')
        .and_yield('  option domain-name "openstacklocal";')
        .and_yield("  renew 2 2016/03/01 01:49:41;")
        .and_yield("  rebind 2 2016/03/01 13:22:07;")
        .and_yield("  expire 2 2016/03/01 16:40:56;")
        .and_yield("}")
      allow(File).to receive(:open).with("/var/lib/dhcp/dhclient.eth0.leases").and_return(@double_file)
    end

    it_behaves_like "!azure"
  end

  describe "with rackspace hint file, no agent, and no dhcp lease" do
    before do
      allow(plugin).to receive(:hint?).with("rackspace").and_return(true)
      allow(plugin).to receive(:hint?).with("azure").and_return(false)
      allow(File).to receive(:exist?).with("/usr/sbin/waagent").and_return(false)
      allow(Dir).to receive(:exist?).with('C:\WindowsAzure').and_return(false)
      allow(File).to receive(:exist?).with("/var/lib/dhcp/dhclient.eth0.leases").and_return(false)
    end

    it_behaves_like "!azure"
  end

  describe "without azure hint file but with agent on linux" do
    before do
      allow(plugin).to receive(:hint?).with("azure").and_return(false)
      allow(File).to receive(:exist?).with("/usr/sbin/waagent").and_return(true)
      allow(Dir).to receive(:exist?).with('C:\WindowsAzure').and_return(false)
    end

    it_behaves_like "azure"
  end

  describe "without azure hint file but with agent on windows" do
    before do
      allow(plugin).to receive(:hint?).with("azure").and_return(false)
      allow(File).to receive(:exist?).with("/usr/sbin/waagent").and_return(false)
      allow(Dir).to receive(:exist?).with('C:\WindowsAzure').and_return(true)
    end

    it_behaves_like "azure"
  end

  describe "without azure hint or agent but with dhcp option" do
    before do
      allow(plugin).to receive(:hint?).with("azure").and_return(false)
      allow(File).to receive(:exist?).with("/usr/sbin/waagent").and_return(false)
      allow(Dir).to receive(:exist?).with('C:\WindowsAzure').and_return(false)
      allow(File).to receive(:exist?).with("/var/lib/dhcp/dhclient.eth0.leases").and_return(true)
      @double_file = double("/var/lib/dhcp/dhclient.eth0.leases")
      allow(@double_file).to receive(:each)
        .and_yield("lease {")
        .and_yield('  interface "eth0";')
        .and_yield("  fixed-address 10.1.0.5;")
        .and_yield('  server-name "RD24BE05C6F140";')
        .and_yield("  option subnet-mask 255.255.255.0;")
        .and_yield("  option dhcp-lease-time 4294967295;")
        .and_yield("  option routers 10.1.0.1;")
        .and_yield("  option dhcp-message-type 5;")
        .and_yield("  option dhcp-server-identifier 168.63.129.16;")
        .and_yield("  option domain-name-servers 168.63.129.16;")
        .and_yield("  option dhcp-renewal-time 4294967295;")
        .and_yield("  option rfc3442-classless-static-routes 0,10,1,0,1,32,168,63,129,16,10,1,0,1;")
        .and_yield("  option unknown-245 a8:3f:81:10;")
        .and_yield("  option dhcp-rebinding-time 4294967295;")
        .and_yield('  option domain-name "v4wvfurds4relghweduc4zqjmd.dx.internal.cloudapp.net";')
        .and_yield("  renew 5 2152/03/10 09:03:39;")
        .and_yield("  rebind 5 2152/03/10 09:03:39;")
        .and_yield("  expire 5 2152/03/10 09:03:39;")
        .and_yield("}")
      allow(File).to receive(:open).with("/var/lib/dhcp/dhclient.eth0.leases").and_return(@double_file)
    end

    it_behaves_like "azure"
  end

  describe "with non-responsive metadata endpoint" do
    before do
      allow(plugin).to receive(:hint?).with("azure").and_return({})
    end

    it "does not return metadata information" do
      allow(plugin).to receive(:can_socket_connect?)
        .with(Ohai::Mixin::AzureMetadata::AZURE_METADATA_ADDR, 80)
        .and_return(true)
      allow(plugin).to receive(:fetch_metadata).and_return(nil)

      plugin.run
      expect(plugin[:azure]).to have_key(:metadata)
      expect(plugin[:azure][:metadata]).to be_nil
    end
  end

  describe "with responsive metadata endpoint" do
    before do
      allow(plugin).to receive(:hint?).with("azure").and_return({})
      allow(plugin).to receive(:can_socket_connect?)
        .with(Ohai::Mixin::AzureMetadata::AZURE_METADATA_ADDR, 80)
        .and_return(true)
      allow(plugin).to receive(:fetch_metadata).and_return(response_data)
      plugin.run
    end

    it "returns metadata compute information" do
      expect(plugin[:azure][:metadata][:compute][:location]).to eq("westus")
      expect(plugin[:azure][:metadata][:compute][:name]).to eq("timtest")
      expect(plugin[:azure][:metadata][:compute][:offer]).to eq("UbuntuServer")
      expect(plugin[:azure][:metadata][:compute][:osType]).to eq("Linux")
      expect(plugin[:azure][:metadata][:compute][:platformFaultDomain]).to eq("0")
      expect(plugin[:azure][:metadata][:compute][:platformUpdateDomain]).to eq("0")
      expect(plugin[:azure][:metadata][:compute][:publisher]).to eq("Canonical")
      expect(plugin[:azure][:metadata][:compute][:sku]).to eq("16.04-LTS")
      expect(plugin[:azure][:metadata][:compute][:version]).to eq("16.04.201707270")
      expect(plugin[:azure][:metadata][:compute][:vmId]).to eq("f78151b3-da8b-4bd8-a592-d9ce8a57ea65")
      expect(plugin[:azure][:metadata][:compute][:vmSize]).to eq("Standard_DS2_v2")
    end

    it "returns metadata network information" do
      expect(plugin[:azure][:metadata][:network][:interfaces]["000D3A37F080"][:mac]).to eq("000D3A37F080")
      expect(plugin[:azure][:metadata][:network][:interfaces]["000D3A37F080"][:public_ipv6]).to eq([])
      expect(plugin[:azure][:metadata][:network][:interfaces]["000D3A37F080"][:public_ipv4]).to eq(["40.118.212.225"])
      expect(plugin[:azure][:metadata][:network][:interfaces]["000D3A37F080"][:local_ipv6]).to eq([])
      expect(plugin[:azure][:metadata][:network][:interfaces]["000D3A37F080"][:local_ipv4]).to eq(["10.0.1.6"])
      expect(plugin[:azure][:metadata][:network][:public_ipv6]).to eq([])
      expect(plugin[:azure][:metadata][:network][:public_ipv4]).to eq(["40.118.212.225"])
      expect(plugin[:azure][:metadata][:network][:local_ipv6]).to eq([])
      expect(plugin[:azure][:metadata][:network][:local_ipv4]).to eq(["10.0.1.6"])
    end
  end
end
