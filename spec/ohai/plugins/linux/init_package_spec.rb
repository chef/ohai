#
# Author:: Caleb Tennis (<caleb.tennis@gmail.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

describe Ohai::System, "Init package" do
  before(:each) do
    @ohai = Ohai::System.new    
    @ohai.stub!(:require_plugin).and_return(true)
    @ohai[:os] = "linux"
    @mock_file = mock("/proc/1/comm")
    @mock_file.stub!(:gets).and_return("init\n")
    File.stub!(:open).with("/proc/1/comm").and_return(@mock_file)
  end
  
  it "should set init_package to init" do
    @ohai._require_plugin("linux::init_package")
    @ohai[:init_package].should == "init"
  end
  
  it "should set init_package to systemd" do
    @mock_file.stub!(:gets).and_return("systemd\n")
    @ohai._require_plugin("linux::init_package")
    @ohai[:init_package].should == "systemd"
  end
end