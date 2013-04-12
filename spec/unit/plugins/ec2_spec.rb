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
# WITHOUT WARRANTIES OR CONDIT"Net::HTTP Response"NS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require 'open-uri'

describe Ohai::System, "plugin ec2" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai.stub!(:require_plugin).and_return(true)
    @ohai[:network] = {:interfaces => {:eth0 => {} } }
  end

  shared_examples_for "!ec2" do
    it "should NOT attempt to fetch the ec2 metadata" do
      @ohai.should_not_receive(:http_client)
      @ohai._require_plugin("ec2")
    end
  end

  shared_examples_for "ec2" do
    before(:each) do
      @http_client = mock("Net::HTTP client")
      @ohai.stub!(:http_client).and_return(@http_client)
      IO.stub!(:select).and_return([[],[1],[]])
      t = mock("connection")
      t.stub!(:connect_nonblock).and_raise(Errno::EINPROGRESS)
      Socket.stub!(:new).and_return(t)
      @http_client.should_receive(:get).
        with("/").twice.
        and_return(mock("Net::HTTP Response", :body => "2012-01-12", :code => "200"))
    end

    it "should recursively fetch all the ec2 metadata" do
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
      @ohai._require_plugin("ec2")

      @ohai[:ec2].should_not be_nil
      @ohai[:ec2]['instance_type'].should == "c1.medium"
      @ohai[:ec2]['ami_id'].should == "ami-5d2dc934"
      @ohai[:ec2]['security_groups'].should eql ['group1', 'group2']
    end

    it "should parse ec2 network/ directory as a multi-level hash" do
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/").
        and_return(mock("Net::HTTP Response", :body => "network/", :code => "200"))
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/network/").
        and_return(mock("Net::HTTP Response", :body => "interfaces/", :code => "200"))
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/network/interfaces/").
        and_return(mock("Net::HTTP Response", :body => "macs/", :code => "200"))
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/network/interfaces/macs/").
        and_return(mock("Net::HTTP Response", :body => "12:34:56:78:9a:bc/", :code => "200"))
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/network/interfaces/macs/12:34:56:78:9a:bc/").
        and_return(mock("Net::HTTP Response", :body => "public_hostname", :code => "200"))
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/network/interfaces/macs/12:34:56:78:9a:bc/public_hostname").
        and_return(mock("Net::HTTP Response", :body => "server17.opscode.com", :code => "200"))
      @ohai._require_plugin("ec2")

      @ohai[:ec2].should_not be_nil
      @ohai[:ec2]['network_interfaces_macs']['12:34:56:78:9a:bc']['public_hostname'].should eql('server17.opscode.com')
    end

    it "should parse ec2 iam/ directory and its JSON files properly" do
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/").
        and_return(mock("Net::HTTP Response", :body => "iam/", :code => "200"))
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/iam/").
        and_return(mock("Net::HTTP Response", :body => "security-credentials/", :code => "200"))
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/iam/security-credentials/").
        and_return(mock("Net::HTTP Response", :body => "MyRole", :code => "200"))
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/iam/security-credentials/MyRole").
        and_return(mock("Net::HTTP Response", :body => "{\n  \"Code\" : \"Success\",\n  \"LastUpdated\" : \"2012-08-22T07:47:22Z\",\n  \"Type\" : \"AWS-HMAC\",\n  \"AccessKeyId\" : \"AAAAAAAA\",\n  \"SecretAccessKey\" : \"SSSSSSSS\",\n  \"Token\" : \"12345678\",\n  \"Expiration\" : \"2012-08-22T11:25:52Z\"\n}", :code => "200"))
      @ohai._require_plugin("ec2")

      @ohai[:ec2].should_not be_nil
      @ohai[:ec2]['iam']['security-credentials']['MyRole']['Code'].should eql 'Success'
      @ohai[:ec2]['iam']['security-credentials']['MyRole']['Token'].should eql '12345678'
    end

    it "should ignore \"./\" and \"../\" on ec2 metadata paths to avoid infinity loops" do
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/").
        and_return(mock("Net::HTTP Response", :body => ".\n./\n..\n../\npath1/.\npath2/./\npath3/..\npath4/../", :code => "200"))

      @http_client.should_not_receive(:get).
        with("/2012-01-12/meta-data/.")
      @http_client.should_not_receive(:get).
        with("/2012-01-12/meta-data/./")
      @http_client.should_not_receive(:get).
        with("/2012-01-12/meta-data/..")
      @http_client.should_not_receive(:get).
        with("/2012-01-12/meta-data/../")
      @http_client.should_not_receive(:get).
        with("/2012-01-12/meta-data/path1/..")

      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/path1/").
        and_return(mock("Net::HTTP Response", :body => "", :code => "200"))
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/path2/").
        and_return(mock("Net::HTTP Response", :body => "", :code => "200"))
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/path3/").
        and_return(mock("Net::HTTP Response", :body => "", :code => "200"))
      @http_client.should_receive(:get).
        with("/2012-01-12/meta-data/path4/").
        and_return(mock("Net::HTTP Response", :body => "", :code => "200"))

      @ohai._require_plugin("ec2")

      @ohai[:ec2].should_not be_nil
    end
  end

  describe "with ec2 mac and metadata address connected" do
    it_should_behave_like "ec2"

    before(:each) do
      IO.stub!(:select).and_return([[],[1],[]])
      @ohai[:network][:interfaces][:eth0][:arp] = {"169.254.1.0"=>"fe:ff:ff:ff:ff:ff"}
    end
  end

  describe "without ec2 mac and metadata address connected" do
    it_should_behave_like "!ec2"

    before(:each) do
      @ohai[:network][:interfaces][:eth0][:arp] = {"169.254.1.0"=>"00:50:56:c0:00:08"}
    end
  end

  describe "with ec2 cloud file" do
    it_should_behave_like "ec2"

    before(:each) do
      File.stub!(:exist?).with('/etc/chef/ohai/hints/ec2.json').and_return(true)
      File.stub!(:read).with('/etc/chef/ohai/hints/ec2.json').and_return('')
      File.stub!(:exist?).with('C:\chef\ohai\hints/ec2.json').and_return(true)
      File.stub!(:read).with('C:\chef\ohai\hints/ec2.json').and_return('')
    end
  end

  describe "without cloud file" do
    it_should_behave_like "!ec2"

    before(:each) do
      File.stub!(:exist?).with('/etc/chef/ohai/hints/ec2.json').and_return(false)
      File.stub!(:exist?).with('C:\chef\ohai\hints/ec2.json').and_return(false)
    end
  end

  describe "with rackspace cloud file" do
    it_should_behave_like "!ec2"

    before(:each) do
      File.stub!(:exist?).with('/etc/chef/ohai/hints/rackspace.json').and_return(true)
      File.stub!(:read).with('/etc/chef/ohai/hints/rackspace.json').and_return('')
      File.stub!(:exist?).with('C:\chef\ohai\hints/rackspace.json').and_return(true)
      File.stub!(:read).with('C:\chef\ohai\hints/rackspace.json').and_return('')
    end
  end

end
