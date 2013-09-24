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
    @ohai[:os] = "aix"
    @ohai._require_plugin("uptime")    
    @ohai.stub(:popen4).with("who -b").and_yield(nil, StringIO.new, StringIO.new(" .  system boot  Jul  9 17:51"), nil)

    Time.stub_chain(:now, :to_i).and_return(1374258600)
    DateTime.stub_chain(:parse, :strftime, :to_i).and_return(1373392260)
    @ohai._require_plugin("aix::uptime")                    
  end

  it "should set uptime_seconds to uptime" do
    @ohai[:uptime_seconds].should == 866340
  end

  it "should set uptime to a human readable date" do
    @ohai[:uptime].should == "10 days 00 hours 39 minutes 00 seconds"
  end
end
