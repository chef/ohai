#
# Author:: Daniel DeLeo (dan@getchef.com)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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
# WITHOUT WARRANTIES OR CONDIT"Net::HTTP Response"NS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'
require 'ohai/plugins/openstack'

describe "OpenStack Plugin" do

  let(:openstack_hint) { false }
  let(:hp_hint) { false }

  let(:ohai_system) { Ohai::System.new }
  let(:ohai_data) { ohai_system.data }

  let(:openstack_plugin) do
    plugin = get_plugin("openstack", ohai_system)
    plugin.stub(:hint?).with("openstack").and_return(openstack_hint)
    plugin.stub(:hint?).with("hp").and_return(hp_hint)
    plugin
  end

  before do
  end

  context "when there is no relevant hint" do

    it "does not set any openstack data" do
      openstack_plugin.run
      expect(ohai_data).to_not have_key("openstack")
    end

  end

  context "when there is an `openstack` hint" do
    let(:openstack_hint) { true }

    context "and the metadata service is not available" do

      before do
        openstack_plugin.should_receive(:can_metadata_connect?).
          with(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR,80).
          and_return(false)
      end

      it "does not set any openstack data" do
        openstack_plugin.run
        expect(ohai_data).to_not have_key("openstack")
      end
    end

    context "and the metadata service is available" do

      let(:metadata_version) { "2009-04-04" }

      let(:metadata_root) do
        <<EOM
reservation-id
public-keys/
security-groups
public-ipv4
ami-manifest-path
instance-type
instance-id
local-ipv4
ari-id
local-hostname
placement/
ami-launch-index
public-hostname
hostname
ami-id
instance-action
aki-id
block-device-mapping/
EOM
      end

      let(:metadata_values) do
        {
          "reservation-id" => "r-4tjvl99h",
          "public-keys/" => "0=dan-default",
          "public-keys/0/" => "openssh-key",
          "public-keys/0/openssh-key" => "SSH KEY DATA",
          "security-groups" => "default",
          "public-ipv4" => "",
          "ami-manifest-path" => "FIXME",
          "instance-type" => "opc-tester",
          "instance-id" => "i-0000162a",
          "local-ipv4" => "172.31.7.23",
          "ari-id" => "ari-00000037",
          "local-hostname" => "ohai-7-system-test.opscode.us",
          "placement/" => "availability-zone",
          "placement/availability-zone" => "nova",
          "ami-launch-index" => "0",
          "public-hostname" => "ohai-7-system-test.opscode.us",
          "hostname" => "ohai-7-system-test.opscode.us",
          "ami-id" => "ami-00000035",
          "instance-action" => "none",
          "aki-id" => "aki-00000036",
          "block-device-mapping/" => "ami\nroot",
          "block-device-mapping/ami" => "vda",
          "block-device-mapping/root" => "/dev/vda"
        }
      end

      let(:http_client) { double("Net::HTTP", :read_timeout= => nil) }

      def expect_get(url, response_body)
        http_client.should_receive(:get).
          with(url).
          and_return(double("HTTP Response", :code => "200", :body => response_body))
      end

      before do
        openstack_plugin.should_receive(:can_metadata_connect?).
          with(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR,80).
          and_return(true)

        Net::HTTP.stub(:start).
          with(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR).
          and_return(http_client)

        openstack_plugin.stub(:best_api_version).and_return(metadata_version)

        expect_get("/#{metadata_version}/meta-data/", metadata_root)

        metadata_values.each do |md_id, md_value|
          expect_get("/#{metadata_version}/meta-data/#{md_id}", md_value)
        end

        openstack_plugin.run
      end

      it "reads the reservation_id from the metadata service" do
        expect(ohai_data['openstack']['reservation_id']).to eq("r-4tjvl99h")
      end
      it "reads the public_keys_0_openssh_key from the metadata service" do
        expect(ohai_data['openstack']['public_keys_0_openssh_key']).to eq("SSH KEY DATA")
      end
      it "reads the security_groups from the metadata service" do
        expect(ohai_data['openstack']['security_groups']).to eq(["default"])
      end
      it "reads the public_ipv4 from the metadata service" do
        expect(ohai_data['openstack']['public_ipv4']).to eq("")
      end
      it "reads the ami_manifest_path from the metadata service" do
        expect(ohai_data['openstack']['ami_manifest_path']).to eq("FIXME")
      end
      it "reads the instance_type from the metadata service" do
        expect(ohai_data['openstack']['instance_type']).to eq("opc-tester")
      end
      it "reads the instance_id from the metadata service" do
        expect(ohai_data['openstack']['instance_id']).to eq("i-0000162a")
      end
      it "reads the local_ipv4 from the metadata service" do
        expect(ohai_data['openstack']['local_ipv4']).to eq("172.31.7.23")
      end
      it "reads the ari_id from the metadata service" do
        expect(ohai_data['openstack']['ari_id']).to eq("ari-00000037")
      end
      it "reads the local_hostname from the metadata service" do
        expect(ohai_data['openstack']['local_hostname']).to eq("ohai-7-system-test.opscode.us")
      end
      it "reads the placement_availability_zone from the metadata service" do
        expect(ohai_data['openstack']['placement_availability_zone']).to eq("nova")
      end
      it "reads the ami_launch_index from the metadata service" do
        expect(ohai_data['openstack']['ami_launch_index']).to eq("0")
      end
      it "reads the public_hostname from the metadata service" do
        expect(ohai_data['openstack']['public_hostname']).to eq("ohai-7-system-test.opscode.us")
      end
      it "reads the hostname from the metadata service" do
        expect(ohai_data['openstack']['hostname']).to eq("ohai-7-system-test.opscode.us")
      end
      it "reads the ami_id from the metadata service" do
        expect(ohai_data['openstack']['ami_id']).to eq("ami-00000035")
      end
      it "reads the instance_action from the metadata service" do
        expect(ohai_data['openstack']['instance_action']).to eq("none")
      end
      it "reads the aki_id from the metadata service" do
        expect(ohai_data['openstack']['aki_id']).to eq("aki-00000036")
      end
      it "reads the block_device_mapping_ami from the metadata service" do
        expect(ohai_data['openstack']['block_device_mapping_ami']).to eq("vda")
      end
      it "reads the block_device_mapping_root from the metadata service" do
        expect(ohai_data['openstack']['block_device_mapping_root']).to eq("/dev/vda")
      end
      it "reads the provider from the metadata service" do
        expect(ohai_data['openstack']['provider']).to eq("openstack")
      end
    end


  end
end

