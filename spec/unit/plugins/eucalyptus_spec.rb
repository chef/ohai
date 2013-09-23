#
# Author:: Tim Dysinger (<tim@dysinger.net>)
# Author:: Christopher Brown (cb@opscode.com)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require 'open-uri'

describe Ohai::System, "plugin eucalyptus" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai.stub!(:require_plugin).and_return(true)
  end

  shared_examples_for "!eucalyptus" do
    it "should NOT attempt to fetch the eucalyptus metadata" do
      OpenURI.should_not_receive(:open)
      @ohai._require_plugin("eucalyptus")
    end
  end

  shared_examples_for "eucalyptus" do
    before(:each) do
      @http_client = mock("Net::HTTP client")
      @ohai.stub!(:http_client).and_return(@http_client)

      @http_client.should_receive(:get).
        with("/").twice.
        and_return(mock("Net::HTTP Response", :body => "2012-01-12", :code => "200"))
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/").
        and_return(mock("Net::HTTP Response", :body => "instance_type\nami_id\nsecurity-groups", :code => "200"))
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/instance_type").
        and_return(mock("Net::HTTP Response", :body => "c1.medium", :code => "200"))
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/ami_id").
        and_return(mock("Net::HTTP Response", :body => "ami-5d2dc934", :code => "200"))
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/security-groups").
        and_return(mock("Net::HTTP Response", :body => "group1\ngroup2", :code => "200"))
      @http_client.should_receive(:get).
        with("/2012-01-12/user-data/").
        and_return(mock("Net::HTTP Response", :body => "By the pricking of my thumb...", :code => "200"))
    end

    it "should recursively fetch all the eucalyptus metadata" do
      IO.stub!(:select).and_return([[],[1],[]])
      t = mock("connection")
      t.stub!(:connect_nonblock).and_raise(Errno::EINPROGRESS)
      Socket.stub!(:new).and_return(t)
      @ohai._require_plugin("eucalyptus")
      @ohai[:eucalyptus].should_not be_nil
      @ohai[:eucalyptus]['instance_type'].should == "c1.medium"
      @ohai[:eucalyptus]['ami_id'].should == "ami-5d2dc934"
      @ohai[:eucalyptus]['security_groups'].should eql ['group1', 'group2']
    end
  end

  describe "with eucalyptus mac and metadata address connected" do
    it_should_behave_like "eucalyptus"

    before(:each) do
      IO.stub!(:select).and_return([[],[1],[]])
      @ohai[:network] = { "interfaces" => { "eth0" => { "addresses" => { "d0:0d:95:47:6E:ED"=> { "family" => "lladdr" } } } } }
    end
  end

  describe "without eucalyptus mac and metadata address connected" do
    it_should_behave_like "!eucalyptus"

    before(:each) do
      @ohai[:network] = { "interfaces" => { "eth0" => { "addresses" => { "ff:ff:95:47:6E:ED"=> { "family" => "lladdr" } } } } }
    end
  end

  describe "with eucalyptus cloud file" do
    it_should_behave_like "eucalyptus"

    before(:each) do
      File.stub!(:exist?).with('/etc/chef/ohai/hints/eucalyptus.json').and_return(true)
      File.stub!(:read).with('/etc/chef/ohai/hints/eucalyptus.json').and_return('')
      File.stub!(:exist?).with('C:\chef\ohai\hints/eucalyptus.json').and_return(true)
      File.stub!(:read).with('C:\chef\ohai\hints/eucalyptus.json').and_return('')
    end
  end

  describe "without cloud file" do
    it_should_behave_like "!eucalyptus"

    before(:each) do
      File.stub!(:exist?).with('/etc/chef/ohai/hints/eucalyptus.json').and_return(false)
      File.stub!(:exist?).with('C:\chef\ohai\hints/eucalyptus.json').and_return(false)
    end
  end

  describe "with ec2 cloud file" do
    it_should_behave_like "!eucalyptus"

    before(:each) do
      File.stub!(:exist?).with('/etc/chef/ohai/hints/ec2.json').and_return(true)
      File.stub!(:read).with('/etc/chef/ohai/hints/ec2.json').and_return('')
      File.stub!(:exist?).with('C:\chef\ohai\hints/ec2.json').and_return(true)
      File.stub!(:read).with('C:\chef\ohai\hints/ec2.json').and_return('')
    end
  end

end
