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
    @plugin = get_plugin("azure")
  end

  describe "with azure cloud file" do
    before(:each) do
      allow(File).to receive(:exist?).with('/etc/chef/ohai/hints/azure.json').and_return(true)
      allow(File).to receive(:read).with('/etc/chef/ohai/hints/azure.json').and_return('{"public_ip":"137.135.46.202","vm_name":"test-vm","public_fqdn":"service.cloudapp.net","public_ssh_port":"22", "public_winrm_port":"5985"}')
      allow(File).to receive(:exist?).with('C:\chef\ohai\hints/azure.json').and_return(true)
      allow(File).to receive(:read).with('C:\chef\ohai\hints/azure.json').and_return('{"public_ip":"137.135.46.202","vm_name":"test-vm","public_fqdn":"service.cloudapp.net","public_ssh_port":"22", "public_winrm_port":"5985"}')
      @plugin.run
    end

    it 'should set the azure cloud attributes' do
      expect(@plugin[:azure]).not_to be_nil
      expect(@plugin[:azure]['public_ip']).to  eq("137.135.46.202")
      expect(@plugin[:azure]['vm_name']).to eq("test-vm")
      expect(@plugin[:azure]['public_fqdn']).to eq("service.cloudapp.net")
      expect(@plugin[:azure]['public_ssh_port']).to eq("22")
      expect(@plugin[:azure]['public_winrm_port']).to eq("5985")
    end

  end

  describe "without azure cloud file" do
    before(:each) do
      allow(File).to receive(:exist?).with('/etc/chef/ohai/hints/azure.json').and_return(false)
      allow(File).to receive(:exist?).with('C:\chef\ohai\hints/azure.json').and_return(false)
    end

    it 'should not behave like azure' do
      expect(@plugin[:azure]).to be_nil
    end
  end

  describe "with rackspace cloud file" do
    before(:each) do
      allow(File).to receive(:exist?).with('/etc/chef/ohai/hints/rackspace.json').and_return(true)
      allow(File).to receive(:read).with('/etc/chef/ohai/hints/rackspace.json').and_return('')
      allow(File).to receive(:exist?).with('C:\chef\ohai\hints/rackspace.json').and_return(true)
      allow(File).to receive(:read).with('C:\chef\ohai\hints/rackspace.json').and_return('')
    end

    it 'should not behave like azure' do
      expect(@plugin[:azure]).to be_nil
    end
  end

end
