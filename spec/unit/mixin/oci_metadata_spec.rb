# frozen_string_literal: true

#
# Author:: Renato Covarrubias <rnt@rnt.cl>
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
require "ohai/mixin/oci_metadata"

describe Ohai::Mixin::OCIMetadata do
  let(:mixin) do
    mixin = Object.new.extend(Ohai::Mixin::OCIMetadata)
    mixin
  end

  before do
    logger = instance_double("Mixlib::Log::Child", trace: nil, debug: nil, warn: nil)
    allow(mixin).to receive(:logger).and_return(logger)
  end

  describe "#http_get" do
    it "gets the passed URI" do
      http_mock = double("http")
      allow(http_mock).to receive(:read_timeout=)
      allow(Net::HTTP).to receive(:start).with(Ohai::Mixin::OCIMetadata::OCI_METADATA_ADDR).and_return(http_mock)

      expect(http_mock).to receive(:get).with(Ohai::Mixin::OCIMetadata::OCI_METADATA_ADDR,
                                              { "Authorization" => "Bearer Oracle",
                                                "User-Agent" => "chef-ohai/#{Ohai::VERSION}" })
      mixin.http_get(Ohai::Mixin::OCIMetadata::OCI_METADATA_ADDR)
    end
  end

  describe "#fetch_metadata" do
    it "returns an empty hash given a non-200 response" do
      http_mock = double("http", { code: "404" })
      allow(mixin).to receive(:http_get).and_return(http_mock)

      expect(mixin.logger).not_to receive(:warn)
      vals = mixin.fetch_metadata
      expect(vals).to eq(nil)
    end

    it "returns a populated hash given valid JSON response" do
      http_mock = double("http", { code: "200", body: '{ "foo": "bar"}' })
      allow(mixin).to receive(:http_get).and_return(http_mock)

      expect(mixin.logger).not_to receive(:warn)
      vals = mixin.fetch_metadata
      expect(vals).to eq({ "foo" => "bar" })
    end
  end
end
