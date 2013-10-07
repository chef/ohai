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
require 'ohai/mixin/gce_metadata'

describe Ohai::System, "plugin gce" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai.stub(:require_plugin).and_return(true)
  end

  shared_examples_for "!gce" do
    it 'should not behave like gce' do
      @ohai[:gce].should be_nil
    end
  end

  shared_examples_for "gce" do
    before(:each) do
      @http_client = double("Net::HTTP client")
      Ohai::Mixin::GCEMetadata.stub(:http_client).and_return(@http_client)
      IO.stub(:select).and_return([[],[1],[]])
      t = double("connection")
      t.stub(:connect_nonblock).and_raise(Errno::EINPROGRESS)
      Socket.stub(:new).and_return(t)
      Socket.stub(:pack_sockaddr_in).and_return(nil)
    end

    it "should recursively fetch and properly parse json metadata" do
      @http_client.should_receive(:get).
        with("/computeMetadata/v1beta1/?recursive=true/").
        and_return(double("Net::HTTP Response", :body => '{"instance":{"hostname":"test-host"}}', :code=>"200"))

      @ohai._require_plugin("gce")

      @ohai[:gce].should_not be_nil
      @ohai[:gce]['instance'].should eq("hostname"=>"test-host")
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
      File.stub(:exist?).with('/etc/chef/ohai/hints/gce.json').and_return(false)
      File.stub(:exist?).with('C:\chef\ohai\hints/gce.json').and_return(false)
    end
  end
  
  describe "with ec2 cloud file" do
    it_should_behave_like "!gce"
  
    before(:each) do
      File.stub(:exist?).with('/etc/chef/ohai/hints/gce.json').and_return(false)
      File.stub(:exist?).with('C:\chef\ohai\hints/gce.json').and_return(false)
      
      File.stub(:exist?).with('/etc/chef/ohai/hints/ec2.json').and_return(true)
      File.stub(:read).with('/etc/chef/ohai/hints/ec2.json').and_return('')
      File.stub(:exist?).with('C:\chef\ohai\hints/ec2.json').and_return(true)
      File.stub(:read).with('C:\chef\ohai\hints/ec2.json').and_return('')
    end
  end

end
