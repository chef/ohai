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
    @plugin = get_plugin("aix/uptime")
    @plugin.stub(:collect_os).and_return(:aix)
    Time.stub_chain(:now, :to_i).and_return(1412072511)
    Time.stub_chain(:now, :zone).and_return("IST")
    DateTime.stub_chain(:parse, :strftime, :to_i).and_return(1411561320)
    @plugin.stub(:shell_out).with("who -b").and_return(mock_shell_out(0, "   .        system boot Sep 24 17:52", nil))

    @plugin.run
  end

  it "should set uptime_seconds to uptime" do
    @plugin[:uptime_seconds].should == 511191
  end

  it "should set uptime to a human readable date" do
    @plugin[:uptime].should == "5 days 21 hours 59 minutes 51 seconds"
  end
end
