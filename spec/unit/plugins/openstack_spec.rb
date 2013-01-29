#
# Author:: Matt Ray (<matt@opscode.com>)
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
require 'open-uri'

describe Ohai::System, "plugin openstack" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai.stub!(:require_plugin).and_return(true)
  end

  shared_examples_for "!openstack" do
    it "should NOT attempt to fetch the openstack metadata" do
      OpenURI.should_not_receive(:open)
      @ohai._require_plugin("openstack")
    end
  end

  shared_examples_for "openstack" do
    before(:each) do
      @http_client = mock("Net::HTTP client")
      @ohai.stub!(:http_client).and_return(@http_client)

      @http_client.should_receive(:get).
        with("/latest/meta-data/").
        and_return(mock("Net::HTTP Response", :body => "instance_type\ninstance_id\nsecurity-groups"))
      @http_client.should_receive(:get).
        with("/latest/meta-data/instance_type").
        and_return(mock("Net::HTTP Response", :body => "standard.xsmall"))
      @http_client.should_receive(:get).
        with("/latest/meta-data/instance_id").
        and_return(mock("Net::HTTP Response", :body => "i-000b66df"))
      @http_client.should_receive(:get).
        with("/latest/meta-data/security-groups").
        and_return(mock("Net::HTTP Response", :body => "group1\ngroup2"))
    end

    it "should recursively fetch all the openstack metadata" do
      IO.stub!(:select).and_return([[],[1],[]])
      t = mock("connection")
      t.stub!(:connect_nonblock).and_raise(Errno::EINPROGRESS)
      Socket.stub!(:new).and_return(t)

      @ohai._require_plugin("openstack")
      @ohai[:openstack].should_not be_nil
      @ohai[:openstack]['instance_type'].should == "standard.xsmall"
      @ohai[:openstack]['instance_id'].should == "i-000b66df"
      @ohai[:openstack]['security_groups'].should eql ['group1', 'group2']
    end
  end

  describe "with openstack cloud file" do
    it_should_behave_like "openstack"

    before(:each) do
      File.stub!(:exist?).with('/etc/chef/ohai/hints/openstack.json').and_return(true)
      File.stub!(:read).with('/etc/chef/ohai/hints/openstack.json').and_return('')
    end
  end

  describe "without cloud file" do
    it_should_behave_like "!openstack"

    before(:each) do
      File.stub!(:exist?).with('/etc/chef/ohai/hints/openstack.json').and_return(false)
    end
  end

end
