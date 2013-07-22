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

require 'json'
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'path', 'ohai_plugin_common.rb'))

describe Ohai::System, "plugin erlang" do

  before(:each) do
    @ohai = Ohai::System.new
    Ohai::Loader.new(@ohai).load_plugin(File.expand_path("erlang.rb", PLUGIN_PATH), "erl")
    @plugin = @ohai.plugins[:erl][:plugin].new(@ohai)
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
end

##########

expected = [{
              :env => [],
              :platform => "centos-5.9",
              :arch => "x86",
              :ohai => { :languages => { :erlang => nil }},
            },{
              :env => [:erlang],
              :platform => "centos-5.9",
              :arch => "x86",
              :ohai => { :languages => { :erlang => { :version => "5.8.5", :options => ["ASYNC_THREADS"], :emulator => "BEAM" }}},
            },{
              :env => [],
              :platform => "centos-5.9",
              :arch => "x64",
              :ohai => { :languages => { :erlang => nil }},
            },{
              :env => [:erlang],
              :platform => "centos-5.9",
              :arch => "x64",
              :ohai => { :languages => { :erlang => { :version => "5.8.5", :options => ["ASYNC_THREADS"], :emulator => "BEAM" }}},
            },{
              :env => [],
              :platform => "centos-6.4",
              :arch => "x86",
              :ohai => { :languages => { :erlang => nil }},
            },{
              :env => [:erlang],
              :platform => "centos-6.4",
              :arch => "x86",
              :ohai => { :languages => { :erlang => { :version => "5.8.5", :options => ["ASYNC_THREADS"], :emulator => "BEAM" }}},
            },{
              :env => [],
              :platform => "centos-6.4",
              :arch => "x64",
              :ohai => { :languages => { :erlang => nil }},
            },{
              :env => [:erlang],
              :platform => "centos-6.4",
              :arch => "x64",
              :ohai => { :languages => { :erlang => { :version => "5.8.5", :options => ["ASYNC_THREADS"], :emulator => "BEAM" }}},
            },{
              :env => [],
              :platform => "ubuntu-10.04",
              :arch => "x86",
              :ohai => { :languages => { :erlang => nil }},
            },{
              :env => [:erlang],
              :platform => "ubuntu-10.04",
              :arch => "x86",
              :ohai => { :languages => { :erlang => { :version => "5.7.4", :options => ["ASYNC_THREADS", "HIPE"], :emulator => "BEAM" }}},
            },{
              :env => [],
              :platform => "ubuntu-10.04",
              :arch => "x64",
              :ohai => { :languages => { :erlang => nil }},
            },{
              :env => [:erlang],
              :platform => "ubuntu-10.04",
              :arch => "x64",
              :ohai => { :languages => { :erlang => { :version => "5.7.4", :options => ["ASYNC_THREADS", "HIPE"], :emulator => "BEAM" }}},
            },{
              :env => [],
              :platform => "ubuntu-12.04",
              :arch => "x86",
              :ohai => { :languages => { :erlang => nil }},
            },{
              :env => [:erlang],
              :platform => "ubuntu-12.04",
              :arch => "x86",
              :ohai => { :languages => { :erlang => { :version => "5.8.5", :options => ["ASYNC_THREADS"], :emulator => "BEAM" }}},
            },{
              :env => [],
              :platform => "ubuntu-12.04",
              :arch => "x64",
              :ohai => { :languages => { :erlang => nil }},
            },{
              :env => [:erlang],
              :platform => "ubuntu-12.04",
              :arch => "x64",
              :ohai => { :languages => { :erlang => { :version => "5.8.5", :options => ["ASYNC_THREADS"], :emulator => "BEAM" }}},
            },{
              :env => [],
              :platform => "ubuntu-13.04",
              :arch => "x86",
              :ohai => { :languages => { :erlang => nil }},
            },{
              :env => [:erlang],
              :platform => "ubuntu-13.04",
              :arch => "x86",
              :ohai => { :languages => { :erlang => { :version => "5.9.1", :options => ["ASYNC_THREADS"], :emulator => "BEAM" }}},
            }]

describe Ohai::System, "cross platform data" do
  before (:all) do
    @opc = OhaiPluginCommon.new
    @opc.set_path '/../path'
  end

  before (:each) do
    @ohai = Ohai::System.new
  end

  expected.each do |e|
    it "should provide the expected values when the platform is '#{e[:platform]}', the architecture is '#{e[:arch]}' and the environment is '#{e[:env]}'" do
      @opc.set_env e[:platform].to_s, e[:arch].to_s, e[:env].to_json
      @ohai.require_plugin "erlang"
      @opc.subsumes? @ohai.data, e[:ohai]
    end
  end
end
