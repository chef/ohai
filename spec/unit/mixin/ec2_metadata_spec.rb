#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require 'ohai/mixin/ec2_metadata'

describe Ohai::Mixin::Ec2Metadata do
  let(:mixin) {
    metadata_object = Object.new.extend(Ohai::Mixin::Ec2Metadata)
    http_client = mock("Net::HTTP client")
    http_client.stub!(:get).and_return(response)
    metadata_object.stub!(:http_client).and_return(http_client)
    metadata_object
  }

  context "#best_api_version" do
    context "with a sorted list of metadata versions" do
      let(:response) { mock("Net::HTTP Response", :body => "1.0\n2011-05-01\n2012-01-12\nUnsupported", :code => "200") }

      it "returns the most recent version" do
        mixin.best_api_version.should == "2012-01-12"
      end
    end

    context "with an unsorted list of metadata versions" do
      let(:response) { mock("Net::HTTP Response", :body => "1.0\n2009-04-04\n2007-03-01\n2011-05-01\n2008-09-01\nUnsupported", :code => "200") }

      it "returns the most recent version (using string sort)" do
        mixin.best_api_version.should == "2011-05-01"
      end
    end

    context "when no supported versions are found" do
      let(:response) { mock("Net::HTTP Response", :body => "2020-01-01\nUnsupported", :code => "200") }

      it "raises an error" do
        lambda { mixin.best_api_version}.should raise_error
      end
    end

    context "when the response code is 404" do
      let(:response) { mock("Net::HTTP Response", :body => "1.0\n2011-05-01\n2012-01-12\nUnsupported", :code => "404") }

      it "raises an error" do
        lambda { mixin.best_api_version}.should raise_error
      end
    end

    context "when the response code is unexpected" do
      let(:response) { mock("Net::HTTP Response", :body => "1.0\n2011-05-01\n2012-01-12\nUnsupported", :code => "418") }

      it "raises an error" do
        lambda { mixin.best_api_version}.should raise_error
      end
    end
  end

  context "#metadata_get" do
    context "when the response code is unexpected" do
      let(:response) { mock("Net::HTTP Response", :body => "", :code => "418") }

      it "raises an error" do
        lambda { mixin.metadata_get('', '2012-01-12') }.should raise_error(RuntimeError)
      end
    end
  end
end
