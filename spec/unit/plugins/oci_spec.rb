# frozen_string_literal: true

#
# Contributed by: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright © 2008-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
begin
  require "win32/registry" unless defined?(Win32::Registry)
rescue LoadError => e
  puts "Skipping missing rake dep: #{e}"
end

describe Ohai::System, "plugin oci" do
  let(:plugin) { get_plugin("oci") }
  let(:hint) do
    {
      "local_hostname" => "test-vm",
      "provider" => "oci",
    }
  end

  let(:response_data) do
    {
      "compute" => {
        "availabilityDomain" => "EMIr:PHX-AD-1",
        "faultDomain" => "FAULT-DOMAIN-3",
        "compartmentId" => "ocid1.tenancy.oc1..exampleuniqueID",
        "displayName" => "my-example-instance",
        "hostname" => "my-hostname",
        "id" => "ocid1.instance.oc1.phx.exampleuniqueID",
        "image" => "ocid1.image.oc1.phx.exampleuniqueID",
        "metadata" => {
          "ssh_authorized_keys" => "example-ssh-key",
        },
        "region" => "phx",
        "canonicalRegionName" => "us-phoenix-1",
        "ociAdName" => "phx-ad-1",
        "regionInfo" => {
          "realmKey" => "oc1",
          "realmDomainComponent" => "oraclecloud.com",
          "regionKey" => "PHX",
          "regionIdentifier" => "us-phoenix-1",
        },
        "shape" => "VM.Standard.E3.Flex",
        "state" => "Running",
        "timeCreated" => 1_600_381_928_581,
        "agentConfig" => {
          "monitoringDisabled" => false,
          "managementDisabled" => false,
          "allPluginsDisabled" => false,
          "pluginsConfig" => [
            { "name" => "OS Management Service Agent", "desiredState" => "ENABLED" },
            { "name" => "Custom Logs Monitoring", "desiredState" => "ENABLED" },
            { "name" => "Compute Instance Run Command", "desiredState" => "ENABLED" },
            { "name" => "Compute Instance Monitoring", "desiredState" => "ENABLED" },
          ],
        },
        "freeformTags" => {
          "Department" => "Finance",
        },
        "definedTags" => {
          "Operations" => {
            "CostCenter" => "42",
          },
        },
      },
      "network" => {
        "interface" => [
          { "vnicId" => "ocid1.vnic.oc1.phx.exampleuniqueID", "privateIp" => "10.0.3.6", "vlanTag" => 11,
            "macAddr" => "00:00:00:00:00:01", "virtualRouterIp" => "10.0.3.1", "subnetCidrBlock" => "10.0.3.0/24",
            "nicIndex" => 0 },
          { "vnicId" => "ocid1.vnic.oc1.phx.exampleuniqueID", "privateIp" => "10.0.4.3", "vlanTag" => 12,
            "macAddr" => "00:00:00:00:00:02", "virtualRouterIp" => "10.0.4.1", "subnetCidrBlock" => "10.0.4.0/24",
            "nicIndex" => 0 },
        ],
      },
    }
  end

  before do
    # skips all the metadata logic unless we want to test it
    allow(plugin).to receive(:can_socket_connect?)
      .with(Ohai::Mixin::OCIMetadata::OCI_METADATA_ADDR, 80)
      .and_return(false)
  end

  shared_examples_for "!oci" do
    it "does not set the oci attribute" do
      plugin.run
      expect(plugin[:oci]).to be_nil
    end
  end

  shared_examples_for "oci" do
    it "sets the oci attribute" do
      plugin.run
      expect(plugin[:oci]).to be_truthy
      expect(plugin[:oci]).to have_key(:metadata)
    end
  end

  describe "with oci hint file" do
    before do
      allow(plugin).to receive(:hint?).with("oci").and_return(hint)
    end

    it "sets the oci cloud attributes" do
      plugin.run
      expect(plugin[:oci]["provider"]).to eq("oci")
      expect(plugin[:oci]["local_hostname"]).to eq("test-vm")
    end
  end

  describe "without oci hint file not in OCI" do
    before do
      allow(plugin).to receive(:hint?).with("oci").and_return(false)
      allow(plugin).to receive(:file_exist?).with(Ohai::Mixin::OCIMetadata::CHASSIS_ASSET_TAG_FILE).and_return(true)
      @double_file = double(Ohai::Mixin::OCIMetadata::CHASSIS_ASSET_TAG_FILE)
      allow(@double_file).to receive(:each)
        .and_yield("")
      allow(plugin).to receive(:file_open).with(Ohai::Mixin::OCIMetadata::CHASSIS_ASSET_TAG_FILE).and_return(@double_file)
    end

    it_behaves_like "!oci"
  end

  describe "without oci hint file in OCI" do
    before do
      allow(plugin).to receive(:hint?).with("oci").and_return(false)
      allow(plugin).to receive(:file_exist?).with(Ohai::Mixin::OCIMetadata::CHASSIS_ASSET_TAG_FILE).and_return(true)
      @double_file = double(Ohai::Mixin::OCIMetadata::CHASSIS_ASSET_TAG_FILE)
      allow(@double_file).to receive(:each)
        .and_yield("OracleCloud.com")
      allow(plugin).to receive(:file_open).with(Ohai::Mixin::OCIMetadata::CHASSIS_ASSET_TAG_FILE).and_return(@double_file)
    end

    it_behaves_like "oci"
  end

  describe "with non-responsive metadata endpoint" do
    before do
      allow(plugin).to receive(:hint?).with("oci").and_return({})
    end

    it "does not return metadata information" do
      allow(plugin).to receive(:can_socket_connect?)
        .with(Ohai::Mixin::OCIMetadata::OCI_METADATA_ADDR, 80)
        .and_return(true)
      allow(plugin).to receive(:parse_metadata).and_return(nil)

      plugin.run
      expect(plugin[:oci]).to have_key(:metadata)
      expect(plugin[:oci][:metadata]).to be_nil
    end
  end

  describe "with responsive metadata endpoint" do
    before do
      allow(plugin).to receive(:hint?).with("oci").and_return({})
      allow(plugin).to receive(:can_socket_connect?)
        .with(Ohai::Mixin::OCIMetadata::OCI_METADATA_ADDR, 80)
        .and_return(true)
      allow(plugin).to receive(:parse_metadata).and_return(response_data)
      plugin.run
    end

    it "returns metadata compute information" do
      expect(plugin[:oci][:metadata][:compute][:availabilityDomain]).to eq("EMIr:PHX-AD-1")
      expect(plugin[:oci][:metadata][:compute][:compartmentId]).to eq("ocid1.tenancy.oc1..exampleuniqueID")
      expect(plugin[:oci][:metadata][:compute][:faultDomain]).to eq("FAULT-DOMAIN-3")
      expect(plugin[:oci][:metadata][:compute][:hostname]).to eq("my-hostname")
      expect(plugin[:oci][:metadata][:compute][:image]).to eq("ocid1.image.oc1.phx.exampleuniqueID")
      expect(plugin[:oci][:metadata][:compute][:region]).to eq("phx")
      expect(plugin[:oci][:metadata][:compute][:shape]).to eq("VM.Standard.E3.Flex")
      expect(plugin[:oci][:metadata][:compute][:state]).to eq("Running")
    end

    it "returns metadata network information" do
      expect(plugin[:oci][:metadata][:network][:interface][0][:macAddr]).to eq("00:00:00:00:00:01")
      expect(plugin[:oci][:metadata][:network][:interface][0][:privateIp]).to eq("10.0.3.6")
    end
  end
end
