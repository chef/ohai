#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Author:: Isa Farnik (<isa@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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
require_relative "../../../spec_helper.rb"

describe Ohai::System, "Aix plugin uptime" do

  before(:each) do
    @plugin = get_plugin("aix/uptime")
    allow(@plugin).to receive(:collect_os).and_return(:aix)
    allow(Time).to receive_message_chain(:now, :to_i).and_return(1412072511)
    allow(Time).to receive_message_chain(:now, :zone).and_return("IST")
    allow(DateTime).to receive_message_chain(:parse, :strftime, :to_i).and_return(1411561320)
    allow(@plugin).to receive(:shell_out).with("who -b").and_return(mock_shell_out(0, "   .        system boot Sep 24 17:52", nil))

    @plugin.run
  end

  it "should set uptime_seconds to uptime" do
    expect(@plugin[:uptime_seconds]).to eq(511191)
  end

  it "should set uptime to a human readable date" do
    expect(@plugin[:uptime]).to eq("5 days 21 hours 59 minutes 51 seconds")
  end
end
