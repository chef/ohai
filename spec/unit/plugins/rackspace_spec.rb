#
# Author:: Cary Penniman (<cary@rightscale.com>)
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

describe Ohai::System, "plugin rackspace" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai.stub!(:require_plugin).and_return(true)
    @ohai[:network] = {:interfaces => {:eth0 => {"addresses"=> {
      "1.2.3.4"=> {
        "broadcast"=> "67.23.20.255",
        "netmask"=> "255.255.255.0",
        "family"=> "inet"
      },
      "2a00:1a48:7805:111:e875:efaf:ff08:75"=> {
        "family"=> "inet6",
        "prefixlen"=> "64",
        "scope"=> "Global"
      },
      "fe80::4240:95ff:fe47:6eed"=> {
        "scope"=> "Link",
        "prefixlen"=> "64",
        "family"=> "inet6"
      },
      "40:40:95:47:6E:ED"=> {
        "family"=> "lladdr"
      }
    }}}}

    @ohai[:network][:interfaces][:eth1] = {:addresses => {
      "fe80::4240:f5ff:feab:2836" => {
        "scope"=> "Link",
        "prefixlen"=> "64",
        "family"=> "inet6"
      },
      "5.6.7.8"=> {
        "broadcast"=> "10.176.191.255",
        "netmask"=> "255.255.224.0",
        "family"=> "inet"
      },
      "40:40:F5:AB:28:36" => {
        "family"=> "lladdr"
      }
    }}

    # In olden days we could detect rackspace by a -rscloud suffix on the kernel
    # This is here to make #has_rackspace_kernel? fail until we remove that check
    @ohai[:kernel] = { :release => "1.2.13-not-rackspace" }

    # We need a generic stub here for the later stubs with arguments to work
    # Because, magic.
    @ohai.stub(:run_command).and_return(false)
  end

  shared_examples_for "!rackspace"  do
    it "should NOT create rackspace" do
      @ohai._require_plugin("rackspace")
      @ohai[:rackspace].should be_nil
    end
  end

  shared_examples_for "rackspace" do

    it "should create rackspace" do
      @ohai._require_plugin("rackspace")
      @ohai[:rackspace].should_not be_nil
    end

    it "should have all required attributes" do
      @ohai._require_plugin("rackspace")
      @ohai[:rackspace][:public_ip].should_not be_nil
      @ohai[:rackspace][:private_ip].should_not be_nil
      @ohai[:rackspace][:public_ipv4].should_not be_nil
      @ohai[:rackspace][:local_ipv4].should_not be_nil
      @ohai[:rackspace][:public_ipv6].should_not be_nil
      @ohai[:rackspace][:local_ipv6].should be_nil
    end

    it "should have correct values for all attributes" do
      @ohai._require_plugin("rackspace")
      @ohai[:rackspace][:public_ip].should == "1.2.3.4"
      @ohai[:rackspace][:private_ip].should == "5.6.7.8"
      @ohai[:rackspace][:public_ipv4].should == "1.2.3.4"
      @ohai[:rackspace][:local_ipv4].should == "5.6.7.8"
      @ohai[:rackspace][:public_ipv6].should == "2a00:1a48:7805:111:e875:efaf:ff08:75"
    end

    it "should capture region information" do
      provider_data = <<-OUT
provider = "Rackspace"
service_type = "cloudServers"
server_id = "21301000"
created_at = "2012-12-06T22:08:16Z"
region = "dfw"
OUT
      @ohai.stub(:run_command).with({:no_status_check=>true, :command=>"xenstore-ls vm-data/provider_data"}).and_return([ 0, provider_data, ""])
      @ohai._require_plugin("rackspace")
      @ohai[:rackspace][:region].should == "dfw"
    end
  end

  describe "with rackspace cloud file" do
    it_should_behave_like "rackspace"

    before(:each) do
      File.stub!(:exist?).with('/etc/chef/ohai/hints/rackspace.json').and_return(true)
      File.stub!(:read).with('/etc/chef/ohai/hints/rackspace.json').and_return('')
      File.stub!(:exist?).with('C:\chef\ohai\hints/rackspace.json').and_return(true)
      File.stub!(:read).with('C:\chef\ohai\hints/rackspace.json').and_return('')
    end
  end

  describe "without cloud file" do
    it_should_behave_like "!rackspace"
  
    before(:each) do
      File.stub!(:exist?).with('/etc/chef/ohai/hints/rackspace.json').and_return(false)
      File.stub!(:exist?).with('C:\chef\ohai\hints/rackspace.json').and_return(false)
    end
  end
  
  describe "with ec2 cloud file" do
    it_should_behave_like "!rackspace"
  
    before(:each) do
      File.stub!(:exist?).with('/etc/chef/ohai/hints/ec2.json').and_return(true)
      File.stub!(:read).with('/etc/chef/ohai/hints/ec2.json').and_return('')
      File.stub!(:exist?).with('C:\chef\ohai\hints/ec2.json').and_return(true)
      File.stub!(:read).with('C:\chef\ohai\hints/ec2.json').and_return('')
    end
  end

  describe "xenstore provider returns rackspace" do
    it_should_behave_like "rackspace"

    before(:each) do
      stderr = StringIO.new
      stdout = "Rackspace\n"
      status = 0
      @ohai.stub!(:run_command).with({:no_status_check=>true, :command=>"xenstore-read vm-data/provider_data/provider"}).and_return([ status, stdout, stderr ])
    end
  end

  describe "xenstore provider does not return rackspace" do
    it_should_behave_like "!rackspace"

    before(:each) do
      stderr = StringIO.new
      stdout = "cumulonimbus\n"
      status = 0
      @ohai.stub!(:run_command).with({:no_status_check=>true, :command=>"xenstore-read vm-data/provider_data/provider"}).and_return([ status, stdout, stderr ])
    end
  end
end
