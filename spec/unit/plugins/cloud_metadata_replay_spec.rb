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

# Runs each cloud plugin's metadata code against responses recorded from a
# real instance (spec/data/cloud_metadata). Detection is covered by each
# plugin's own spec; here a hint selects the plugin so the examples exercise
# the requests and the parsing.
describe "cloud plugins with recorded metadata service responses" do
  def run_plugin(name, recording)
    plugin = get_plugin(name)
    allow(plugin).to receive(:hint?).and_return(false)
    allow(plugin).to receive(:hint?).with(name).and_return({})
    allow(plugin).to receive(:can_socket_connect?).and_return(true)
    replay_metadata(recording)
    plugin.run
    plugin
  end

  {
    "ec2_amazon_linux_2023_x86_64" => { instance_type: "t3.small", local_ipv4: "172.31.2.47", architecture: "x86_64" },
    "ec2_amazon_linux_2027_aarch64" => { instance_type: "t4g.small", local_ipv4: "172.31.2.213", architecture: "arm64" },
  }.each do |recording, expected|
    describe "EC2, #{recording}" do
      let(:plugin) { run_plugin("ec2", recording) }
      let(:ec2) { plugin[:ec2] }
      let(:mac) { "02:00:5e:00:00:01" }

      it "reads the instance's identity and placement" do
        expect(ec2[:instance_id]).to eq("i-00000000feed0002")
        expect(ec2[:instance_type]).to eq(expected[:instance_type])
        expect(ec2[:ami_id]).to eq("ami-00000000feed0001")
        expect(ec2[:account_id]).to eq("123456789011")
        expect(ec2[:region]).to eq("us-west-2")
        expect(ec2[:availability_zone]).to eq("us-west-2a")
        expect(ec2[:placement_availability_zone_id]).to eq("usw2-az2")
        expect(ec2[:system]).to eq("nitro")
      end

      it "reads the addresses" do
        expect(ec2[:local_ipv4]).to eq(expected[:local_ipv4])
        expect(ec2[:public_ipv4]).to eq("203.0.113.11")
        expect(ec2[:mac]).to eq(mac)
      end

      it "reads the network interface" do
        interface = ec2[:network_interfaces_macs][mac]
        expect(interface[:interface_id]).to eq("eni-00000000feed0003")
        expect(interface[:subnet_id]).to eq("subnet-00000000feed0005")
        expect(interface[:vpc_id]).to eq("vpc-00000000feed0006")
        expect(interface[:vpc_ipv4_cidr_block]).to eq("172.31.0.0/16")
        expect(interface["ipv4-associations"]).to eq("203.0.113.11" => expected[:local_ipv4])
      end

      it "splits the security groups" do
        expect(ec2[:security_groups]).to eq(["ohai-audit"])
      end

      it "has no user data when the instance has none" do
        expect(ec2[:userdata]).to be_nil
      end

      it "doesn't keep the instance's temporary credentials" do
        expect(ec2.keys.grep(/security_credentials/)).to be_empty
        expect(ec2.to_hash.to_s).not_to include("SecretAccessKey")
      end

      it "sends the IMDSv2 session token with every request" do
        plugin
        gets = replayed_requests.select { |r| r[:method] == "GET" }
        expect(gets).not_to be_empty
        expect(gets.map { |r| r[:headers]["x-aws-ec2-metadata-token"] }.uniq).to eq([["T2hhaUZpeHR1cmVJbWRzVG9rZW4="]])
      end
    end
  end

  describe "DigitalOcean, digital_ocean_ubuntu_24_04" do
    let(:droplet) { run_plugin("digital_ocean", "digital_ocean_ubuntu_24_04")[:digital_ocean] }

    it "reads the droplet's identity" do
      expect(droplet[:droplet_id]).to eq(400000001)
      expect(droplet[:hostname]).to eq("ohai-audit-do")
      expect(droplet[:region]).to eq("nyc3")
    end

    it "reads the public interface with its IPv6 and anchor addresses" do
      public_interface = droplet[:interfaces][:public].first
      expect(public_interface[:ipv4][:ip_address]).to eq("203.0.113.11")
      expect(public_interface[:ipv6][:ip_address]).to eq("2001:db8:0800:0014:0000:0003:E8CF:B000")
      expect(public_interface[:anchor_ipv4][:ip_address]).to eq("10.20.0.5")
    end

    it "reads the private interface" do
      expect(droplet[:interfaces][:private].first[:ipv4][:ip_address]).to eq("10.116.0.2")
    end
  end

  describe "OCI, oci_solaris_11_4" do
    let(:metadata) { run_plugin("oci", "oci_solaris_11_4")[:oci][:metadata] }

    it "reads the instance document" do
      expect(metadata[:compute][:id]).to eq("ocid1.instance.oc1.us-sanjose-1.aaaaaaaaohaifixture0002")
      expect(metadata[:compute][:shape]).to eq("VM.Standard.E5.Flex")
      expect(metadata[:compute][:availabilityDomain]).to eq("Uocm:US-SANJOSE-1-AD-1")
      expect(metadata[:compute][:shapeConfig][:ocpus]).to eq(1.0)
    end

    it "reads the VNICs" do
      expect(metadata[:network][:interface].first["privateIp"]).to eq("10.0.1.12")
      expect(metadata[:network][:interface].first["vnicId"]).to eq("ocid1.vnic.oc1.us-sanjose-1.aaaaaaaaohaifixture0004")
    end

    it "keys the volume attachments by ID" do
      expect(metadata[:volumes].keys).to eq(["ocid1.instance.oc1.us-sanjose-1.aaaaaaaaohaifixture0002"])
      expect(metadata[:volumes].values.first[:volumeId]).to eq("ocid1.bootvolume.oc1.us-sanjose-1.aaaaaaaaohaifixture0005")
    end
  end

  describe "Azure, azure_ubuntu_24_04" do
    let(:plugin) { run_plugin("azure", "azure_ubuntu_24_04") }
    let(:metadata) { plugin[:azure][:metadata] }

    it "reads the compute document" do
      expect(metadata[:compute][:vmId]).to eq("0eaf0002-0000-4000-8000-0000feed0002")
      expect(metadata[:compute][:location]).to eq("westus2")
      expect(metadata[:compute][:vmSize]).to eq("Standard_B2s")
      expect(metadata[:compute][:osProfile][:computerName]).to eq("ohai-audit-az")
    end

    it "reads the interface's private address" do
      expect(metadata[:network][:interfaces]["02005E000011"][:local_ipv4]).to eq(["10.0.0.4"])
      expect(metadata[:network][:local_ipv4]).to eq(["10.0.0.4"])
    end

    it "asks IMDS for its versions, then sends Metadata: true" do
      plugin
      expect(replayed_requests.first[:path]).to eq("/metadata/instance")
      expect(replayed_requests.map { |r| r[:headers]["metadata"] }.uniq).to eq([["true"]])
    end
  end
end
