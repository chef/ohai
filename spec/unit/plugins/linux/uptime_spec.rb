#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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


require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Ohai::System, "Linux plugin uptime" do
  before(:each) do
    @plugin = get_plugin("uptime")
    @plugin.stub(:collect_os).and_return(:linux)
    @double_file = double("/proc/uptime", { :gets => "18423 989" })
    File.stub(:open).with("/proc/uptime").and_return(@double_file)
  end
 
  it "should set uptime_seconds to uptime" do
    @plugin.run
    @plugin[:uptime_seconds].should == 18423
  end
  
  it "should set uptime to a human readable date" do
    @plugin.run
    @plugin[:uptime].should == "5 hours 07 minutes 03 seconds"
  end
  
  it "should set idletime_seconds to uptime" do
    @plugin.run
    @plugin[:idletime_seconds].should == 989
  end
  
  it "should set idletime to a human readable date" do
    @plugin.run
    @plugin[:idletime].should == "16 minutes 29 seconds"
  end
end
