#
# Author:: ETiV Wang <et@xde.com>
# Copyright:: Copyright (c) Chef Software Inc.
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
require "ohai/mixin/alibaba_metadata"

describe Ohai::Mixin::AlibabaMetadata do
  let(:mixin) do
    metadata_object = Object.new.extend(described_class)
    conn = double("Net::HTTP client")
    allow(conn).to receive(:get).and_return(response)
    allow(metadata_object).to receive(:http_get).and_return(conn.get)
    metadata_object
  end

  before do
    logger = instance_double("Mixlib::Log::Child", trace: nil, debug: nil, warn: nil)
    allow(mixin).to receive(:logger).and_return(logger)
  end

  JSON_STR = %{{"zone-id":"cn-shanghai-a","region-id":"cn-shanghai","private-ipv4":"192.168.0.200","instance-type":"ecs.4xlarge"}}.freeze
  CONF_STR = %{#cloud-config

# system wide
timezone: Asia/Shanghai
locale: en_US.UTF-8
manage_etc_hosts: localhost

## apt & packages
apt:
  disable_suites: [proposed, $RELEASE-proposed-updates]
package_update: true
package_upgrade: true
packages:
  - htop
  - lvm2
  - tmux
  - dnsutils
  - net-tools
  - rsync
  - ca-certificates
  - curl
}.freeze

  def compare_tree(local, remote, need_sanitize = false)
    local.all? do |k, v|
      key = k
      key = mixin.sanitize_key(k) if !!need_sanitize

      if v.class == Hash
        return compare_tree(v, remote[key], need_sanitize)
      else
        return v == remote[key]
      end
    end
  end

  describe "#fetch_metadata" do
    context "when get a non-200 status code" do
      let(:response) { double("Net::HTTP Response", code: "404") }

      it "should get nil" do
        expect(mixin.fetch_metadata).to eq(nil)
      end
    end

    context "when get a plain text content without new-line" do
      let(:response) { double("Net::HTTP Response", body: "bar", code: "200") }

      it "should be its original content" do
        expect(mixin.fetch_metadata("foo", false)).to eq("bar")
      end
    end

    context "when get a plain text content with a new-line" do
      let(:response) { double("Net::HTTP Response", body: "bar\nbaz", code: "200") }

      it "should be its original content" do
        expect(mixin.fetch_metadata("foo", false)).to eq("bar\nbaz")
      end
    end

    context "when get a JSON response" do
      let(:response) { double("Net::HTTP Response", body: JSON_STR, code: "200") }

      it "should be parsed" do
        ret = mixin.fetch_metadata("foo", false)

        parser = FFI_Yajl::Parser.new
        json_obj = parser.parse(JSON_STR)

        expect(compare_tree(json_obj, ret, false)).to eq(true)
      end
    end

    api_tree = {
      "meta-data" => {
        # plain K-V
        "a" => "b",
        # nested structure
        "c" => {
          "d" => "e",
        },
        # has a new-line but not nested
        "dns-conf" => "1.1.1.1\n1.0.0.1",
        "eipv4" => nil,
        "private_ipv4" => "192.168.2.1",
        "hostname" => "some-host.example.com",
      },
      "json-data" => {
        "dynamic" => JSON_STR,
      },
      "user-data" => CONF_STR,
    }

    context "when recursively fetching a tree structure from root" do
      let(:response) { double("Net::HTTP Response", body: "", code: "200") }

      it "should be a nested structure" do
        allow(mixin).to receive(:http_get) do |uri|
          tree = api_tree

          uri.split("/").each do |part|
            tree = tree[part] unless part == ""
          end

          output = [tree]
          if tree.class == Hash
            output = tree.keys.map do |key|
              ret = key
              ret += "/" if tree[key].class == Hash
              ret
            end
          end

          double("Net::HTTP Response", body: output.join("\n"), code: "200")
        end

        ret = mixin.fetch_metadata

        expect(compare_tree(api_tree, ret, true)).to eq(true)
      end
    end

    context "when fetching config from meta-data API" do
      let(:response) { double("Net::HTTP Response", body: "", code: "200") }

      it "should be accessible directly without 'meta_data' level" do
        allow(mixin).to receive(:http_get) do |uri|
          tree = api_tree["meta-data"]

          uri.split("/").each do |part|
            tree = tree[part] unless part == ""
          end

          output = [tree]
          if tree.class == Hash
            output = tree.keys.map do |key|
              ret = key
              ret += "/" if tree[key].class == Hash
              ret
            end
          end

          double("Net::HTTP Response", body: output.join("\n"), code: "200")
        end

        ret = mixin.fetch_metadata

        expect(ret["meta_data"]).to eq(nil)

        expect(ret["eipv4"]).to eq(nil)
        expect(ret["private_ipv4"]).to eq(api_tree["meta-data"]["private_ipv4"])
        expect(ret["hostname"]).to eq(api_tree["meta-data"]["hostname"])

        expect(compare_tree(api_tree["meta-data"], ret, true)).to eq(true)
      end
    end

  end
end

