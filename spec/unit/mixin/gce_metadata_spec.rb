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
require "ohai/mixin/gce_metadata"

describe Ohai::Mixin::GCEMetadata do
  let(:mixin) do
    Object.new.tap do |o|
      o.extend(described_class)
      o.define_singleton_method(:logger) { Ohai::Log }
      o.define_singleton_method(:sleep) { |_seconds| nil }
    end
  end

  def response(code, body = "")
    double("Net::HTTP Response", code: code, body: body)
  end

  it "uses the metadata server's link-local address, not its DNS name" do
    expect(Ohai::Mixin::GCEMetadata::GCE_METADATA_ADDR).to eq("169.254.169.254")
  end

  describe "#fetch_metadata" do
    it "retries a 503 and returns the metadata" do
      allow(mixin).to receive(:http_get).with("/computeMetadata/v1/?recursive=true")
        .and_return(response("503"), response("200", '{"instance":{"hostname":"test-host"}}'))
      expect(mixin.fetch_metadata).to eq("instance" => { "hostname" => "test-host" })
    end

    it "gives up after three attempts" do
      expect(mixin).to receive(:http_get).exactly(3).times.and_return(response("503"))
      expect(mixin.fetch_metadata).to be_nil
    end

    it "doesn't retry other errors" do
      expect(mixin).to receive(:http_get).once.and_return(response("404"))
      expect(mixin.fetch_metadata).to be_nil
    end
  end
end
