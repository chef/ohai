#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Ohai::System, "AIX kernel plugin" do
  before do
    @ohai = Ohai::System.new
    @plugin = Ohai::DSL::Plugin.new(@ohai, File.expand_path("aix/kernel.rb", PLUGIN_PATH))
    @plugin.stub(:from).with("uname -s").and_return("AIX")
    @plugin.stub(:from).with("uname -r").and_return(1)
    @plugin.stub(:from).with("uname -v").and_return(6)
    @plugin.stub(:from).with("uname -p").and_return("powerpc")
    @plugin.run
    @modules = Mash.new
    @plugin[:kernel].stub(:modules).and_return(@modules)
  end

  it "uname -s detects the name" do
    @plugin[:kernel][:name].should == "aix"
  end

  it "uname -r detects the release" do
    @plugin[:kernel][:release].should == 1
  end

  it "uname -v detects the version" do
    @plugin[:kernel][:version].should == 6
  end

  it "uname -p detects the machine" do
    @plugin[:kernel][:machine].should == "powerpc"
  end

  it "detects the modules" do
    @plugin[:kernel][:modules].should == @modules
  end
end
