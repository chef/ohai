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
require "ohai/mixin/linode_metadata"

describe Ohai::Mixin::LinodeMetadata do
  let(:http_client) { double("Net::HTTP") }
  let(:mixin) do
    Object.new.tap do |o|
      o.extend(described_class)
      o.define_singleton_method(:logger) { Ohai::Log }
    end
  end

  def response(code, body = "")
    double("Net::HTTP Response", code: code, body: body)
  end

  before do
    allow(mixin).to receive(:http_client).and_return(http_client)
  end

  describe "#fetch_metadata" do
    let(:headers) { { "Metadata-Token" => "abc123", "Accept" => "application/json" } }

    before do
      allow(http_client).to receive(:put)
        .with("/v1/token", "", { "Metadata-Token-Expiry-Seconds" => "300" })
        .and_return(response("200", "abc123\n"))
    end

    it "reads the instance and network documents with the token" do
      expect(http_client).to receive(:get).with("/v1/instance", headers).and_return(response("200", '{"id":1234,"label":"web-1"}'))
      expect(http_client).to receive(:get).with("/v1/network", headers).and_return(response("200", '{"ipv4":{"public":["192.0.2.10/32"]}}'))
      expect(mixin.fetch_metadata).to eq(
        "instance" => { "id" => 1234, "label" => "web-1" },
        "network" => { "ipv4" => { "public" => ["192.0.2.10/32"] } }
      )
    end

    it "never requests user data" do
      allow(http_client).to receive(:get).and_return(response("200", "{}"))
      expect(http_client).not_to receive(:get).with(/user-data/, anything)
      mixin.fetch_metadata
    end

    it "keeps the documents it could read" do
      allow(http_client).to receive(:get).with("/v1/instance", headers).and_return(response("500"))
      allow(http_client).to receive(:get).with("/v1/network", headers).and_return(response("200", '{"ipv4":{}}'))
      expect(mixin.fetch_metadata).to eq("network" => { "ipv4" => {} })
    end

    it "skips a document that isn't JSON" do
      allow(http_client).to receive(:get).with("/v1/instance", headers).and_return(response("200", "id: 1234"))
      allow(http_client).to receive(:get).with("/v1/network", headers).and_return(response("200", "{}"))
      expect(mixin.fetch_metadata).to eq("network" => {})
    end

    it "returns nothing without a token" do
      allow(http_client).to receive(:put).and_return(response("403", "Forbidden"))
      expect(http_client).not_to receive(:get)
      expect(mixin.fetch_metadata).to eq({})
    end

    it "returns nothing when the service times out" do
      allow(http_client).to receive(:put).and_raise(Net::ReadTimeout)
      expect(mixin.fetch_metadata).to eq({})
    end
  end
end
