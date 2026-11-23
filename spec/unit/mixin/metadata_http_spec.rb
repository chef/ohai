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
require "ohai/mixin/ec2_metadata"
require "ohai/mixin/alibaba_metadata"
require "ohai/mixin/azure_metadata"
require "ohai/mixin/gce_metadata"
require "ohai/mixin/oci_metadata"
require "ohai/mixin/do_metadata"
require "ohai/mixin/scaleway_metadata"

# Link-local metadata services must be reached directly. Net::HTTP.start uses
# http_proxy from the environment unless it is given an explicit nil proxy
# address, and Chef exports its proxy settings to the environment.
describe "metadata HTTP clients" do
  let(:conn) { double("Net::HTTP", :read_timeout= => nil, :keep_alive_timeout= => nil, get: nil) }

  around do |example|
    saved = ENV.to_h.slice("http_proxy", "HTTP_PROXY")
    ENV["http_proxy"] = ENV["HTTP_PROXY"] = "http://proxy.example.com:3128"
    example.run
  ensure
    ENV.delete("http_proxy")
    ENV.delete("HTTP_PROXY")
    ENV.update(saved)
  end

  {
    Ohai::Mixin::Ec2Metadata => [Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR, :http_client],
    Ohai::Mixin::AlibabaMetadata => [Ohai::Mixin::AlibabaMetadata::ALI_METADATA_ADDR, :http_get, ""],
    Ohai::Mixin::AzureMetadata => [Ohai::Mixin::AzureMetadata::AZURE_METADATA_ADDR, :http_get, "/metadata/instance"],
    Ohai::Mixin::GCEMetadata => [Ohai::Mixin::GCEMetadata::GCE_METADATA_ADDR, :http_get, "/computeMetadata/v1/"],
    Ohai::Mixin::OCIMetadata => [Ohai::Mixin::OCIMetadata::OCI_METADATA_ADDR, :http_get, "/opc/v2/instance"],
    Ohai::Mixin::DOMetadata => [Ohai::Mixin::DOMetadata::DO_METADATA_ADDR, :http_client],
    Ohai::Mixin::ScalewayMetadata => [Ohai::Mixin::ScalewayMetadata::SCALEWAY_METADATA_ADDR, :http_client],
  }.each do |mixin_module, (addr, method, *args)|
    it "#{mixin_module.name.split("::").last} connects to #{addr} without a proxy and with a connect timeout" do
      mixin = Object.new.extend(mixin_module)
      expect(Net::HTTP).to receive(:start).with(addr, 80, nil, open_timeout: 3).and_return(conn)
      mixin.public_send(method, *args)
    end
  end
end
