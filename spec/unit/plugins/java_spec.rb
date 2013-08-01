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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Ohai::System, "plugin java (Java5 Client VM)" do
  before(:each) do
    @ohai = Ohai::System.new
    Ohai::Loader.new(@ohai).load_plugin(File.join(PLUGIN_PATH, "java.rb"), "java")
    @plugin = @ohai.plugins[:java][:plugin]
    @plugin.stub(:require_plugin).and_return(true)
    @data = @ohai.data
    @data[:languages] = Mash.new
    @status = 0
    @stdout = ""
    @stderr = "java version \"1.5.0_16\"\nJava(TM) 2 Runtime Environment, Standard Edition (build 1.5.0_16-b06-284)\nJava HotSpot(TM) Client VM (build 1.5.0_16-133, mixed mode, sharing)"
    @plugin.stub(:run_command).with({:no_status_check => true, :command => "java -version"}).and_return([@status, @stdout, @stderr])
  end

  it "should run java -version" do
    @plugin.should_receive(:run_command).with({:no_status_check => true, :command => "java -version"}).and_return([0, "", "java version \"1.5.0_16\"\nJava(TM) 2 Runtime Environment, Standard Edition (build 1.5.0_16-b06-284)\nJava HotSpot(TM) Client VM (build 1.5.0_16-133, mixed mode, sharing)"])
    @plugin.new(@ohai).run
  end

  it "should set java[:version]" do
    @plugin.new(@ohai).run
    @data[:languages][:java][:version].should eql("1.5.0_16")
  end

  it "should set java[:runtime][:name] to runtime name" do
    @plugin.new(@ohai).run
    @data[:languages][:java][:runtime][:name].should eql("Java(TM) 2 Runtime Environment, Standard Edition")
  end

  it "should set java[:runtime][:build] to runtime build" do
    @plugin.new(@ohai).run
    @data[:languages][:java][:runtime][:build].should eql("1.5.0_16-b06-284")
  end

  it "should set java[:hotspot][:name] to hotspot name" do
    @plugin.new(@ohai).run
    @data[:languages][:java][:hotspot][:name].should eql("Java HotSpot(TM) Client VM")
  end

  it "should set java[:hotspot][:build] to hotspot build" do
    @plugin.new(@ohai).run
    @data[:languages][:java][:hotspot][:build].should eql("1.5.0_16-133, mixed mode, sharing")
  end

  it "should not set the languages[:java] tree up if java command fails" do
    @status = 1
    @stdout = ""
    @stderr = "Some error output here"
    @plugin.stub(:run_command).with({:no_status_check => true, :command => "java -version"}).and_return([@status, @stdout, @stderr])
    @plugin.new(@ohai).run
    @data[:languages].should_not have_key(:java)
  end
end

describe Ohai::System, "plugin java (Java6 Server VM)" do
  before(:each) do
    @ohai = Ohai::System.new
    Ohai::Loader.new(@ohai).load_plugin(File.join(PLUGIN_PATH, "java.rb"), "java")
    @plugin = @ohai.plugins[:java][:plugin]
    @plugin.stub(:require_plugin).and_return(true)
    @data[:languages] = Mash.new
    @status = 0
    @stdout = ""
    @stderr = "java version \"1.6.0_22\"\nJava(TM) 2 Runtime Environment (build 1.6.0_22-b04)\nJava HotSpot(TM) Server VM (build 17.1-b03, mixed mode)"
    @plugin.stub(:run_command).with({:no_status_check => true, :command => "java -version"}).and_return([@status, @stdout, @stderr])
  end

  it "should run java -version" do
    @plugin.should_receive(:run_command).with({:no_status_check => true, :command => "java -version"}).and_return([0, "", "java version \"1.6.0_22\"\nJava(TM) 2 Runtime Environment (build 1.6.0_22-b04)\nJava HotSpot(TM) Server VM (build 17.1-b03, mixed mode)"])
    @plugin.new(@ohai).run
  end

  it "should set java[:version]" do
    @plugin.new(@ohai).run
    @data[:languages][:java][:version].should eql("1.6.0_22")
  end

  it "should set java[:runtime][:name] to runtime name" do
    @plugin.new(@ohai).run
    @data[:languages][:java][:runtime][:name].should eql("Java(TM) 2 Runtime Environment")
  end

  it "should set java[:runtime][:build] to runtime build" do
    @plugin.new(@ohai).run
    @data[:languages][:java][:runtime][:build].should eql("1.6.0_22-b04")
  end

  it "should set java[:hotspot][:name] to hotspot name" do
    @plugin.new(@ohai).run
    @data[:languages][:java][:hotspot][:name].should eql("Java HotSpot(TM) Server VM")
  end

  it "should set java[:hotspot][:build] to hotspot build" do
    @plugin.new(@ohai).run
    @data[:languages][:java][:hotspot][:build].should eql("17.1-b03, mixed mode")
  end

  it "should not set the languages[:java] tree up if java command fails" do
    @status = 1
    @stdout = ""
    @stderr = "Some error output here"
    @plugin.stub(:run_command).with({:no_status_check => true, :command => "java -version"}).and_return([@status, @stdout, @stderr])
    @plugin.new(@ohai).run
    @data[:languages].should_not have_key(:java)
  end
end


