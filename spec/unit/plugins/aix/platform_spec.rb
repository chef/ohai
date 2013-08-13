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

describe Ohai::System, "Aix plugin platform" do
  before(:each) do
    @ohai = Ohai::System.new
    @plugin = Ohai::DSL::Plugin.new(@ohai, File.expand_path("aix/platform.rb", PLUGIN_PATH))
    @plugin[:kernel] = Mash.new
    @plugin[:kernel][:name] = "aix"
    @plugin[:kernel][:version] = "1"
    @plugin[:kernel][:release] = "0"
    @plugin.stub(:require_plugin).and_return(true)
    @plugin.run
  end

  it "should set platform to aix" do
    @plugin[:platform].should == "aix"
  end

  it "should set the platform_version" do
    @plugin[:platform_version].should == "1.0"
  end
end
