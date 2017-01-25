#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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

require_relative "../../spec_helper.rb"
require "ohai/mixin/ec2_metadata"

describe Ohai::Mixin::Ec2Metadata do
  let(:mixin) do
    metadata_object = Object.new.extend(Ohai::Mixin::Ec2Metadata)
    http_client = double("Net::HTTP client")
    allow(http_client).to receive(:get).and_return(response)
    allow(metadata_object).to receive(:http_client).and_return(http_client)
    metadata_object
  end

  context "#best_api_version" do
    context "with a sorted list of metadata versions" do
      let(:response) { double("Net::HTTP Response", :body => "1.0\n2011-05-01\n2012-01-12\nUnsupported", :code => "200") }

      it "returns the most recent version" do
        expect(mixin.best_api_version).to eq("2012-01-12")
      end
    end

    context "with an unsorted list of metadata versions" do
      let(:response) { double("Net::HTTP Response", :body => "1.0\n2009-04-04\n2007-03-01\n2011-05-01\n2008-09-01\nUnsupported", :code => "200") }

      it "returns the most recent version (using string sort)" do
        expect(mixin.best_api_version).to eq("2011-05-01")
      end
    end

    context "when no supported versions are found" do
      let(:response) { double("Net::HTTP Response", :body => "2020-01-01\nUnsupported", :code => "200") }

      it "raises an error" do
        expect { mixin.best_api_version }.to raise_error(RuntimeError)
      end
    end

    # Presume 'latest' when we get a 404 for Eucalyptus back-compat
    context "when the response code is 404" do
      let(:response) { double("Net::HTTP Response", :code => "404") }

      it "returns 'latest' as the version" do
        expect(mixin.best_api_version).to eq("latest")
      end
    end

    context "when the response code is unexpected" do
      let(:response) { double("Net::HTTP Response", :body => "1.0\n2011-05-01\n2012-01-12\nUnsupported", :code => "418") }

      it "raises an error" do
        expect { mixin.best_api_version }.to raise_error(RuntimeError)
      end
    end
  end

  context "#metadata_get" do
    context "when the response code is unexpected" do
      let(:response) { double("Net::HTTP Response", :body => "", :code => "418") }

      it "raises an error" do
        expect { mixin.metadata_get("", "2012-01-12") }.to raise_error(RuntimeError)
      end
    end
  end
end
