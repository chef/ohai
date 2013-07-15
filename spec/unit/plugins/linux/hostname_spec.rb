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

describe Ohai::System, "Linux hostname plugin" do
  before(:each) do
    @ohai = Ohai::System.new    
    @plugin = Ohai::DSL::Plugin.new(@ohai, File.expand_path("linux/hostname.rb", PLUGIN_PATH))
    @plugin.stub!(:require_plugin).and_return(true)
    @plugin[:os] = "linux"
    @plugin.stub!(:from).with("hostname -s").and_return("katie")
    @plugin.stub!(:from).with("hostname --fqdn").and_return("katie.bethell")
  end

  it_should_check_from("linux::hostname", "hostname", "hostname -s", "katie")
  
  it_should_check_from("linux::hostname", "fqdn", "hostname --fqdn", "katie.bethell")

  describe "when domain name is unset" do 
    before(:each) do
      @plugin.should_receive(:from).with("hostname --fqdn").and_raise("Ohai::Exception::Exec")
    end

    it "should not raise an error" do
      lambda { @plugin.run }.should_not raise_error
    end

    it "should not set fqdn" do
      @plugin.run
      @plugin.fqdn.should == nil
    end

  end
    
end

