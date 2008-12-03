#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

describe Ohai::System, "plugin lsb" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai[:os] = "linux"    
    @ohai.stub!(:require_plugin).and_return(true)
    @mock_file = mock("/etc/lsb-release")
    @mock_file.stub!(:each).
      and_yield("DISTRIB_ID=Ubuntu").
      and_yield("DISTRIB_RELEASE=8.04").
      and_yield("DISTRIB_CODENAME=hardy").
      and_yield('DISTRIB_DESCRIPTION="Ubuntu 8.04"')
  end
  
  it "should set lsb_dist_id" do
    @ohai._require_plugin("lsb")
    @ohai[:lsb_dist_id] == "Ubuntu"
  end
  
  it "should set lsb_dist_release" do
    @ohai._require_plugin("lsb")
    @ohai[:lsb_dist_release] == "8.04"
  end
  
  it "should set lsb_dist_codename" do
    @ohai._require_plugin("lsb")
    @ohai[:lsb_dist_codename] == "hardy"
  end
  
  it "should set lsb dist description" do
    @ohai._require_plugin("lsb")
    @ohai[:lsb_dist_description] == "Ubuntu 8.04"
  end
  
  it "should not set any lsb values if /etc/lsb-release cannot be read" do
    File.stub!(:open).with("/etc/lsb-release").and_raise(IOError)
    @ohai.attribute?(:lsb_dist_id).should be(false)
    @ohai.attribute?(:lsb_dist_release).should be(false)
    @ohai.attribute?(:lsb_dist_codename).should be(false)
    @ohai.attribute?(:lsb_dist_description).should be(false)
  end
end