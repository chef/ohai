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

describe Ohai::System, "plugin cloud" do
  before do
    @ohai = Ohai::System.new
    @ohai.stub!(:require_plugin).and_return(true)
  end

  describe "with no cloud mashes" do
    it "doesn't populate the cloud data" do
      @ohai[:ec2] = nil
      @ohai[:rackspace] = nil
      @ohai[:eucalyptus] = nil
      @ohai[:linode] = nil
      @ohai[:azure] = nil
      @ohai._require_plugin("cloud")
      @ohai[:cloud].should be_nil
    end
  end

  describe "with EC2 mash" do
    before do
      @ohai[:ec2] = Mash.new()
    end

    it "populates cloud public ip" do
      @ohai[:ec2]['public_ipv4'] = "174.129.150.8"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:public_ips][0].should == @ohai[:ec2]['public_ipv4']
    end

    it "populates cloud private ip" do
      @ohai[:ec2]['local_ipv4'] = "10.252.42.149"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:private_ips][0].should == @ohai[:ec2]['local_ipv4']
    end

    it "populates cloud provider" do
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:provider].should == "ec2"
    end
  end

  describe "with rackspace" do
    before do
      @ohai[:rackspace] = Mash.new()
    end  
    
    it "populates cloud public ip" do
      @ohai[:rackspace][:public_ipv4] = "174.129.150.8"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:public_ipv4].should == @ohai[:rackspace][:public_ipv4]
    end
    
    it "populates cloud public ipv6" do
      @ohai[:rackspace][:public_ipv6] = "2a00:1a48:7805:111:e875:efaf:ff08:75"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:public_ipv6].should == @ohai[:rackspace][:public_ipv6]
    end
    
    it "populates cloud private ip" do
      @ohai[:rackspace][:local_ipv4] = "10.252.42.149"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:local_ipv4].should == @ohai[:rackspace][:local_ipv4]
    end
    
    it "populates cloud private ipv6" do
      @ohai[:rackspace][:local_ipv6] = "2a00:1a48:7805:111:e875:efaf:ff08:75"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:local_ipv6].should == @ohai[:rackspace][:local_ipv6]
    end
    
    it "populates first cloud public ip" do
      @ohai[:rackspace][:public_ipv4] = "174.129.150.8"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:public_ips].first.should == @ohai[:rackspace][:public_ipv4]
    end
    
    it "populates first cloud public ip" do
      @ohai[:rackspace][:local_ipv4] = "174.129.150.8"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:private_ips].first.should == @ohai[:rackspace][:local_ipv4]
    end

    it "populates cloud provider" do
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:provider].should == "rackspace"
    end
  end

  describe "with linode mash" do
    before do
      @ohai[:linode] = Mash.new()
    end

    it "populates cloud public ip" do
      @ohai[:linode]['public_ip'] = "174.129.150.8"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:public_ips][0].should == @ohai[:linode][:public_ip]
    end

    it "populates cloud private ip" do
      @ohai[:linode]['private_ip'] = "10.252.42.149"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:private_ips][0].should == @ohai[:linode][:private_ip]
    end

    it "populates first cloud public ip" do
      @ohai[:linode]['public_ip'] = "174.129.150.8"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:public_ips].first.should == @ohai[:linode][:public_ip]
    end

    it "populates cloud provider" do
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:provider].should == "linode"
    end
  end

  describe "with eucalyptus mash" do
    before do
      @ohai[:eucalyptus] = Mash.new()
    end

    it "populates cloud public ip" do
      @ohai[:eucalyptus]['public_ipv4'] = "174.129.150.8"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:public_ips][0].should == @ohai[:eucalyptus]['public_ipv4']
    end

    it "populates cloud private ip" do
      @ohai[:eucalyptus]['local_ipv4'] = "10.252.42.149"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:private_ips][0].should == @ohai[:eucalyptus]['local_ipv4']
    end

    it "populates cloud provider" do
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:provider].should == "eucalyptus"
    end
  end

  describe "with Azure mash" do
    before do
      @ohai[:azure] = Mash.new()
    end

    it "populates cloud public ip" do
      @ohai[:azure]['public_ip'] = "174.129.150.8"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:public_ips][0].should == @ohai[:azure]['public_ip']
    end

    it "populates cloud vm_name" do
      @ohai[:azure]['vm_name'] = "linux-vm"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:vm_name].should == @ohai[:azure]['vm_name']
    end

    it "populates cloud public_fqdn" do
      @ohai[:azure]['public_fqdn'] = "linux-vm-svc.cloudapp.net"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:public_fqdn].should == @ohai[:azure]['public_fqdn']
    end

    it "populates cloud public_ssh_port" do
      @ohai[:azure]['public_ssh_port'] = "22"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:public_ssh_port].should == @ohai[:azure]['public_ssh_port']
    end

    it "should not populate cloud public_ssh_port when winrm is used" do
      @ohai[:azure]['public_winrm_port'] = "5985"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:public_ssh_port].should be_nil
    end

    it "populates cloud public_winrm_port" do
      @ohai[:azure]['public_winrm_port'] = "5985"
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:public_winrm_port].should == @ohai[:azure]['public_winrm_port']
    end

    it "populates cloud provider" do
      @ohai._require_plugin("cloud")
      @ohai[:cloud][:provider].should == "azure"
    end
  end

end
