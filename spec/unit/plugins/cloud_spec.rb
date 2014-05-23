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
  before(:each) do
    @plugin = get_plugin("cloud")
  end

  describe "with no cloud mashes" do
    it "doesn't populate the cloud data" do
      @plugin[:ec2] = nil
      @plugin[:rackspace] = nil
      @plugin[:eucalyptus] = nil
      @plugin[:linode] = nil
      @plugin[:azure] = nil
      @plugin.run
      @plugin[:cloud].should be_nil
    end
  end

  describe "with EC2 mash" do
    before do
      @plugin[:ec2] = Mash.new()
    end

    it "populates cloud public ip" do
      @plugin[:ec2]['public_ipv4'] = "174.129.150.8"
      @plugin.run
      @plugin[:cloud][:public_ips][0].should == @plugin[:ec2]['public_ipv4']
    end

    it "populates cloud private ip" do
      @plugin[:ec2]['local_ipv4'] = "10.252.42.149"
      @plugin.run
      @plugin[:cloud][:private_ips][0].should == @plugin[:ec2]['local_ipv4']
    end

    it "populates cloud provider" do
      @plugin.run
      @plugin[:cloud][:provider].should == "ec2"
    end
  end

  describe "with rackspace" do
    before do
      @plugin[:rackspace] = Mash.new()
    end  
    
    it "populates cloud public ip" do
      @plugin[:rackspace][:public_ipv4] = "174.129.150.8"
      @plugin.run
      @plugin[:cloud][:public_ipv4].should == @plugin[:rackspace][:public_ipv4]
    end
    
    it "populates cloud public ipv6" do
      @plugin[:rackspace][:public_ipv6] = "2a00:1a48:7805:111:e875:efaf:ff08:75"
      @plugin.run
      @plugin[:cloud][:public_ipv6].should == @plugin[:rackspace][:public_ipv6]
    end
    
    it "populates cloud private ip" do
      @plugin[:rackspace][:local_ipv4] = "10.252.42.149"
      @plugin.run
      @plugin[:cloud][:local_ipv4].should == @plugin[:rackspace][:local_ipv4]
    end
    
    it "populates cloud private ipv6" do
      @plugin[:rackspace][:local_ipv6] = "2a00:1a48:7805:111:e875:efaf:ff08:75"
      @plugin.run
      @plugin[:cloud][:local_ipv6].should == @plugin[:rackspace][:local_ipv6]
    end
    
    it "populates first cloud public ip" do
      @plugin[:rackspace][:public_ipv4] = "174.129.150.8"
      @plugin.run
      @plugin[:cloud][:public_ips].first.should == @plugin[:rackspace][:public_ipv4]
    end
    
    it "populates first cloud public ip" do
      @plugin[:rackspace][:local_ipv4] = "174.129.150.8"
      @plugin.run
      @plugin[:cloud][:private_ips].first.should == @plugin[:rackspace][:local_ipv4]
    end

    it "populates cloud provider" do
      @plugin.run
      @plugin[:cloud][:provider].should == "rackspace"
    end
  end

  describe "with linode mash" do
    before do
      @plugin[:linode] = Mash.new()
    end

    it "populates cloud public ip" do
      @plugin[:linode]['public_ip'] = "174.129.150.8"
      @plugin.run
      @plugin[:cloud][:public_ips][0].should == @plugin[:linode][:public_ip]
    end

    it "populates cloud private ip" do
      @plugin[:linode]['private_ip'] = "10.252.42.149"
      @plugin.run
      @plugin[:cloud][:private_ips][0].should == @plugin[:linode][:private_ip]
    end

    it "populates first cloud public ip" do
      @plugin[:linode]['public_ip'] = "174.129.150.8"
      @plugin.run
      @plugin[:cloud][:public_ips].first.should == @plugin[:linode][:public_ip]
    end

    it "populates cloud provider" do
      @plugin.run
      @plugin[:cloud][:provider].should == "linode"
    end
  end

  describe "with eucalyptus mash" do
    before do
      @plugin[:eucalyptus] = Mash.new()
    end

    it "populates cloud public ip" do
      @plugin[:eucalyptus]['public_ipv4'] = "174.129.150.8"
      @plugin.run
      @plugin[:cloud][:public_ips][0].should == @plugin[:eucalyptus]['public_ipv4']
    end

    it "populates cloud private ip" do
      @plugin[:eucalyptus]['local_ipv4'] = "10.252.42.149"
      @plugin.run
      @plugin[:cloud][:private_ips][0].should == @plugin[:eucalyptus]['local_ipv4']
    end

    it "populates cloud provider" do
      @plugin.run
      @plugin[:cloud][:provider].should == "eucalyptus"
    end
  end

  describe "with Azure mash" do
    before do
      @plugin[:azure] = Mash.new()
    end

    it "populates cloud public ip" do
      @plugin[:azure]['public_ip'] = "174.129.150.8"
      @plugin.run
      @plugin[:cloud][:public_ips][0].should == @plugin[:azure]['public_ip']
      @plugin[:cloud][:public_ipv4].should == @plugin[:azure]['public_ip']
    end

    it "populates cloud vm_name" do
      @plugin[:azure]['vm_name'] = "linux-vm"
      @plugin.run
      @plugin[:cloud][:vm_name].should == @plugin[:azure]['vm_name']
    end

    it "populates cloud public_fqdn" do
      @plugin[:azure]['public_fqdn'] = "linux-vm-svc.cloudapp.net"
      @plugin.run
      @plugin[:cloud][:public_fqdn].should == @plugin[:azure]['public_fqdn']
      @plugin[:cloud][:public_hostname].should == @plugin[:azure]['public_fqdn']
    end

    it "populates cloud public_ssh_port" do
      @plugin[:azure]['public_ssh_port'] = "22"
      @plugin.run
      @plugin[:cloud][:public_ssh_port].should == @plugin[:azure]['public_ssh_port']
    end

    it "should not populate cloud public_ssh_port when winrm is used" do
      @plugin[:azure]['public_winrm_port'] = "5985"
      @plugin.run
      @plugin[:cloud][:public_ssh_port].should be_nil
    end

    it "populates cloud public_winrm_port" do
      @plugin[:azure]['public_winrm_port'] = "5985"
      @plugin.run
      @plugin[:cloud][:public_winrm_port].should == @plugin[:azure]['public_winrm_port']
    end

    it "populates cloud provider" do
      @plugin.run
      @plugin[:cloud][:provider].should == "azure"
    end
  end

end
