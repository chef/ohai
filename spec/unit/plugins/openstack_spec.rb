#
# Author:: Daniel DeLeo (dan@chef.io)
# Copyright:: Copyright (c) 2014-2016 Chef Software, Inc.
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

require "spec_helper"

describe Ohai::System, "plugin openstack" do

  let(:plugin) { get_plugin("openstack") }
  let(:default_timeout) { 2 }

  before do
    PasswdEntry = Struct.new(:name, :uid, :gid, :dir, :shell, :gecos)
    allow(plugin).to receive(:hint?).with("openstack").and_return(false)
    plugin[:virtualization] = { systems: {} }
  end

  context "when there is no relevant hint or virtualization data" do
    it "does not set any openstack data" do
      plugin.run
      expect(plugin[:openstack]).to be_nil
    end
  end

  context "when virtualization data is Openstack", :unix_only do
    context "and the metadata service is not available" do
      before do
        allow(plugin).to receive(:can_socket_connect?)
          .with(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR, 80, default_timeout)
          .and_return(false)
        plugin[:virtualization] = { systems: { openstack: "guest" } }
        expect(Etc).to receive(:getpwnam).and_raise(ArgumentError)
        plugin.run
      end

      it "sets provider attribute to openstack" do
        expect(plugin[:openstack][:provider]).to eq("openstack")
      end

      it "doesn't set metadata attributes" do
        expect(plugin[:openstack][:instance_id]).to be_nil
      end
    end
  end

  context "when running on dreamhost", :unix_only do
    it "sets openstack provider attribute to dreamhost" do
      plugin["etc"] = { "passwd" => { "dhc-user" => {} } }
      allow(plugin).to receive(:can_socket_connect?)
        .with(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR, 80, default_timeout)
        .and_return(false)
      plugin[:virtualization] = { systems: { openstack: "guest" } }
      expect(Etc).to receive(:getpwnam).and_return(PasswdEntry.new("dhc-user", 800, 800, "/var/www", "/bin/false", "The dreamhost user"))
      plugin.run
      expect(plugin[:openstack][:provider]).to eq("dreamhost")
    end
  end

  context "when the hint is present" do
    context "and the metadata service is not available" do
      before do
        allow(plugin).to receive(:can_socket_connect?)
          .with(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR, 80, default_timeout)
          .and_return(false)
        allow(plugin).to receive(:hint?).with("openstack").and_return(true)
        plugin.run
      end

      it "sets openstack provider attribute if the hint is provided" do
        expect(plugin[:openstack][:provider]).to eq("openstack")
      end

      it "doesn't set metadata attributes" do
        expect(plugin[:openstack][:instance_id]).to be_nil
      end
      context "when timout was set" do
        let(:override_timout) { 10 }

        before do
          Ohai::Config.ohai[:openstack_metadata_timeout] = override_timout
        end

        after do
          Ohai::Config.ohai[:openstack_metadata_timeout] = nil
        end

        it "overwrite timout by setting" do
          allow(plugin).to receive(:can_socket_connect?)
            .with(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR, 80, override_timout)
            .and_return(false)
          allow(plugin).to receive(:hint?).with("openstack").and_return(true)
          plugin.run
        end
      end
    end

    context "and the metadata service is available" do

      let(:metadata_version) { "2009-04-04" }

      let(:metadata_root) do
        <<~EOM
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
          "public-ipv4" => "172.31.7.2",
          "public-ipv6" => "",
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
          "block-device-mapping/root" => "/dev/vda",
        }
      end

      let(:openstack_metadata_version) { "2009-04-04" }
      let(:openstack_metadata_endpoint) { "http://169.254.169.254/" }

      let(:openstack_metadata_values) do
        '{
            "availability_zone" : "nova",
            "hostname" : "ohai.novalocal",
            "launch_index" : 0,
            "meta" : {
                "priority" : "low",
                "role" : "ohaiserver"
            },
            "name" : "ohai_spec",
            "public_keys" : {
                "mykey" : "SSH KEY DATA"
            },
            "uuid" : "00000000-0000-0000-0000-100000000000"
        }'
      end

      let(:http_client) { double("Net::HTTP", { :read_timeout= => nil, :keep_alive_timeout= => nil } ) }

      def allow_get(url, response_body)
        allow(http_client).to receive(:get)
          .with(url)
          .and_return(double("HTTP Response", code: "200", body: response_body))
      end

      def allow_get_response(url, response_body)
        allow(http_client).to receive(:get_response)
          .with(url, nil, nil)
          .and_return(double("HTTP Response", code: "200", body: response_body))
      end

      before do
        allow(plugin).to receive(:hint?).with("openstack").and_return(true)
        allow(plugin).to receive(:can_socket_connect?)
          .with(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR, 80, default_timeout)
          .and_return(true)

        allow(Net::HTTP).to receive(:start)
          .with(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR)
          .and_return(http_client)

        allow(plugin).to receive(:best_api_version).and_return(metadata_version)

        allow_get("/#{metadata_version}/meta-data/", metadata_root)

        metadata_values.each do |md_id, md_value|
          allow_get("/#{metadata_version}/meta-data/#{md_id}", md_value)
        end

        allow_get_response(
          URI.parse("#{openstack_metadata_endpoint}#{openstack_metadata_version}/meta_data.json"),
          openstack_metadata_values
        )
        plugin.run
      end

      it "reads the reservation_id from the metadata service" do
        expect(plugin["openstack"]["reservation_id"]).to eq("r-4tjvl99h")
      end
      it "reads the public_keys_0_openssh_key from the metadata service" do
        expect(plugin["openstack"]["public_keys_0_openssh_key"]).to eq("SSH KEY DATA")
      end
      it "reads the security_groups from the metadata service" do
        expect(plugin["openstack"]["security_groups"]).to eq(["default"])
      end
      it "reads the public_ipv4 from the metadata service" do
        expect(plugin["openstack"]["public_ipv4"]).to eq("172.31.7.2")
      end
      it "ignore the public_ipv6 from the metadata service when empty" do
        expect(plugin["openstack"]).not_to have_key("public_ipv6")
      end
      it "reads the ami_manifest_path from the metadata service" do
        expect(plugin["openstack"]["ami_manifest_path"]).to eq("FIXME")
      end
      it "reads the instance_type from the metadata service" do
        expect(plugin["openstack"]["instance_type"]).to eq("opc-tester")
      end
      it "reads the instance_id from the metadata service" do
        expect(plugin["openstack"]["instance_id"]).to eq("i-0000162a")
      end
      it "reads the local_ipv4 from the metadata service" do
        expect(plugin["openstack"]["local_ipv4"]).to eq("172.31.7.23")
      end
      it "reads the ari_id from the metadata service" do
        expect(plugin["openstack"]["ari_id"]).to eq("ari-00000037")
      end
      it "reads the local_hostname from the metadata service" do
        expect(plugin["openstack"]["local_hostname"]).to eq("ohai-7-system-test.opscode.us")
      end
      it "reads the placement_availability_zone from the metadata service" do
        expect(plugin["openstack"]["placement_availability_zone"]).to eq("nova")
      end
      it "reads the ami_launch_index from the metadata service" do
        expect(plugin["openstack"]["ami_launch_index"]).to eq("0")
      end
      it "reads the public_hostname from the metadata service" do
        expect(plugin["openstack"]["public_hostname"]).to eq("ohai-7-system-test.opscode.us")
      end
      it "reads the hostname from the metadata service" do
        expect(plugin["openstack"]["hostname"]).to eq("ohai-7-system-test.opscode.us")
      end
      it "reads the ami_id from the metadata service" do
        expect(plugin["openstack"]["ami_id"]).to eq("ami-00000035")
      end
      it "reads the instance_action from the metadata service" do
        expect(plugin["openstack"]["instance_action"]).to eq("none")
      end
      it "reads the aki_id from the metadata service" do
        expect(plugin["openstack"]["aki_id"]).to eq("aki-00000036")
      end
      it "reads the block_device_mapping_ami from the metadata service" do
        expect(plugin["openstack"]["block_device_mapping_ami"]).to eq("vda")
      end
      it "reads the block_device_mapping_root from the metadata service" do
        expect(plugin["openstack"]["block_device_mapping_root"]).to eq("/dev/vda")
      end
      it "sets the provider to openstack" do
        expect(plugin["openstack"]["provider"]).to eq("openstack")
      end
    end
  end

  context "when openstack virtualization is present" do
    context "and the metadata service is not available" do
      before do
        allow(plugin).to receive(:can_socket_connect?)
          .with(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR, 80, default_timeout)
          .and_return(false)
        plugin[:virtualization] = { systems: { openstack: "guest" } }
        plugin.run
      end

      it "sets openstack provider attribute since virtualization is present" do
        expect(plugin[:openstack][:provider]).to eq("openstack")
      end

      it "doesn't set metadata attributes" do
        expect(plugin[:openstack][:instance_id]).to be_nil
      end
    end
  end
end
