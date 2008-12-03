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

describe Ohai::System, "plugin hostname" do
  before(:each) do
    @ohai = Ohai::System.new    
    @ohai.stub!(:require_plugin).and_return(true)
    @ohai.stub!(:from).with("uname -s").and_return("Darwin")
    @ohai.stub!(:from).with("uname -r").and_return("9.5.0")
    @ohai.stub!(:from).with("uname -v").and_return("Darwin Kernel Version 9.5.0: Wed Sep  3 11:29:43 PDT 2008; root:xnu-1228.7.58~1\/RELEASE_I386")
    @ohai.stub!(:from).with("uname -m").and_return("i386")
    @ohai.stub!(:from).with("uname -o").and_return("Linux")
  end

  it_should_check_from("kernel", "kernel_name", "uname -s", "Darwin")
  
  it_should_check_from("kernel", "kernel_release", "uname -r", "9.5.0")
  
  it_should_check_from("kernel", "kernel_version", "uname -v", "Darwin Kernel Version 9.5.0: Wed Sep  3 11:29:43 PDT 2008; root:xnu-1228.7.58~1\/RELEASE_I386")
  
  it_should_check_from("kernel", "kernel_machine", "uname -m", "i386")
  
  describe "on linux" do
    before(:each) do
      @ohai.stub!(:from).with("uname -s").and_return("Linux")
    end
    
    it_should_check_from("kernel", "kernel_os", "uname -o", "Linux")
  end
  
  describe "on darwin" do
    it "should set the kernel_os to the kernel_name value" do
      @ohai._require_plugin("kernel")
      @ohai[:kernel_os].should == @ohai[:kernel_name]
    end
  end
end