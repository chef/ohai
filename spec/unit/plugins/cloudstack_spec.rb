#
# Author:: Olle Lundberg (<geek@nerd.sh>)
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
require 'ohai/plugins/cloudstack'

describe "Cloudstack Plugin" do

  let(:cloudstack_hint) { false }

  let(:ohai_system) { Ohai::System.new }
  let(:ohai_data) { ohai_system.data }

  let(:cloudstack_plugin) do
    plugin = get_plugin("cloudstack", ohai_system)
    allow(plugin).to receive(:hint?).with("cloudstack").and_return(cloudstack_hint)
    plugin
  end

  before do
    stub_const("Ohai::Mixin::CloudstackMetadata::CLOUDSTACK_METADATA_ADDR", '10.10.10.10')
  end

  context "when there is no relevant hint" do

    it "does not set any cloudstack data" do
      cloudstack_plugin.run
      expect(ohai_data).to_not have_key("cloudstack")
    end

  end

  context "when there is a `cloudstack` hint" do
    let(:cloudstack_hint) { true }

    context "and the metadata service is not available" do

      before do
        expect(cloudstack_plugin).to receive(:can_metadata_connect?).
          with(Ohai::Mixin::CloudstackMetadata::CLOUDSTACK_METADATA_ADDR,80).
          and_return(false)
      end

      it "does not set any cloudstack data" do
        cloudstack_plugin.run
        expect(ohai_data).to_not have_key("cloudstack")
      end
    end

    context "and the metadata service is available" do

      let(:metadata_version) { "latest" }

      let(:metadata_root) do
        <<EOM
availability-zone
cloud-identifier
instance-id
local-hostname
local-ipv4
public-hostname
public-ipv4
service-offering
vm-id
EOM
      end

      let(:metadata_values) do
        {
          "local-ipv4" =>"10.235.34.23",
          "local-hostname" =>"VM-8983fb85-fb7f-46d6-8af1-c1b6666fec39",
          "public-hostname" =>"awesome-doge",
          "availability-zone" =>"TCS7",
          "service-offering" =>"2vCPU, 1GHz, 2GB RAM",
          "public-ipv4" =>"10.235.34.23",
          "vm-id"=>"8983fb85-fb7f-46d6-8af1-c1b6666fec39",
          "cloud-identifier"=>"CloudStack-{e84ff39d-ef64-4812-a8a9-7932f7b67f17}",
          "instance-id"=>"8983fb85-fb7f-46d6-8af1-c1b6666fec39"
        }
      end

      let(:http_client) { double("Net::HTTP", :read_timeout= => nil) }

      def expect_get(url, response_body)
        expect(http_client).to receive(:get).
          with(url).
          and_return(double("HTTP Response", :code => "200", :body => response_body))
      end

      before do
        expect(cloudstack_plugin).to receive(:can_metadata_connect?).
          with(Ohai::Mixin::CloudstackMetadata::CLOUDSTACK_METADATA_ADDR,80).
          and_return(true)

        allow(Net::HTTP).to receive(:start).
          with(Ohai::Mixin::CloudstackMetadata::CLOUDSTACK_METADATA_ADDR).
          and_return(http_client)

        allow(cloudstack_plugin).to receive(:best_api_version).and_return(metadata_version)

        expect_get("/#{metadata_version}/meta-data/", metadata_root)

        metadata_values.each do |md_id, md_value|
          expect_get("/#{metadata_version}/meta-data/#{md_id}", md_value)
        end

        cloudstack_plugin.run
      end

     it "reads the local ipv4 from the metadata service" do
        expect(ohai_data['cloudstack']['local_ipv4']).to eq("10.235.34.23")
      end
     it "reads the local hostname from the metadata service" do
        expect(ohai_data['cloudstack']['local_hostname']).to eq("VM-8983fb85-fb7f-46d6-8af1-c1b6666fec39")
      end
     it "reads the public hostname from the metadata service" do
        expect(ohai_data['cloudstack']['public_hostname']).to eq("awesome-doge")
      end
     it "reads the availability zone from the metadata service" do
        expect(ohai_data['cloudstack']['availability_zone']).to eq("TCS7")
      end
     it "reads the service offering from the metadata service" do
        expect(ohai_data['cloudstack']['service_offering']).to eq("2vCPU, 1GHz, 2GB RAM")
      end
     it "reads the public ipv4 from the metadata service" do
        expect(ohai_data['cloudstack']['router_ipv4']).to eq("10.235.34.23")
      end
     it "reads the vm id from the metadata service" do
        expect(ohai_data['cloudstack']['vm_id']).to eq("8983fb85-fb7f-46d6-8af1-c1b6666fec39")
      end
     it "reads the cloud identifier from the metadata service" do
        expect(ohai_data['cloudstack']['cloud_identifier']).to eq("CloudStack-{e84ff39d-ef64-4812-a8a9-7932f7b67f17}")
      end
     it "reads the instance id from the metadata service" do
        expect(ohai_data['cloudstack']['instance_id']).to eq("8983fb85-fb7f-46d6-8af1-c1b6666fec39")
      end
    end
  end
end

