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
require File.expand_path("#{File.dirname(__FILE__)}/system_profiler_output.rb")

describe Ohai::System, "Darwin system_profiler plugin" do
  before(:each) do
    @ohai = Ohai::System.new

    @ohai.stub!(:require_plugin).and_return(true)
    @ohai['system_profile'] = Mash.new
  end
  
  it "should return the right serial number" do
    @ohai.stub!(:popen4).with("system_profiler -xml -detailLevel full SPHardwareDataType").and_yield(nil, nil, SystemProfilerOutput::Full, nil)
    @ohai.stub!(:popen4).with("system_profiler -xml -detailLevel mini").and_yield(nil, nil, SystemProfilerOutput::Mini, nil)
    @ohai._require_plugin("darwin::system_profiler")
    require 'pp'
    pp @ohai['system_profile']
    @ohai['system_profile'][10]["_items"][0]["serial_number"].should == 'ABCDEFG12345'
  end
end