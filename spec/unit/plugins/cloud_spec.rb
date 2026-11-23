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

require "spec_helper"

describe "CloudAttrs object" do
  before do
    @plugin = get_plugin("cloud")
  end

  let(:cloud_node) do
    { "public_ipv4_addrs" => ["1.2.3.1"],
      "local_ipv4_addrs" => ["1.2.4.1"],
      "public_ipv6_addrs" => ["3ffe:505:2::1"],
      "local_ipv6_addrs" => ["3ffe:506:2::1"],
      "public_ipv4" => "1.2.3.1",
      "local_ipv4" => "1.2.4.1",
      "public_ipv6" => "3ffe:505:2::1",
      "local_ipv6" => "3ffe:506:2::1",
      "public_hostname" => "myhost.somewhere.com",
      "local_hostname" => "my-localhost",
      "provider" => "my_awesome_cloud",
     }
  end

  it "populates cloud mash" do
    @cloud_attr_obj = ::CloudAttrs.new
    @cloud_attr_obj.add_ipv4_addr("1.2.3.1", :public)
    @cloud_attr_obj.add_ipv4_addr("1.2.4.1", :private)
    @cloud_attr_obj.add_ipv6_addr("3ffe:505:2::1", :public)
    @cloud_attr_obj.add_ipv6_addr("3ffe:506:2::1", :private)
    @cloud_attr_obj.public_hostname = "myhost.somewhere.com"
    @cloud_attr_obj.local_hostname = "my-localhost"
    @cloud_attr_obj.provider = "my_awesome_cloud"
    expect(@cloud_attr_obj.cloud_mash).to eq(cloud_node)
  end

  it "ignores blank hostnames" do
    @cloud_attr_obj = ::CloudAttrs.new
    @cloud_attr_obj.public_hostname = ""
    @cloud_attr_obj.local_hostname = " "
    @cloud_attr_obj.provider = "my_awesome_cloud"
    expect(@cloud_attr_obj.cloud_mash).to eq("provider" => "my_awesome_cloud")
  end

  it "ignores a bad ipv4 address" do
    @cloud_attr_obj = ::CloudAttrs.new
    @cloud_attr_obj.add_ipv4_addr("somebogusstring", :public)
    expect(@cloud_attr_obj.cloud_mash).to be_nil
  end

  it "ignores a bad ipv6 address" do
    @cloud_attr_obj = ::CloudAttrs.new
    @cloud_attr_obj.add_ipv6_addr("FEED:B0B:DEAD:BEEF", :public)
    expect(@cloud_attr_obj.cloud_mash).to be_nil
  end

  it "ignores an ipv6 address passed to ipv4" do
    @cloud_attr_obj = ::CloudAttrs.new
    @cloud_attr_obj.add_ipv4_addr("3ffe:506:2::1", :public)
    expect(@cloud_attr_obj.cloud_mash).to be_nil
  end

  it "ignores an ipv4 address passed to ipv6" do
    @cloud_attr_obj = ::CloudAttrs.new
    @cloud_attr_obj.add_ipv6_addr("1.2.3.4", :public)
    expect(@cloud_attr_obj.cloud_mash).to be_nil
  end

  it "ignores empty addresses" do
    @cloud_attr_obj = ::CloudAttrs.new
    @cloud_attr_obj.add_ipv4_addr("", :public)
    @cloud_attr_obj.add_ipv6_addr(" ", :private)
    expect(@cloud_attr_obj.cloud_mash).to be_nil
  end

  it "keeps the valid addresses alongside a bad one" do
    @cloud_attr_obj = ::CloudAttrs.new
    @cloud_attr_obj.add_ipv4_addr("bogus", :public)
    @cloud_attr_obj.add_ipv4_addr("1.2.3.4", :public)
    expect(@cloud_attr_obj.cloud_mash[:public_ipv4_addrs]).to eq(["1.2.3.4"])
  end

end

