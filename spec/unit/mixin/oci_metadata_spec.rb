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
  let(:oracle_cloud_dot_com) { "OracleCloud.com" }

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

      expect(mixin.logger).to receive(:debug)
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

  describe "#chassis_asset_tag" do
    let(:test_asset_tag) { "test-asset_tag" }
    context "on Windows platform" do
      before do
        stub_const("RUBY_PLATFORM", "mswin")
      end

      it "calls get_chassis_asset_tag_windows" do
        expect(mixin).to receive(:get_chassis_asset_tag_windows).and_return(test_asset_tag)
        expect(mixin.chassis_asset_tag).to eq(test_asset_tag)
      end
    end

    context "on non-Windows platform" do
      before do
        stub_const("RUBY_PLATFORM", "linux")
      end

      it "calls get_chassis_asset_tag_linux" do
        expect(mixin).to receive(:get_chassis_asset_tag_linux).and_return(test_asset_tag)
        expect(mixin.chassis_asset_tag).to eq(test_asset_tag)
      end
    end
  end

  describe "#get_chassis_asset_tag_linux" do
    let(:chassis_file) { Ohai::Mixin::OCIMetadata::CHASSIS_ASSET_TAG_FILE }

    it "returns asset tag when file exists and is readable" do
      allow(::File).to receive(:exist?).with(chassis_file).and_return(true)
      allow(::File).to receive(:read).with(chassis_file).and_return("  #{oracle_cloud_dot_com}  \n")

      expect(mixin.get_chassis_asset_tag_linux).to eq(oracle_cloud_dot_com)
    end

    it "returns nil when file does not exist" do
      allow(::File).to receive(:exist?).with(chassis_file).and_return(false)

      expect(mixin.get_chassis_asset_tag_linux).to be_nil
    end

    it "returns nil when file read fails" do
      allow(::File).to receive(:exist?).with(chassis_file).and_return(true)
      allow(::File).to receive(:read).with(chassis_file).and_raise(Errno::EACCES)

      expect(mixin.logger).to receive(:debug).with(/Failed to read chassis asset tag/)
      expect(mixin.get_chassis_asset_tag_linux).to be_nil
    end
  end

  describe "#get_chassis_asset_tag_windows" do
    let(:wmi_mock) { double("WmiLite::Wmi") }
    let(:enclosure_mock) { { "SMBIOSAssetTag" => oracle_cloud_dot_com } }

    before do
      allow(mixin).to receive(:require)
      stub_const("WmiLite::Wmi", double(new: wmi_mock))
    end

    it "returns asset tag from WMI when available" do
      allow(wmi_mock).to receive(:first_of).with("Win32_SystemEnclosure").and_return(enclosure_mock)

      expect(mixin.get_chassis_asset_tag_windows).to eq(oracle_cloud_dot_com)
    end

    it "returns nil when WMI query returns nil" do
      allow(wmi_mock).to receive(:first_of).with("Win32_SystemEnclosure").and_return(nil)

      expect(mixin.get_chassis_asset_tag_windows).to be_nil
    end

    it "returns nil when WMI query fails" do
      allow(wmi_mock).to receive(:first_of).with("Win32_SystemEnclosure").and_raise(StandardError.new("WMI error"))

      expect(mixin.logger).to receive(:debug).with(/Failed to read chassis asset tag from WMI/)
      expect(mixin.get_chassis_asset_tag_windows).to be_nil
    end

    it "returns nil when SMBIOSAssetTag is not present" do
      allow(wmi_mock).to receive(:first_of).with("Win32_SystemEnclosure").and_return({})

      expect(mixin.get_chassis_asset_tag_windows).to be_nil
    end
  end
end
