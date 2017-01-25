#
# Author:: Cary Penniman (<cary@rightscale.com>)
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

require "resolv"
require_relative "../../spec_helper.rb"

describe Ohai::System, "plugin rackspace" do
  let(:plugin) { get_plugin("rackspace") }

  before(:each) do
    allow(Resolv).to receive(:getname).and_return("1.2.3.4")

    plugin[:hostname] = "katie"

    plugin[:network] = {
      :interfaces => {
        :eth0 => {
          "addresses" => {
            "1.2.3.4" => {
              "broadcast" => "67.23.20.255",
              "netmask" => "255.255.255.0",
              "family" => "inet",
            },
            "2a00:1a48:7805:111:e875:efaf:ff08:75" => {
              "family" => "inet6",
              "prefixlen" => "64",
              "scope" => "Global",
            },
            "fe80::4240:95ff:fe47:6eed" => {
              "scope" => "Link",
              "prefixlen" => "64",
              "family" => "inet6",
            },
            "40:40:95:47:6E:ED" => {
              "family" => "lladdr",
            },
          },
        },
      },
    }

    plugin[:network][:interfaces][:eth1] = {
      :addresses => {
        "fe80::4240:f5ff:feab:2836" => {
          "scope" => "Link",
          "prefixlen" => "64",
          "family" => "inet6",
        },
        "5.6.7.8" => {
          "broadcast" => "10.176.191.255",
          "netmask" => "255.255.224.0",
          "family" => "inet",
        },
        "40:40:F5:AB:28:36" => {
          "family" => "lladdr",
        },
      },
    }

    # In olden days we could detect rackspace by a -rscloud suffix on the kernel
    # This is here to make #has_rackspace_kernel? fail until we remove that check
    plugin[:kernel] = { :release => "1.2.13-not-rackspace" }

    # We need a generic stub here for the later stubs with arguments to work
    # Because, magic.
    allow(plugin).to receive(:shell_out).and_return(mock_shell_out(1, "", ""))
  end

  shared_examples_for "!rackspace" do
    it "does not create rackspace attribute" do
      plugin.run
      expect(plugin[:rackspace]).to be_nil
    end
  end

  shared_examples_for "rackspace" do
    it "has rackspace attribute" do
      plugin.run
      expect(plugin[:rackspace]).not_to be_nil
    end

    it "has expected rackspace ip/hostname attributes" do
      plugin.run
      expect(plugin[:rackspace][:public_ip]).not_to be_nil
      expect(plugin[:rackspace][:private_ip]).not_to be_nil
      expect(plugin[:rackspace][:public_ipv4]).not_to be_nil
      expect(plugin[:rackspace][:local_ipv4]).not_to be_nil
      expect(plugin[:rackspace][:public_ipv6]).not_to be_nil
      expect(plugin[:rackspace][:local_ipv6]).to be_nil
      expect(plugin[:rackspace][:local_hostname]).not_to be_nil
      expect(plugin[:rackspace][:public_hostname]).not_to be_nil
    end

    it "resolves hostname if reverse dns is set" do
      allow(Resolv).to receive(:getname).and_return("1234.resolved.com")
      plugin.run
      expect(plugin[:rackspace][:public_hostname]).to eq("1234.resolved.com")
    end

    [Resolv::ResolvError, Resolv::ResolvTimeout].each do |exception|
      it "returns ip address when reverse dns returns exception: #{exception}" do
        allow(Resolv).to receive(:getname).and_raise(exception)
        plugin.run
        expect(plugin[:rackspace][:public_hostname]).to eq("1.2.3.4")
      end
    end

    it "has correct values for all attributes" do
      plugin.run
      expect(plugin[:rackspace][:public_ip]).to eq("1.2.3.4")
      expect(plugin[:rackspace][:private_ip]).to eq("5.6.7.8")
      expect(plugin[:rackspace][:public_ipv4]).to eq("1.2.3.4")
      expect(plugin[:rackspace][:local_ipv4]).to eq("5.6.7.8")
      expect(plugin[:rackspace][:public_ipv6]).to eq("2a00:1a48:7805:111:e875:efaf:ff08:75")
      expect(plugin[:rackspace][:local_hostname]).to eq("katie")
      expect(plugin[:rackspace][:public_hostname]).to eq("1.2.3.4")
    end

    it "captures region information" do
      provider_data = <<-OUT
