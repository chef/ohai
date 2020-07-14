# frozen_string_literal: true
#
# Author:: Tim Smith <tsmith@chef.io>
# Copyright:: 2017-2020 Chef Software, Inc.
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
require "ohai/mixin/azure_metadata"

describe Ohai::Mixin::AzureMetadata do
  let(:mixin) do
    mixin = Object.new.extend(::Ohai::Mixin::AzureMetadata)
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
      allow(Net::HTTP).to receive(:start).with("169.254.169.254").and_return(http_mock)

      expect(http_mock).to receive(:get).with("http://www.chef.io", { "Metadata" => "true" })
      mixin.http_get("http://www.chef.io")
    end
  end

  describe "#best_api_version" do
    before do
      allow(mixin).to receive(:http_get).and_return(response)
    end

    context "when azure returns versions we know about" do
      let(:response) { double("Net::HTTP Response", body: "{\"error\":\"Bad request. api-version was not specified in the request. For more information refer to aka.ms/azureimds\",\"newest-versions\":[\"2019-08-15\",\"2019-08-01\",\"2019-07-15\"]}", code: "400") }

      it "returns the most recent version" do
        expect(mixin.best_api_version).to eq("2019-08-15")
      end
    end

    context "when azure doesn't return any versions we know about" do
      let(:response) { double("Net::HTTP Response", body: "{\"error\":\"Bad request. api-version was not specified in the request. For more information refer to aka.ms/azureimds\",\"newest-versions\":[\"2021-01-02\",\"2020-08-01\",\"2020-07-15\"]}", code: "400") }

      it "returns the most recent version we know of" do
        expect(mixin.best_api_version).to eq("2019-11-01")
      end
    end

    context "when the response code is 404" do
      let(:response) { double("Net::HTTP Response", code: "404") }

      it "returns the most recent version we know of" do
        expect(mixin.best_api_version).to eq("2019-11-01")
      end
    end

    context "when the response code is unexpected" do
      let(:response) { double("Net::HTTP Response", body: "{\"error\":\"Bad request. api-version was not specified in the request. For more information refer to aka.ms/azureimds\",\"newest-versions\":[\"2021-01-02\",\"2020-08-01\",\"2020-07-15\"]}", code: "418") }

      it "raises an error" do
        expect { mixin.best_api_version }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#fetch_metadata" do
    before do
      allow(mixin).to receive(:best_api_version).and_return("2019-11-01")
    end

    it "returns an empty hash given a non-200 response" do
      http_mock = double("http", { code: "500" })
      allow(mixin).to receive(:http_get).and_return(http_mock)

      expect(mixin.logger).to receive(:warn)
      vals = mixin.fetch_metadata
      expect(vals).to eq(nil)
    end

    it "returns an empty hash given invalid JSON response" do
      http_mock = double("http", { code: "200", body: '{ "foo" "bar"}' })
      allow(mixin).to receive(:http_get).and_return(http_mock)

      expect(mixin.logger).to receive(:warn)
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
