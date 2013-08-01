#
# Author:: Ranjib Dey (dey.ranjib@gmail.com)
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

describe Ohai::System, "plugin gce" do
  before(:each) do
    @ohai = Ohai::System.new
    @plugin = Ohai::DSL::Plugin.new(@ohai, File.join(PLUGIN_PATH, "gce.rb"))
    @plugin.stub(:require_plugin)
  end

  shared_examples_for "!gce" do
    it "should NOT attempt to fetch the gce metadata" do
      @plugin.should_not_receive(:http_client)
      @plugin.run
    end
  end

  shared_examples_for "gce" do
    before(:each) do
      @http_client = double("Net::HTTP client")
      @plugin.stub(:http_client).and_return(@http_client)
      IO.stub(:select).and_return([[],[1],[]])
      t = double("connection")
      t.stub(:connect_nonblock).and_raise(Errno::EINPROGRESS)
      Socket.stub(:new).and_return(t)
      Socket.stub(:pack_sockaddr_in).and_return(nil)
    end

    it "should recursively fetch metadata" do
      @http_client.should_receive(:get).
        with("/0.1/meta-data/").
        and_return(double("Net::HTTPOK",
                         :body => "domain\nhostname\ndescription", :code=>"200"))
      @http_client.should_receive(:get).
        with("/0.1/meta-data/domain").
        and_return(double("Net::HTTPOK", :body => "test-domain", :code=>"200"))
      @http_client.should_receive(:get).
        with("/0.1/meta-data/hostname").
        and_return(double("Net::HTTPOK", :body => "test-host", :code=>"200"))
      @http_client.should_receive(:get).
        with("/0.1/meta-data/description").
        and_return(double("Net::HTTPOK", :body => "test-description", :code=>"200"))

      @plugin.run

      @plugin[:gce].should_not be_nil
      @plugin[:gce]['hostname'].should == "test-host"
      @plugin[:gce]['domain'].should == "test-domain"
      @plugin[:gce]['description'].should  == "test-description"
    end

    it "should properly parse json metadata" do
      @http_client.should_receive(:get).
        with("/0.1/meta-data/").
        and_return(double("Net::HTTP Response", :body => "attached-disks\n", :code=>"200"))
      @http_client.should_receive(:get).
        with("/0.1/meta-data/attached-disks").
        and_return(double("Net::HTTP Response", :body => '{"disks":[{"deviceName":"boot",
                    "index":0,"mode":"READ_WRITE","type":"EPHEMERAL"}]}', :code=>"200"))

      @plugin.run

      @plugin[:gce].should_not be_nil
      @plugin[:gce]['attached_disks'].should eq({"disks"=>[{"deviceName"=>"boot",
                                              "index"=>0,"mode"=>"READ_WRITE",
                                              "type"=>"EPHEMERAL"}]})
    end
  end

  describe "with dmi and metadata address connected" do
    it_should_behave_like "gce"
    before(:each) do
      File.should_receive(:read).with('/sys/firmware/dmi/entries/1-0/raw').and_return('Google')
    end
  end

  describe "without dmi and metadata address connected" do
    it_should_behave_like "!gce"
    before(:each) do
      File.should_receive(:read).with('/sys/firmware/dmi/entries/1-0/raw').and_return('Test')
    end
  end
  
  describe "with hint file" do
    it_should_behave_like "gce"

    before(:each) do
      File.stub(:exist?).with('/etc/chef/ohai/hints/gce.json').and_return(true)
      File.stub(:read).with('/etc/chef/ohai/hints/gce.json').and_return('')
      File.stub(:exist?).with('C:\chef\ohai\hints/gce.json').and_return(true)
      File.stub(:read).with('C:\chef\ohai\hints/gce.json').and_return('')
    end
  end

  describe "without hint file" do
    it_should_behave_like "!gce"
  
    before(:each) do
      File.should_receive(:read).with('/sys/firmware/dmi/entries/1-0/raw').and_return('Test')

      File.stub(:exist?).with('/etc/chef/ohai/hints/gce.json').and_return(false)
      File.stub(:exist?).with('C:\chef\ohai\hints/gce.json').and_return(false)
    end
  end
  
  describe "with ec2 cloud file" do
    it_should_behave_like "!gce"
  
    before(:each) do
      File.should_receive(:read).with('/sys/firmware/dmi/entries/1-0/raw').and_return('Test')

      File.stub(:exist?).with('/etc/chef/ohai/hints/gce.json').and_return(false)
      File.stub(:exist?).with('C:\chef\ohai\hints/gce.json').and_return(false)

      File.stub(:exist?).with('/etc/chef/ohai/hints/ec2.json').and_return(true)
      File.stub(:read).with('/etc/chef/ohai/hints/ec2.json').and_return('')
      File.stub(:exist?).with('C:\chef\ohai\hints/ec2.json').and_return(true)
      File.stub(:read).with('C:\chef\ohai\hints/ec2.json').and_return('')
    end
  end
end
