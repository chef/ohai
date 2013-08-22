#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Theodore Nordsieck (<theo@opscode.com>)
# Copyright:: Copyright (c) 2008-2013 Opscode, Inc.
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

require 'json'
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'path', 'ohai_plugin_common.rb'))

describe Ohai::System, "plugin erlang" do

  before(:each) do
    @plugin = get_plugin("erlang")
    @plugin[:languages] = Mash.new
    @status = 0
    @stdin = ""
    @stderr = "Erlang (ASYNC_THREADS,SMP,HIPE) (BEAM) emulator version 5.6.2\n"
    @plugin.stub(:run_command).with({:no_status_check => true, :command => "erl +V"}).and_return([@status, @stdout, @stderr])
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
    @plugin.stub(:run_command).with({:no_status_check => true, :command => "erl +V"}).and_return([@status, @stdout, @stderr])
    @plugin.run
    @plugin.languages.should_not have_key(:erlang)
  end


  ##########

  test_plugin([ "languages", "erlang" ], [ "erl" ]) do | p |
    p.test([ "centos-5.9", "centos-6.4", "ubuntu-10.04", "ubuntu-12.04" ], [ "x86", "x64" ], [[]],
           { "languages" => { "erlang" => nil }})
    p.test([ "ubuntu-13.04" ], [ "x64" ], [[]],
           { "languages" => { "erlang" => nil }})
    p.test([ "centos-5.9", "centos-6.4" ], [ "x86", "x64" ], [[ "erlang" ]],
           { "languages" => { "erlang" => { "version" => "5.8.5", "options" => [ "ASYNC_THREADS" ], "emulator" => "BEAM" }}})
    p.test([ "ubuntu-10.04" ], [ "x86", "x64" ], [[ "erlang" ]],
           { "languages" => { "erlang" => { "version" => "5.7.4", "options" => [ "ASYNC_THREADS", "HIPE" ], "emulator" => "BEAM" }}})
    p.test([ "ubuntu-12.04" ], [ "x86", "x64" ], [[ "erlang" ]],
           { "languages" => { "erlang" => { "version" => "5.8.5", "options" => [ "ASYNC_THREADS" ], "emulator" => "BEAM" }}})
    p.test([ "ubuntu-13.04" ], [ "x64" ], [[ "erlang" ]],
           { "languages" => { "erlang" => { "version" => "5.9.1", "options" => [ "ASYNC_THREADS" ], "emulator" => "BEAM" }}})
  end
end
