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
    Ohai::Loader.new(@ohai).load_plugin(File.expand_path("cloud.rb", PLUGIN_PATH), "cloud")
    @plugin = @ohai.plugins[:cloud][:plugin]
    @plugin.stub(:require_plugin)
    @data = @ohai.data
  end

  describe "with no cloud mashes" do
    it "doesn't populate the cloud data" do
      @data[:ec2] = nil
      @data[:rackspace] = nil
      @data[:eucalyptus] = nil
      @data[:linode] = nil
      @data[:azure] = nil
      @plugin.new(@ohai).run
      @data[:cloud].should be_nil
    end
  end

  describe "with EC2 mash" do
    before do
      @data[:ec2] = Mash.new()
    end

    it "populates cloud public ip" do
      @data[:ec2]['public_ipv4'] = "174.129.150.8"
      @plugin.new(@ohai).run
      @data[:cloud][:public_ips][0].should == @data[:ec2]['public_ipv4']
    end

    it "populates cloud private ip" do
      @data[:ec2]['local_ipv4'] = "10.252.42.149"
      @plugin.new(@ohai).run
      @data[:cloud][:private_ips][0].should == @data[:ec2]['local_ipv4']
    end

    it "populates cloud provider" do
      @plugin.new(@ohai).run
      @data[:cloud][:provider].should == "ec2"
    end
  end

  describe "with rackspace" do
    before do
      @data[:rackspace] = Mash.new()
    end  
    
    it "populates cloud public ip" do
      @data[:rackspace][:public_ipv4] = "174.129.150.8"
      @plugin.new(@ohai).run
      @data[:cloud][:public_ipv4].should == @data[:rackspace][:public_ipv4]
    end
    
    it "populates cloud public ipv6" do
      @data[:rackspace][:public_ipv6] = "2a00:1a48:7805:111:e875:efaf:ff08:75"
      @plugin.new(@ohai).run
      @data[:cloud][:public_ipv6].should == @data[:rackspace][:public_ipv6]
    end
    
    it "populates cloud private ip" do
      @data[:rackspace][:local_ipv4] = "10.252.42.149"
      @plugin.new(@ohai).run
      @data[:cloud][:local_ipv4].should == @data[:rackspace][:local_ipv4]
    end
    
    it "populates cloud private ipv6" do
      @data[:rackspace][:local_ipv6] = "2a00:1a48:7805:111:e875:efaf:ff08:75"
      @plugin.new(@ohai).run
      @data[:cloud][:local_ipv6].should == @data[:rackspace][:local_ipv6]
    end
    
    it "populates first cloud public ip" do
      @data[:rackspace][:public_ipv4] = "174.129.150.8"
      @plugin.new(@ohai).run
      @data[:cloud][:public_ips].first.should == @data[:rackspace][:public_ipv4]
    end
    
    it "populates first cloud public ip" do
      @data[:rackspace][:local_ipv4] = "174.129.150.8"
      @plugin.new(@ohai).run
      @data[:cloud][:private_ips].first.should == @data[:rackspace][:local_ipv4]
    end

    it "populates cloud provider" do
      @plugin.new(@ohai).run
      @data[:cloud][:provider].should == "rackspace"
    end
  end

  describe "with linode mash" do
    before do
      @data[:linode] = Mash.new()
    end

    it "populates cloud public ip" do
      @data[:linode]['public_ip'] = "174.129.150.8"
      @plugin.new(@ohai).run
      @data[:cloud][:public_ips][0].should == @data[:linode][:public_ip]
    end

    it "populates cloud private ip" do
      @data[:linode]['private_ip'] = "10.252.42.149"
      @plugin.new(@ohai).run
      @data[:cloud][:private_ips][0].should == @data[:linode][:private_ip]
    end

    it "populates first cloud public ip" do
      @data[:linode]['public_ip'] = "174.129.150.8"
      @plugin.new(@ohai).run
      @data[:cloud][:public_ips].first.should == @data[:linode][:public_ip]
    end

    it "populates cloud provider" do
      @plugin.new(@ohai).run
      @data[:cloud][:provider].should == "linode"
    end
  end

  describe "with eucalyptus mash" do
    before do
      @data[:eucalyptus] = Mash.new()
    end

    it "populates cloud public ip" do
      @data[:eucalyptus]['public_ipv4'] = "174.129.150.8"
      @plugin.new(@ohai).run
      @data[:cloud][:public_ips][0].should == @data[:eucalyptus]['public_ipv4']
    end

    it "populates cloud private ip" do
      @data[:eucalyptus]['local_ipv4'] = "10.252.42.149"
      @plugin.new(@ohai).run
      @data[:cloud][:private_ips][0].should == @data[:eucalyptus]['local_ipv4']
    end

    it "populates cloud provider" do
      @plugin.new(@ohai).run
      @data[:cloud][:provider].should == "eucalyptus"
    end
  end

  describe "with Azure mash" do
    before do
      @data[:azure] = Mash.new()
    end

    it "populates cloud public ip" do
      @data[:azure]['public_ip'] = "174.129.150.8"
      @plugin.new(@ohai).run
      @data[:cloud][:public_ips][0].should == @data[:azure]['public_ip']
    end

    it "populates cloud vm_name" do
      @data[:azure]['vm_name'] = "linux-vm"
      @plugin.new(@ohai).run
      @data[:cloud][:vm_name].should == @data[:azure]['vm_name']
    end

    it "populates cloud public_fqdn" do
      @data[:azure]['public_fqdn'] = "linux-vm-svc.cloudapp.net"
      @plugin.new(@ohai).run
      @data[:cloud][:public_fqdn].should == @data[:azure]['public_fqdn']
    end

    it "populates cloud public_ssh_port" do
      @data[:azure]['public_ssh_port'] = "22"
      @plugin.new(@ohai).run
      @data[:cloud][:public_ssh_port].should == @data[:azure]['public_ssh_port']
    end

    it "should not populate cloud public_ssh_port when winrm is used" do
      @data[:azure]['public_winrm_port'] = "5985"
      @plugin.new(@ohai).run
      @data[:cloud][:public_ssh_port].should be_nil
    end

    it "populates cloud public_winrm_port" do
      @data[:azure]['public_winrm_port'] = "5985"
      @plugin.new(@ohai).run
      @data[:cloud][:public_winrm_port].should == @data[:azure]['public_winrm_port']
    end

    it "populates cloud provider" do
      @plugin.new(@ohai).run
      @data[:cloud][:provider].should == "azure"
    end
  end

end
