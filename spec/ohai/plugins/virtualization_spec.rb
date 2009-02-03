#
# Author:: Benjamin Black (<bb@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require File.join(File.dirname(__FILE__), '..', '..', '/spec_helper.rb')

describe Ohai::System, " Libvirt virtualization plugin" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai[:os] = 'linux'
    @ohai[:virtualization] = Mash.new
    @ohai.stub!(:require_plugin).and_return(true)
  end

  describe "when we are a guest" do
    it "should not collect from libvirt" do
      @ohai[:virtualization][:emulator] = "kvm" 
      @ohai[:virtualization][:role] = "guest"
      @ohai._require_plugin("virtualization")
      @ohai[:virtualization].has_key?("libvirt_version").should be false
    end
  end

  describe "when we are a host" do
    it "should collect from libvirt" do
      @ohai[:virtualization][:emulator] = "kvm" 
      @ohai[:virtualization][:role] = "host"
      @ohai._require_plugin("virtualization")
      @ohai[:virtualization].has_key?("libvirt_version").should be true
      @ohai[:virtualization].has_key?("domains").should be true
      @ohai[:virtualization].has_key?("networks").should be true
      @ohai[:virtualization].has_key?("storage").should be true
    end
  end
end