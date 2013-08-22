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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
tmp = ENV['TMPDIR'] || ENV['TMP'] || ENV['TEMP'] || '/tmp'

describe Ohai::System, "initialize" do
  it "should return an Ohai::System object" do
    Ohai::System.new.should be_a_kind_of(Ohai::System)
  end

  it "should set @data to a Mash" do
    Ohai::System.new.data.should be_a_kind_of(Mash)
  end

  it "should set @attributes to a Hash" do
    Ohai::System.new.attributes.should be_a_kind_of(Hash)
  end
end

describe Ohai::System, "load_plugins" do
  before(:all) do
    begin
      Dir.mkdir("#{tmp}/plugins")
    rescue Errno::EEXIST
      # ignore
    end

    str = "Ohai.plugin do\nend\n"
    file = File.open("#{tmp}/plugins/plgn.rb", "w+")
    file.write(str)
    file.close

    @plugin_path = Ohai::Config[:plugin_path]
    Dir.should_receive(:[]).with("#{tmp}/plugins/*")
    Dir.should_receive(:[]).with("#{tmp}/plugins/#{Ohai::OS.collect_os}/**/*").and_return([])
  end

  before(:each) do
    @ohai = Ohai::System.new
    @ohai.stub(:from_file).and_return(true)
  end

  after(:all) do
    Ohai::Config[:plugin_path] = @plugin_path

    File.delete("#{tmp}/plugins/plgn.rb")
    begin
      Dir.delete("#{tmp}/plugins")
    rescue
      # ignore
    end
  end

  it "should load plugins when plugin_path has a trailing slash" do
    Ohai::Config[:plugin_path] = ["#{tmp}/plugins/"]
    File.stub(:expand_path).with("#{tmp}/plugins/").and_return("#{tmp}/plugins") # windows
    @ohai.load_plugins
  end

  it "should log debug message for already loaded plugin" do
    Ohai::Config[:plugin_path] = ["#{tmp}/plugins", "#{tmp}/plugins"]
    File.stub(:expand_path).with("#{tmp}/plugins").and_return("#{tmp}/plugins") # windows

    Ohai::Log.should_receive(:debug).with(/Already loaded plugin at/).once
    @ohai.load_plugins
  end

  it "should add loaded plugins to @v6_dependency_solver" do
    Ohai::Config[:plugin_path] = ["#{tmp}/plugins"]
    File.stub(:expand_path).with("#{tmp}/plugins").and_return("#{tmp}/plugins") # windows
    @ohai.load_plugins
    @ohai.v6_dependency_solver.should have_key("#{tmp}/plugins/plgn.rb")
  end
end