describe Ohai::System, "plugin cloud" do
  before do
    @plugin = get_plugin("cloud")
  end

  describe "with no cloud mashes" do
    it "doesn't populate the cloud data" do
      @plugin[:alibaba] = nil
      @plugin[:ec2] = nil
      @plugin[:rackspace] = nil
      @plugin[:eucalyptus] = nil
      @plugin[:linode] = nil
      @plugin[:azure] = nil
      @plugin[:gce] = nil
      @plugin[:digital_ocean] = nil
      @plugin[:softlayer] = nil
      @plugin[:oci] = nil
      @plugin[:scaleway] = nil
      @plugin.run
      expect(@plugin[:cloud]).to be_nil
    end
  end

  describe "with partial provider data" do
    # a failed metadata fetch can leave a provider's attribute with little or
    # nothing in it; the cloud attribute must still be populated

    it "populates cloud provider for an empty Alibaba mash" do
      @plugin[:alibaba] = Mash.new
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("alibaba")
    end

    it "populates cloud provider for an empty GCE mash" do
      @plugin[:gce] = Mash.new
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("gce")
    end

    it "populates cloud provider for GCE interfaces without access configs" do
      @plugin[:gce] = Mash.new("instance" => { "networkInterfaces" => [{ "ip" => "10.0.0.2" }] })
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("gce")
      expect(@plugin[:cloud][:local_ipv4]).to eq("10.0.0.2")
    end

    it "populates cloud provider for OCI without metadata" do
      @plugin[:oci] = Mash.new("metadata" => nil)
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("oci")
    end

    it "populates cloud provider for OCI metadata without network data" do
      @plugin[:oci] = Mash.new("metadata" => { "compute" => { "hostname" => "oci-host" } })
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("oci")
      expect(@plugin[:cloud][:local_hostname]).to eq("oci-host")
    end

    it "populates EC2 values with an empty public address" do
      @plugin[:ec2] = Mash.new("public_ipv4" => "", "local_ipv4" => "10.0.0.3")
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("ec2")
      expect(@plugin[:cloud][:public_ipv4]).to be_nil
      expect(@plugin[:cloud][:local_ipv4]).to eq("10.0.0.3")
    end

    it "keeps other providers' values when one provider's data is malformed" do
      @plugin[:gce] = Mash.new("instance" => 5)
      @plugin[:ec2] = Mash.new("local_ipv4" => "10.0.0.3")
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("ec2")
      expect(@plugin[:cloud][:local_ipv4]).to eq("10.0.0.3")
    end
  end

  describe "with Alibaba mash" do
    before do
      @plugin[:alibaba] = Mash.new
      @plugin[:alibaba]["meta_data"] = Mash.new
    end

    it "populates hostname" do
      @plugin[:alibaba]["meta_data"]["hostname"] = "foo"
      @plugin.run
      expect(@plugin[:cloud][:local_hostname]).to eq("foo")
    end

    it "populates cloud public ip" do
      @plugin[:alibaba]["meta_data"]["eipv4"] = "174.129.150.8"
      @plugin.run
      expect(@plugin[:cloud][:public_ipv4_addrs][0]).to eq("174.129.150.8")
    end

    it "populates cloud private ip" do
      @plugin[:alibaba]["meta_data"]["private_ipv4"] = "10.252.42.149"
      @plugin.run
      expect(@plugin[:cloud][:local_ipv4_addrs][0]).to eq("10.252.42.149")
    end

    it "populates cloud public ip from public_ipv4 without an EIP" do
      @plugin[:alibaba]["meta_data"]["public_ipv4"] = "47.88.1.2"
      @plugin.run
      expect(@plugin[:cloud][:public_ipv4]).to eq("47.88.1.2")
    end

    it "populates cloud provider" do
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("alibaba")
    end
  end

  describe "with Scaleway mash" do
    before do
      @plugin[:scaleway] = Mash.new(
        "hostname" => "sample-hostname",
        "private_ip" => "10.8.23.7",
        "public_ip" => { "dynamic" => false, "address" => "5.1.9.3" },
        "ipv6" => { "address" => "2001:bc8:4400:2500::d:2", "gateway" => "2001:bc8:4400:2500::d:1", "netmask" => "127" }
      )
    end

    it "populates cloud values" do
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("scaleway")
      expect(@plugin[:cloud][:public_ipv4]).to eq("5.1.9.3")
      expect(@plugin[:cloud][:local_ipv4]).to eq("10.8.23.7")
      expect(@plugin[:cloud][:public_ipv6]).to eq("2001:bc8:4400:2500::d:2")
      expect(@plugin[:cloud][:local_hostname]).to eq("sample-hostname")
    end

    it "populates cloud values without IPv6" do
      @plugin[:scaleway]["ipv6"] = nil
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("scaleway")
      expect(@plugin[:cloud][:public_ipv6]).to be_nil
    end
  end

  describe "with EC2 mash" do
    before do
      @plugin[:ec2] = Mash.new
    end

    it "populates cloud public ip" do
      @plugin[:ec2]["public_ipv4"] = "174.129.150.8"
      @plugin.run
      expect(@plugin[:cloud][:public_ipv4_addrs][0]).to eq(@plugin[:ec2]["public_ipv4"])
    end

    it "populates cloud private ip" do
      @plugin[:ec2]["local_ipv4"] = "10.252.42.149"
      @plugin.run
      expect(@plugin[:cloud][:local_ipv4_addrs][0]).to eq(@plugin[:ec2]["local_ipv4"])
    end

    it "populates cloud provider" do
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("ec2")
    end

    # an instance in a VPC without DNS hostnames, where the metadata service
    # answers public-hostname with an empty body
    it "leaves out a blank public hostname" do
      @plugin[:ec2]["public_ipv4"] = "203.0.113.85"
      @plugin[:ec2]["public_hostname"] = ""
      @plugin[:ec2]["local_hostname"] = "ip-172-31-2-47.us-west-2.compute.internal"
      @plugin.run
      expect(@plugin[:cloud]).not_to have_key(:public_hostname)
      expect(@plugin[:cloud][:local_hostname]).to eq("ip-172-31-2-47.us-west-2.compute.internal")
    end
  end

  describe "with GCE mash" do
    describe "with a public IP" do
      before do
        @plugin[:gce] = Mash.new
        @plugin[:gce]["instance"] = Mash.new
        @plugin[:gce]["instance"]["networkInterfaces"] = [
          {
            "accessConfigs" => [ { "externalIp" => "8.35.198.173", "type" => "ONE_TO_ONE_NAT" } ],
            "ip" => "10.240.0.102",
            "network" => "projects/foo/networks/default",
          },
        ]
      end

      it "populates cloud public ip" do
        @plugin.run
        expect(@plugin[:cloud][:public_ipv4_addrs][0]).to eq("8.35.198.173")
      end

      it "populates cloud private ip" do
        @plugin.run
        expect(@plugin[:cloud][:local_ipv4_addrs][0]).to eq("10.240.0.102")
      end

      it "populates cloud provider" do
        @plugin.run
        expect(@plugin[:cloud][:provider]).to eq("gce")
      end
    end

    describe "with no public IP" do
      before do
        @plugin[:gce] = Mash.new
        @plugin[:gce]["instance"] = Mash.new
        @plugin[:gce]["instance"]["networkInterfaces"] = [
          {
            "accessConfigs" => [ { "externalIp" => "", "type" => "ONE_TO_ONE_NAT" } ],
            "ip" => "10.240.0.102",
            "network" => "projects/foo/networks/default",
          },
        ]
      end

      it "does not populate cloud public ip" do
        @plugin.run
        expect(@plugin[:cloud][:public_ipv4_addrs]).to be_nil
      end

      it "populates cloud private ip" do
        @plugin.run
        expect(@plugin[:cloud][:local_ipv4_addrs][0]).to eq("10.240.0.102")
      end

      it "populates cloud provider" do
        @plugin.run
        expect(@plugin[:cloud][:provider]).to eq("gce")
      end
    end
  end

  describe "with rackspace" do
    before do
      @plugin[:rackspace] = Mash.new
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
      expect(@plugin[:cloud][:public_ipv4_addrs].first).to eq(@plugin[:rackspace][:public_ipv4])
    end

    it "populates first cloud public ip" do
      @plugin[:rackspace][:local_ipv4] = "174.129.150.8"
      @plugin.run
      expect(@plugin[:cloud][:local_ipv4_addrs].first).to eq(@plugin[:rackspace][:local_ipv4])
    end

    it "populates cloud provider" do
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("rackspace")
    end
  end

  describe "with linode mash" do
    before do
      @plugin[:linode] = Mash.new
    end

    it "populates cloud public ip" do
      @plugin[:linode]["public_ip"] = "174.129.150.8"
      @plugin.run
      expect(@plugin[:cloud][:public_ipv4_addrs][0]).to eq(@plugin[:linode][:public_ip])
    end

    it "populates cloud private ip" do
      @plugin[:linode]["private_ip"] = "10.252.42.149"
      @plugin.run
      expect(@plugin[:cloud][:local_ipv4_addrs][0]).to eq(@plugin[:linode][:private_ip])
    end

    it "populates first cloud public ip" do
      @plugin[:linode]["public_ip"] = "174.129.150.8"
      @plugin.run
      expect(@plugin[:cloud][:public_ipv4_addrs].first).to eq(@plugin[:linode][:public_ip])
    end

    it "populates cloud public ipv6" do
      @plugin[:linode]["public_ipv6"] = "2001:db8:1::5"
      @plugin.run
      expect(@plugin[:cloud][:public_ipv6]).to eq("2001:db8:1::5")
    end

    it "populates cloud provider" do
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("linode")
    end
  end

  describe "with eucalyptus mash" do
    before do
      @plugin[:eucalyptus] = Mash.new
    end

    it "populates cloud public ip" do
      @plugin[:eucalyptus]["public_ipv4"] = "174.129.150.8"
      @plugin.run
      expect(@plugin[:cloud][:public_ipv4_addrs][0]).to eq(@plugin[:eucalyptus]["public_ipv4"])
    end

    it "populates cloud private ip" do
      @plugin[:eucalyptus]["local_ipv4"] = "10.252.42.149"
      @plugin.run
      expect(@plugin[:cloud][:local_ipv4_addrs][0]).to eq(@plugin[:eucalyptus]["local_ipv4"])
    end

    it "populates cloud provider" do
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("eucalyptus")
    end
  end

  describe "with Azure mash" do
    before do
      @plugin[:azure] = Mash.new
      @plugin[:azure][:metadata] = {
        "compute" =>
          {
            "location" => "westus",
            "name" => "timtest",
            "offer" => "UbuntuServer",
            "osType" => "Linux",
            "platformFaultDomain" => "0",
            "platformUpdateDomain" => "0",
            "publisher" => "Canonical",
            "sku" => "16.04-LTS",
            "version" => "16.04.201707270",
            "vmId" => "f78151b3-da8b-4bd8-a592-d9ce8357e365",
            "vmSize" => "Standard_DS2_v2",
          },
        "network" =>
          {
            "interfaces" =>
              {
                "000D3A37F080" =>
                  {
                    "mac" => "000D3A37F080",
                    "public_ipv6" => [],
                    "public_ipv4" => ["40.118.212.225"],
                    "local_ipv6" => [],
                    "local_ipv4" => ["10.0.1.6"],
                  },
              },
            "public_ipv4" => ["40.118.212.225"],
            "local_ipv4" => ["10.0.1.6"],
            "public_ipv6" => [],
            "local_ipv6" => [],
            },
          }
    end

    it "populates cloud public ip" do
      @plugin.run
      expect(@plugin[:cloud][:public_ipv4_addrs][0]).to eq("40.118.212.225")
    end

    it "doesn't populates cloud vm_name" do
      @plugin.run
      expect(@plugin[:cloud][:vm_name]).not_to eq("timtest")
    end

    it "populates cloud public_hostname" do
      @plugin[:azure]["public_fqdn"] = "linux-vm-svc.cloudapp.net"
      @plugin.run
      expect(@plugin[:cloud][:public_hostname]).to eq("linux-vm-svc.cloudapp.net")
    end

    it "doesn't populate cloud public_ssh_port" do
      @plugin[:azure]["public_ssh_port"] = "22"
      @plugin.run
      expect(@plugin[:cloud][:public_ssh_port]).to be_nil
    end

    it "does not populate cloud public_ssh_port when winrm is used" do
      @plugin[:azure]["public_winrm_port"] = "5985"
      @plugin.run
      expect(@plugin[:cloud][:public_ssh_port]).to be_nil
    end

    it "populates cloud public_winrm_port" do
      @plugin[:azure]["public_winrm_port"] = "5985"
      @plugin.run
      expect(@plugin[:cloud][:public_winrm_port]).to be_nil
    end

    it "populates cloud provider" do
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("azure")
    end
  end

  describe "with Azure mash without metadata" do
    before do
      @plugin[:azure] = Mash.new
      @plugin[:azure][:metadata] = nil
    end

    it "populates cloud provider" do
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("azure")
    end
  end

  describe "with Azure mash whose metadata has no network data" do
    before do
      @plugin[:azure] = Mash.new
      @plugin[:azure][:metadata] = { "compute" => { "location" => "westus" } }
    end

    it "populates cloud provider" do
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("azure")
    end
  end

  describe "with digital_ocean mash" do
    before do
      @plugin[:digital_ocean] = Mash.new
      @plugin[:digital_ocean][:interfaces] = Mash.new
      @plugin[:digital_ocean][:interfaces] = {
        "private" =>
          [
            {
              "ipv4" =>
              {
                "ip_address" => "10.135.32.4",
                "netmask" => "255.255.0.0",
                "gateway" => "10.135.0.1",
              },
              "mac" => "36:9e:23:65:c1:fe",
              "type" => "private",
            },
          ],
        "public" =>
          [
            {
              "ipv4" =>
                {
                  "ip_address" => "207.154.221.42",
                  "netmask" => "255.255.240.0",
                  "gateway" => "207.154.208.1",
                },
              "ipv6" =>
                {
                  "ip_address" => "2A03:B0C0:0003:00D0:0000:0000:3B15:B001",
                  "cidr" => 64,
                  "gateway" => "2A03:B0C0:0003:00D0:0000:0000:0000:0001",
                },
              "anchor_ipv4" =>
                {
                  "ip_address" => "10.19.0.5",
                  "netmask" => "255.255.0.0",
                  "gateway" => "10.19.0.1",
                },
              "mac" => "9a:80:15:02:7a:c1",
              "type" => "public",
            },
          ],
        }
    end

    before do
      @plugin.run
    end

    it "populates cloud local hostname" do
      expect(@plugin[:cloud][:local_hostname]).to be_nil
    end

    it "populates cloud public_ipv4_addrs" do
      expect(@plugin[:cloud][:public_ipv4_addrs]).to eq(["207.154.221.42"])

    end

    it "populates cloud local_ipv4_addrs" do
      expect(@plugin[:cloud][:local_ipv4_addrs]).to eq(["10.135.32.4"])

    end

    it "populates cloud public_ipv4" do
      expect(@plugin[:cloud][:public_ipv4]).to eq("207.154.221.42")
    end

    it "populates cloud local_ipv4" do
      expect(@plugin[:cloud][:local_ipv4]).to eq("10.135.32.4")
    end

    it "populates cloud public_ipv6_addrs" do
      expect(@plugin[:cloud][:public_ipv6_addrs]).to eq(["2a03:b0c0:3:d0::3b15:b001"])
    end

    it "populates cloud local_ipv6_addrs" do
      expect(@plugin[:cloud][:local_ipv6_addrs]).to be_nil
    end

    it "populates cloud public_ipv6" do
      expect(@plugin[:cloud][:public_ipv6]).to eq("2a03:b0c0:3:d0::3b15:b001")
    end

    it "populates cloud local_ipv6" do
      expect(@plugin[:cloud][:local_ipv6]).to be_nil
    end

    it "populates cloud local_hostname" do
      @plugin[:digital_ocean][:hostname] = "droplet-1"
      @plugin.run
      expect(@plugin[:cloud][:local_hostname]).to eq("droplet-1")
    end

    it "populates cloud provider" do
      expect(@plugin[:cloud][:provider]).to eq("digital_ocean")
    end
  end

  describe "with softlayer mash" do
    before do
      @plugin[:softlayer] = Mash.new
      @plugin[:softlayer] = { "local_ipv4" => "192.168.0.1",
                              "public_ipv4" => "8.8.8.8",
                              "public_fqdn" => "abc1234.public.com",
      }
    end

    it "populates cloud public ip" do
      @plugin.run
      expect(@plugin[:cloud][:public_ipv4_addrs][0]).to eq(@plugin[:softlayer][:public_ipv4])
    end

    it "populates cloud private ip" do
      @plugin.run
      expect(@plugin[:cloud][:local_ipv4_addrs][0]).to eq(@plugin[:softlayer][:local_ipv4])
    end

    it "populates first cloud public ip" do
      @plugin.run
      expect(@plugin[:cloud][:public_ipv4_addrs].first).to eq(@plugin[:softlayer][:public_ipv4])
    end

    it "populates cloud public_hostname" do
      @plugin.run
      expect(@plugin[:cloud][:public_hostname]).to eq(@plugin[:softlayer][:public_fqdn])
    end

    it "populates cloud provider" do
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("softlayer")
    end
  end

  describe "with OCI mash" do
    before do
      @plugin[:oci] = Mash.new
      @plugin[:oci][:metadata] = {
        "compute" => {
          "hostname" => "my-hostname",
        },
        "network" => {
          "interface" => [
            { "vnicId" => "ocid1.vnic.oc1.phx.exampleuniqueID", "privateIp" => "10.0.3.6", "vlanTag" => 11,
              "macAddr" => "00:00:00:00:00:01", "virtualRouterIp" => "10.0.3.1", "subnetCidrBlock" => "10.0.3.0/24",
              "nicIndex" => 0 },
          ],
        },
      }
    end

    it "doesn't populates cloud vm_name" do
      @plugin.run
      expect(@plugin[:cloud][:vm_name]).not_to eq("testtest")
    end

    it "populates cloud local_hostname" do
      @plugin.run
      expect(@plugin[:cloud][:local_hostname]).to eq("my-hostname")
    end

    it "populates cloud private ip" do
      @plugin.run
      expect(@plugin[:cloud][:local_ipv4]).to eq(@plugin[:oci][:metadata][:network][:interface][0]["privateIp"])
    end

    it "populates cloud provider" do
      @plugin.run
      expect(@plugin[:cloud][:provider]).to eq("oci")
    end
  end
end
