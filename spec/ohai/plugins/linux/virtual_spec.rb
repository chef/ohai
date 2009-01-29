#
# Author:: Thom May (<thom@clearairturbulence.org>)
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

require File.join(File.dirname(__FILE__), '..', '..', '..', '/spec_helper.rb')

describe Ohai::System, "Linux virtualisation platform" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai[:os] = "linux"
    @ohai.stub!(:require_plugin).and_return(true)
    @mock_cap = mock("/proc/xen/capabilities")
    @mock_cap.stub!(:each).and_yield("control_d")
  end

  it "should set xen0 if /proc/xen/capabilities contains control_d" do
    @ohai._require_plugin("linux::virtual")
    @ohai[:virtual] == "xen0"
  end

  it "should set xenu if /proc/sys/xen/independent_wallclock exists" do
    File.stub!(:exists).with("/proc/xen/capabilities").and_return(false)
    File.stub!(:exists).with("/proc/sys/xen/independent_wallclock").and_return(true)
    @ohai._require_plugin("linux::virtual")
    @ohai[:virtual] == "xenu"
  end

  it "should set physical if xen isn't there" do
    File.stub!(:exists).with("/proc/xen/capabilities").and_return(false)
    File.stub!(:exists).with("/proc/sys/xen/independent_wallclock").and_return(false)
    @ohai._require_plugin("linux::virtual")
    @ohai[:virtual] == "physical"
  end
end