provider = "Rackspace"
service_type = "cloudServers"
server_id = "21301000"
created_at = "2012-12-06T22:08:16Z"
region = "dfw"
OUT
      allow(plugin).to receive(:shell_out).with("xenstore-ls vm-data/provider_data").and_return(mock_shell_out(0, provider_data, ""))
      plugin.run
      expect(plugin[:rackspace][:region]).to eq("dfw")
    end

    it "logs a debug message when region info cannot be collected" do
      expect(plugin).
        to receive(:shell_out).
        with("xenstore-ls vm-data/provider_data").
        and_raise(Ohai::Exceptions::Exec)

      expect(Ohai::Log).
        to receive(:debug).
        with("rackspace plugin: Unable to find xenstore-ls, cannot capture " \
             "region information for Rackspace cloud")

      plugin.run

      expect(plugin[:rackspace]).not_to have_key(:region)
    end

    it "captures instance ID information" do
      provider_data = "instance-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      allow(plugin).to receive(:shell_out).with("xenstore-read name").and_return(mock_shell_out(0, provider_data, ""))
      plugin.run
      expect(plugin[:rackspace][:instance_id]).to eq("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx")
    end

    it "logs error if instance id cannot be found" do
      expect(plugin).
        to receive(:shell_out).
        with("xenstore-read name").
        and_raise(Ohai::Exceptions::Exec)

      expect(Ohai::Log).
        to receive(:debug).
        with("rackspace plugin: Unable to find xenstore-read, cannot capture " \
             "instance ID information for Rackspace cloud")

      plugin.run

      expect(plugin[:rackspace]).not_to have_key(:instance_id)
    end
  end

  describe "with rackspace hint file" do
    it_behaves_like "rackspace"

    before(:each) do
      allow(Resolv).to receive(:getname).and_raise(Resolv::ResolvError)
      allow(File).to receive(:exist?).with("/etc/resolv.conf").and_return(true)
      allow(File).to receive(:read).with("/etc/resolv.conf").and_return("")
      allow(plugin).to receive(:hint?).with("rackspace").and_return(true)
    end

    describe "with no public interfaces (empty eth0)" do
      before do
        # unset public (eth0) addresses
        plugin[:network][:interfaces][:eth0]["addresses"] = {}
      end

      it "has correct rackspace attributes" do
        plugin.run
        # expliticly nil
        expect(plugin[:rackspace][:public_ip]).to be_nil
        expect(plugin[:rackspace][:public_ipv4]).to be_nil
        expect(plugin[:rackspace][:public_ipv6]).to be_nil
        expect(plugin[:rackspace][:public_hostname]).to be_nil
        # per normal
        expect(plugin[:rackspace][:local_ipv6]).to be_nil
        expect(plugin[:rackspace][:private_ip]).to eq("5.6.7.8")
        expect(plugin[:rackspace][:local_ipv4]).to eq("5.6.7.8")
        expect(plugin[:rackspace][:local_hostname]).to eq("katie")
      end
    end
  end

  describe "without hint file" do
    it_behaves_like "!rackspace"

    before(:each) do
      allow(plugin).to receive(:hint?).with("rackspace").and_return(false)
    end
  end

  describe "xenstore provider returns rackspace" do
    it_behaves_like "rackspace"

    before(:each) do
      stdout = "Rackspace\n"
      allow(plugin).to receive(:hint?).with("rackspace").and_return(false)
      allow(plugin).to receive(:shell_out).with("xenstore-read vm-data/provider_data/provider").and_return(mock_shell_out(0, stdout, "" ))
    end
  end

  describe "xenstore provider does not return rackspace" do
    it_behaves_like "!rackspace"

    before(:each) do
      allow(plugin).to receive(:hint?).with("rackspace").and_return(false)
      stdout = "cumulonimbus\n"
      allow(plugin).to receive(:shell_out).with("xenstore-read vm-data/provider_data/provider").and_return(mock_shell_out(0, stdout, "" ))
    end
  end

  describe "xenstore provider does not exist" do
    it_behaves_like "!rackspace"

    before(:each) do
      allow(plugin).to receive(:hint?).with("rackspace").and_return(false)
      allow(plugin).
        to receive(:shell_out).
        with("xenstore-read vm-data/provider_data/provider").
        and_raise(Ohai::Exceptions::Exec)
    end
  end

  describe "when private networks shell out fails" do
    it "logs an error and does not collect private_networks" do
      allow(plugin).to receive(:hint?).with("rackspace").and_return(true)

      expect(plugin).
        to receive(:shell_out).
        with("xenstore-ls vm-data/networking").
        and_raise(Ohai::Exceptions::Exec)

      expect(Ohai::Log).
        to receive(:debug).
        with("rackspace plugin: Unable to capture custom private networking " \
             "information for Rackspace cloud")

      plugin.run

      expect(plugin[:rackspace]).not_to have_key(:private_networks)
    end
  end

  describe "does not have private networks" do
    before do
      stdout = 'BC764E20422B = "{"label": "public"}"\n'
      allow(plugin).to receive(:hint?).with("rackspace").and_return(true)
      allow(plugin).to receive(:shell_out).with("xenstore-ls vm-data/networking").and_return(mock_shell_out(0, stdout, "" ))
      stdout = '{"label": "public", "broadcast": "9.10.11.255", "ips": [{"ip": "9.10.11.12", "netmask": "255.255.255.0", "enabled": "1", "gateway": null}], "mac": "BC:76:4E:20:42:2B", "dns": ["69.20.0.164", "69.20.0.196"], "gateway": null}'
      allow(plugin).to receive(:shell_out).with("xenstore-read vm-data/networking/BC764E20422B").and_return(mock_shell_out(0, stdout, "" ))
    end

    it "does not have private_networks object" do
      plugin.run
      expect(plugin[:rackspace][:private_networks]).to eq([])
    end
  end

  describe "has private networks" do
    before do
      plugin[:network][:interfaces][:eth2] = {
        :addresses => {
          "fe80::be76:4eff:fe20:422b" => {
            "scope" => "Link",
            "prefixlen" => "64",
            "family" => "inet6",
         },
          "9.10.11.12" => {
            "broadcast" => "9.10.11.255",
            "netmask" => "255.255.255.0",
            "family" => "inet",
          },
          "BC:76:4E:20:42:2B" => {
            "family" => "lladdr",
          },
        },
      }
      stdout = 'BC764E20422B = "{"label": "private-network"}"\n'
      allow(plugin).to receive(:shell_out).with("xenstore-ls vm-data/networking").and_return(mock_shell_out(0, stdout, "" ))
      stdout = '{"label": "private-network", "broadcast": "9.10.11.255", "ips": [{"ip": "9.10.11.12", "netmask": "255.255.255.0", "enabled": "1", "gateway": null}], "mac": "BC:76:4E:20:42:2B", "dns": ["69.20.0.164", "69.20.0.196"], "gateway": null}'
      allow(plugin).to receive(:shell_out).with("xenstore-read vm-data/networking/BC764E20422B").and_return(mock_shell_out(0, stdout, "" ))
      allow(plugin).to receive(:hint?).with("rackspace").and_return(true)
    end

    it "has private_networks object" do
      plugin.run
      expect(plugin[:rackspace][:private_networks]).not_to be_nil
    end

    it "has correct values for all rackspace attributes" do
      plugin.run
      expect(plugin[:rackspace][:private_networks][0][:label]).to eq("private-network")
      expect(plugin[:rackspace][:private_networks][0][:broadcast]).to eq("9.10.11.255")
      expect(plugin[:rackspace][:private_networks][0][:mac]).to eq("BC:76:4E:20:42:2B")
    end

  end

end
