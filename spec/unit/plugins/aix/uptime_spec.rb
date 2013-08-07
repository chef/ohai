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
#
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Ohai::System, "Aix plugin uptime" do

  before(:each) do
    @ohai = Ohai::System.new
    @plugin = Ohai::DSL::Plugin.new(@ohai, File.expand_path("aix/uptime.rb", PLUGIN_PATH))
    @plugin[:os] = "aix"
    @plugin.stub(:popen4).with("who -b").and_yield(nil, StringIO.new, StringIO.new(" .  system boot  Jul  9 17:51"), nil)
    Time.stub_chain(:now, :to_i).and_return(1375857797)
  end

  it "should set uptime_seconds to uptime" do
    @plugin.run
    @plugin[:uptime_seconds].should == 2465537
  end

  it "should set uptime to a human readable date" do
    @plugin.run
    @plugin[:uptime].should == "28 days 12 hours 52 minutes 17 seconds"
  end
end
