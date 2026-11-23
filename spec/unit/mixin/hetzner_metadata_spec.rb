# frozen_string_literal: true
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
require "ohai/mixin/hetzner_metadata"

describe Ohai::Mixin::HetznerMetadata do
  let(:http_client) { double("Net::HTTP") }
  let(:mixin) do
    Object.new.tap do |o|
      o.extend(described_class)
      o.define_singleton_method(:logger) { Ohai::Log }
    end
  end

  # the shape of a real response; the values are made up
  let(:metadata_yaml) do
    <<~YAML
      availability-zone: fsn1-dc14
      hostname: web-1
      instance-id: 4242
      local-ipv4: ''
      network-config:
        config:
        - mac_address: 96:00:00:00:00:01
          name: eth0
          subnets:
          - ipv4: true
            type: dhcp
          - address: 2001:db8:1:2::1/64
            gateway: fe80::1
            ipv6: true
            type: static
          type: physical
        version: 1
      network-sysconfig: "DEVICE='eth0'\\nONBOOT='yes'\\n"
      public-ipv4: 203.0.113.10
      public-keys:
      - ssh-ed25519 AAAAexample user@example
      region: eu-central
      vendor_data: "#cloud-config\\nruncmd: [echo secret]\\n"
    YAML
  end

  let(:private_networks_yaml) do
    <<~YAML
      - ip: 10.0.0.2
        alias_ips: [10.0.0.3]
        interface_num: 1
        mac_address: 86:00:00:00:00:02
        network_id: 7
        network_name: backend
        network: 10.0.0.0/16
        subnet: 10.0.0.0/24
        gateway: 10.0.0.1
    YAML
  end

  def response(code, body = "")
    double("Net::HTTP Response", code: code, body: body)
  end

  before do
    allow(mixin).to receive(:http_client).and_return(http_client)
  end

  describe "#fetch_metadata" do
    before do
      allow(http_client).to receive(:get).with("/hetzner/v1/metadata").and_return(response("200", metadata_yaml))
      allow(http_client).to receive(:get).with("/hetzner/v1/metadata/private-networks").and_return(response("200", private_networks_yaml))
    end

    it "parses the metadata with underscored keys" do
      metadata = mixin.fetch_metadata
      expect(metadata["instance_id"]).to eq(4242)
      expect(metadata["hostname"]).to eq("web-1")
      expect(metadata["public_ipv4"]).to eq("203.0.113.10")
      expect(metadata["availability_zone"]).to eq("fsn1-dc14")
      expect(metadata["region"]).to eq("eu-central")
      expect(metadata["network_config"]["config"][0]["subnets"][1]["address"]).to eq("2001:db8:1:2::1/64")
    end

    it "includes the private networks" do
      expect(mixin.fetch_metadata["private_networks"]).to eq([{
        "ip" => "10.0.0.2", "alias_ips" => ["10.0.0.3"], "interface_num" => 1, "mac_address" => "86:00:00:00:00:02",
        "network_id" => 7, "network_name" => "backend", "network" => "10.0.0.0/16", "subnet" => "10.0.0.0/24", "gateway" => "10.0.0.1"
      }])
    end

    it "doesn't keep vendor data or the redundant sysconfig network config" do
      metadata = mixin.fetch_metadata
      expect(metadata.keys).not_to include("vendor_data", "network_sysconfig", "network-sysconfig")
    end

    it "never requests user data" do
      expect(http_client).not_to receive(:get).with(/userdata/)
      mixin.fetch_metadata
    end

    it "returns an empty private network list when that request fails" do
      allow(http_client).to receive(:get).with("/hetzner/v1/metadata/private-networks").and_return(response("500"))
      expect(mixin.fetch_metadata["private_networks"]).to eq([])
    end
  end

  describe "#fetch_yaml" do
    it "returns nil for a non-200 response" do
      allow(http_client).to receive(:get).and_return(response("404"))
      expect(mixin.fetch_yaml("/hetzner/v1/metadata")).to be_nil
    end

    it "returns nil for invalid YAML" do
      allow(http_client).to receive(:get).and_return(response("200", "key: [unterminated"))
      expect(mixin.fetch_yaml("/hetzner/v1/metadata")).to be_nil
    end

    it "refuses YAML that would build arbitrary objects" do
      allow(http_client).to receive(:get).and_return(response("200", "--- !ruby/object:OpenStruct\nfoo: bar\n"))
      expect(mixin.fetch_yaml("/hetzner/v1/metadata")).to be_nil
    end
  end
end
