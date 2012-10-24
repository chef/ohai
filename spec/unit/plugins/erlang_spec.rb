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


require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Ohai::System, "plugin erlang" do

  before(:each) do
    @ohai = Ohai::System.new
    @plugin = Ohai::DSL::Plugin.new(@ohai, File.join(PLUGIN_PATH, "erlang.rb"))
    @plugin[:languages] = Mash.new
    @status = 0
    @stdin = ""
    @stderr = "Erlang (ASYNC_THREADS,SMP,HIPE) (BEAM) emulator version 5.6.2\n"
    @plugin.stub!(:run_command).with({:no_status_check => true, :command => "erl +V"}).and_return([@status, @stdout, @stderr])
  end
  
  it "should get the erlang version from erl +V" do
    @plugin.should_receive(:run_command).with({:no_status_check => true, :command => "erl +V"}).and_return([0, "", "Erlang (ASYNC_THREADS,SMP,HIPE) (BEAM) emulator version 5.6.2\n"])
    @plugin.run
  end

  it "should set languages[:erlang][:version]" do
    @plugin.run
    @plugin.languages[:erlang][:version].should eql("5.6.2")
  end
  
  it "should set languages[:erlang][:options]" do
    @plugin.run
    @plugin.languages[:erlang][:options].should eql(["ASYNC_THREADS", "SMP", "HIPE"])
  end
  
  it "should set languages[:erlang][:emulator]" do
    @plugin.run
    @plugin.languages[:erlang][:emulator].should eql("BEAM")
  end
  
  it "should not set the languages[:erlang] tree up if erlang command fails" do
    @status = 1
    @stdin = ""
    @stderr = "Erlang (ASYNC_THREADS,SMP,HIPE) (BEAM) emulator version 5.6.2\n"
    @plugin.stub!(:run_command).with({:no_status_check => true, :command => "erl +V"}).and_return([@status, @stdout, @stderr])
    @plugin.run
    @plugin.languages.should_not have_key(:erlang)
  end
  
end
