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
      }}
    }
  }

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
      @stderr = StringIO.new
      @stdout = <<-OUT
provider = "Rackspace"
service_type = "cloudServers"
server_id = "21301000"
created_at = "2012-12-06T22:08:16Z"
region = "dfw"
OUT
      @status = 0
      @ohai.stub(:run_command).with({:no_status_check=>true, :command=>"xenstore-ls vm-data/provider_data"}).and_return([ @status, @stdout, @stderr ])
      @ohai._require_plugin("rackspace")
      @ohai[:rackspace][:region].should == "dfw"
    end
  end

  describe "with rackspace mac and hostname" do
    it_should_behave_like "rackspace"

    before(:each) do
      IO.stub!(:select).and_return([[],[1],[]])
      @ohai[:hostname] = "slice74976"
      @ohai[:network][:interfaces][:eth0][:arp] = {"67.23.20.1" => "00:00:0c:07:ac:01"}
    end
  end

  describe "without rackspace mac" do
    it_should_behave_like "!rackspace"

    before(:each) do
      @ohai[:hostname] = "slice74976"
      @ohai[:network][:interfaces][:eth0][:arp] = {"169.254.1.0"=>"fe:ff:ff:ff:ff:ff"}
    end
  end

  describe "without rackspace hostname" do
    it_should_behave_like "rackspace"

    before(:each) do
      @ohai[:hostname] = "bubba"
      @ohai[:network][:interfaces][:eth0][:arp] = {"67.23.20.1" => "00:00:0c:07:ac:01"}
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

end
