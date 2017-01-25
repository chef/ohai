#
# Author:: Alexey Karpik <alexey.karpik@rightscale.com>
# Author:: Peter Schroeter <peter.schroeter@rightscale.com>
# Author:: Stas Turlo <stanislav.turlo@rightscale.com>
# Copyright:: Copyright (c) 2010-2014 RightScale Inc
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative "../../spec_helper.rb"
require "ohai/mixin/softlayer_metadata"

describe ::Ohai::Mixin::SoftlayerMetadata do

  let(:mixin) do
    mixin = Object.new.extend(::Ohai::Mixin::SoftlayerMetadata)
    mixin
  end

  def make_request(item)
    "/rest/v3.1/SoftLayer_Resource_Metadata/#{item}"
  end

  def make_res(body)
    double("response", { :body => body, :code => "200" })
  end

  context "fetch_metadata" do
    it "riases error if softlayer api query results with error" do
      http_mock = double("http", { :ssl_version= => true, :use_ssl= => true, :ca_file= => true })
      allow(http_mock).to receive(:get).and_raise(StandardError.new("API return fake error"))
      allow(::Net::HTTP).to receive(:new).with("api.service.softlayer.com", 443).and_return(http_mock)

      expect(::Ohai::Log).to receive(:error).at_least(:once)
      expect { mixin.fetch_metadata }.to raise_error(StandardError)
    end

    it "query api service" do
      http_mock = double("http", { :ssl_version= => true, :use_ssl= => true, :ca_file= => true })
      allow(::Net::HTTP).to receive(:new).with("api.service.softlayer.com", 443).and_return(http_mock)

      expect(http_mock).to receive(:get).with(make_request("getFullyQualifiedDomainName.txt")).and_return(make_res("abc.host.org")).once
      expect(http_mock).to receive(:get).with(make_request("getPrimaryBackendIpAddress.txt")).and_return(make_res("10.0.1.10")).once
      expect(http_mock).to receive(:get).with(make_request("getPrimaryIpAddress.txt")).and_return(make_res("8.8.8.8")).once
      expect(http_mock).to receive(:get).with(make_request("getId.txt")).and_return(make_res("1111")).once
      expect(http_mock).to receive(:get).with(make_request("getDatacenter.txt")).and_return(make_res("dal05")).once

      metadata = mixin.fetch_metadata
      expect(metadata).not_to be_nil
      expect(metadata["public_fqdn"]).to eq("abc.host.org")
      expect(metadata["local_ipv4"]).to  eq("10.0.1.10")
      expect(metadata["instance_id"]).to eq("1111")
      expect(metadata["region"]).to      eq("dal05")
      expect(metadata["public_ipv4"]).to eq("8.8.8.8")
    end
  end
end
