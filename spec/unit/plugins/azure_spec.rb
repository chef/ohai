#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright (c) 2011-2013 Opscode, Inc.
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

describe Ohai::System, "plugin azure" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai.stub!(:require_plugin).and_return(true)
  end

  describe "with azure cloud file" do
    before(:each) do
      File.stub!(:exist?).with('/etc/chef/ohai/hints/azure.json').and_return(true)
      File.stub!(:read).with('/etc/chef/ohai/hints/azure.json').and_return('{"public_ip":"137.135.46.202","vm_name":"test-vm","public_fqdn":"service.cloudapp.net","public_ssh_port":"22", "public_winrm_port":"5985"}')
      File.stub!(:exist?).with('C:\chef\ohai\hints/azure.json').and_return(true)
      File.stub!(:read).with('C:\chef\ohai\hints/azure.json').and_return('{"public_ip":"137.135.46.202","vm_name":"test-vm","public_fqdn":"service.cloudapp.net","public_ssh_port":"22", "public_winrm_port":"5985"}')
      @ohai._require_plugin("azure")
    end

    it 'should set the azure cloud attributes' do
      @ohai[:azure].should_not be_nil
      @ohai[:azure]['public_ip'].should  == "137.135.46.202"
      @ohai[:azure]['vm_name'].should == "test-vm"
      @ohai[:azure]['public_fqdn'].should == "service.cloudapp.net"
      @ohai[:azure]['public_ssh_port'].should == "22"
      @ohai[:azure]['public_winrm_port'].should == "5985"
    end

  end

  describe "without azure cloud file" do
    before(:each) do
      File.stub!(:exist?).with('/etc/chef/ohai/hints/azure.json').and_return(false)
      File.stub!(:exist?).with('C:\chef\ohai\hints/azure.json').and_return(false)
    end

    it 'should not behave like azure' do
      @ohai[:azure].should be_nil
    end
  end

  describe "with rackspace cloud file" do
    before(:each) do
      File.stub!(:exist?).with('/etc/chef/ohai/hints/rackspace.json').and_return(true)
      File.stub!(:read).with('/etc/chef/ohai/hints/rackspace.json').and_return('')
      File.stub!(:exist?).with('C:\chef\ohai\hints/rackspace.json').and_return(true)
      File.stub!(:read).with('C:\chef\ohai\hints/rackspace.json').and_return('')
    end

    it 'should not behave like azure' do
      @ohai[:azure].should be_nil
    end
  end

end
