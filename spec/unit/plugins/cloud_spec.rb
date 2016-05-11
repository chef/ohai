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

require_relative "../../spec_helper.rb"

describe Ohai::System, "plugin cloud" do
  before(:each) do
    @plugin = get_plugin("cloud")
  end

  describe "with no cloud mashes" do
    it "doesn't populate the cloud data" do
      @plugin[:ec2] = nil
      @plugin[:rackspace] = nil
      @plugin[:eucalyptus] = nil
      @plugin[:linode] = nil
      @plugin[:azure] = nil
      @plugin[:digital_ocean] = nil
      @plugin.run
      expect(@plugin[:cloud]).to be_nil
    end
  end

  describe "with EC2 mash" do
    before do
      @plugin[:ec2] = Mash.new()
    end

    it "populates cloud public ip" do
      @plugin[:ec2]["public_ipv4"] = "174.129.150.8"
      @plugin.run
      expect(@plugin[:cloud][:public_ips][0]).to eq(@plugin[:ec2]["public_ipv4"])
    end

    it "populates cloud private ip" do
      @plugin[:ec2]["local_ipv4"] = "10.252.42.149"
      @plugin.run
      expect(@plugin[:cloud][:private_ips][0]).to eq(@plugin[:ec2]["local_ipv4"])
    end

    it "populates cloud provider" do
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("ec2")
    end
  end

  describe "with rackspace" do
    before do
      @plugin[:rackspace] = Mash.new()
    end

    it "populates cloud public ip" do
      @plugin[:rackspace][:public_ipv4] = "174.129.150.8"
      @plugin.run
      expect(@plugin[:cloud][:public_ipv4]).to eq(@plugin[:rackspace][:public_ipv4])
    end

    it "populates cloud public ipv6" do
      @plugin[:rackspace][:public_ipv6] = "2a00:1a48:7805:111:e875:efaf:ff08:75"
      @plugin.run
      expect(@plugin[:cloud][:public_ipv6]).to eq(@plugin[:rackspace][:public_ipv6])
    end

    it "populates cloud private ip" do
      @plugin[:rackspace][:local_ipv4] = "10.252.42.149"
      @plugin.run
      expect(@plugin[:cloud][:local_ipv4]).to eq(@plugin[:rackspace][:local_ipv4])
    end

    it "populates cloud private ipv6" do
      @plugin[:rackspace][:local_ipv6] = "2a00:1a48:7805:111:e875:efaf:ff08:75"
      @plugin.run
      expect(@plugin[:cloud][:local_ipv6]).to eq(@plugin[:rackspace][:local_ipv6])
    end

    it "populates first cloud public ip" do
      @plugin[:rackspace][:public_ipv4] = "174.129.150.8"
      @plugin.run
      expect(@plugin[:cloud][:public_ips].first).to eq(@plugin[:rackspace][:public_ipv4])
    end

    it "populates first cloud public ip" do
      @plugin[:rackspace][:local_ipv4] = "174.129.150.8"
      @plugin.run
      expect(@plugin[:cloud][:private_ips].first).to eq(@plugin[:rackspace][:local_ipv4])
    end

    it "populates cloud provider" do
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("rackspace")
    end
  end

  describe "with linode mash" do
    before do
      @plugin[:linode] = Mash.new()
    end

    it "populates cloud public ip" do
      @plugin[:linode]["public_ip"] = "174.129.150.8"
      @plugin.run
      expect(@plugin[:cloud][:public_ips][0]).to eq(@plugin[:linode][:public_ip])
    end

    it "populates cloud private ip" do
      @plugin[:linode]["private_ip"] = "10.252.42.149"
      @plugin.run
      expect(@plugin[:cloud][:private_ips][0]).to eq(@plugin[:linode][:private_ip])
    end

    it "populates first cloud public ip" do
      @plugin[:linode]["public_ip"] = "174.129.150.8"
      @plugin.run
      expect(@plugin[:cloud][:public_ips].first).to eq(@plugin[:linode][:public_ip])
    end

    it "populates cloud provider" do
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("linode")
    end
  end

  describe "with eucalyptus mash" do
    before do
      @plugin[:eucalyptus] = Mash.new()
    end

    it "populates cloud public ip" do
      @plugin[:eucalyptus]["public_ipv4"] = "174.129.150.8"
      @plugin.run
      expect(@plugin[:cloud][:public_ips][0]).to eq(@plugin[:eucalyptus]["public_ipv4"])
    end

    it "populates cloud private ip" do
      @plugin[:eucalyptus]["local_ipv4"] = "10.252.42.149"
      @plugin.run
      expect(@plugin[:cloud][:private_ips][0]).to eq(@plugin[:eucalyptus]["local_ipv4"])
    end

    it "populates cloud provider" do
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("eucalyptus")
    end
  end

  describe "with Azure mash" do
    before do
      @plugin[:azure] = Mash.new()
    end

    it "populates cloud private ip" do
      @plugin[:azure]["private_ip"] = "10.0.0.1"
      @plugin.run
      expect(@plugin[:cloud][:private_ips][0]).to eq(@plugin[:azure]["private_ip"])
    end

    it "populates cloud public ip" do
      @plugin[:azure]["public_ip"] = "174.129.150.8"
      @plugin.run
      expect(@plugin[:cloud][:public_ips][0]).to eq(@plugin[:azure]["public_ip"])
      expect(@plugin[:cloud][:public_ipv4]).to eq(@plugin[:azure]["public_ip"])
    end

    it "populates cloud vm_name" do
      @plugin[:azure]["vm_name"] = "linux-vm"
      @plugin.run
      expect(@plugin[:cloud][:vm_name]).to eq(@plugin[:azure]["vm_name"])
    end

    it "populates cloud public_fqdn" do
      @plugin[:azure]["public_fqdn"] = "linux-vm-svc.cloudapp.net"
      @plugin.run
      expect(@plugin[:cloud][:public_fqdn]).to eq(@plugin[:azure]["public_fqdn"])
      expect(@plugin[:cloud][:public_hostname]).to eq(@plugin[:azure]["public_fqdn"])
    end

    it "populates cloud public_ssh_port" do
      @plugin[:azure]["public_ssh_port"] = "22"
      @plugin.run
      expect(@plugin[:cloud][:public_ssh_port]).to eq(@plugin[:azure]["public_ssh_port"])
    end

    it "should not populate cloud public_ssh_port when winrm is used" do
      @plugin[:azure]["public_winrm_port"] = "5985"
      @plugin.run
      expect(@plugin[:cloud][:public_ssh_port]).to be_nil
    end

    it "populates cloud public_winrm_port" do
      @plugin[:azure]["public_winrm_port"] = "5985"
      @plugin.run
      expect(@plugin[:cloud][:public_winrm_port]).to eq(@plugin[:azure]["public_winrm_port"])
    end

    it "populates cloud provider" do
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("azure")
    end
  end

  describe "with digital_ocean mash" do
    before do
      @plugin[:digital_ocean] = Mash.new
      @plugin[:digital_ocean][:hostname] = "public.example.com"
      @plugin[:digital_ocean][:interfaces] = Mash.new
      @plugin[:digital_ocean][:interfaces] = {
        "public" => [
          {
            "ipv4" => {
              "ip_address" => "159.203.92.161",
              "netmask" => "255.255.240.0",
              "gateway" => "159.203.80.1",
            },
            "ipv6" => {
              "ip_address" => "2604:A880:0800:00A1:0000:0000:0201:0001",
              "cidr" => 64,
              "gateway" => "2604:A880:0800:00A1:0000:0000:0000:0001",
            },
            "anchor_ipv4" => {
              "ip_address" => "10.17.0.5",
              "netmask" => "255.255.0.0",
              "gateway" => "10.17.0.1",
            },
            "mac" => "04:01:e5:14:03:01",
            "type" => "public",
          },
        ],
      }
    end

    before(:each) do
      @plugin.run
    end

    it "populates cloud public hostname" do
      expect(@plugin[:cloud][:public_hostname]).to eq("public.example.com")
    end

    it "populates cloud local hostname" do
      expect(@plugin[:cloud][:local_hostname]).to be_nil
    end

    it "populates cloud public ips" do
      expect(@plugin[:cloud][:public_ips]).to eq([ "159.203.92.161", "2604:A880:0800:00A1:0000:0000:0201:0001" ])
    end

    it "populates cloud private ips" do
      expect(@plugin[:cloud][:private_ips]).to be_empty
    end

    it "populates cloud public_ipv4" do
      expect(@plugin[:cloud][:public_ipv4]).to eq("159.203.92.161")
    end

    it "populates cloud local_ipv4" do
      expect(@plugin[:cloud][:local_ipv4]).to be_nil
    end

    it "populates cloud public_ipv6" do
      expect(@plugin[:cloud][:public_ipv6]).to eq("2604:A880:0800:00A1:0000:0000:0201:0001")
    end

    it "populates cloud local_ipv6" do
      expect(@plugin[:cloud][:local_ipv6]).to be_nil
    end

    it "populates cloud provider" do
      expect(@plugin[:cloud][:provider]).to eq("digital_ocean")
    end
  end
end
