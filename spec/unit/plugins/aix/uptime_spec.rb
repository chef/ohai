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
    allow(@plugin).to receive(:shell_out).and_call_original
    allow(@plugin).to receive(:shell_out).with("LC_ALL=POSIX ps -o etime= -p 1").and_return(mock_shell_out(0, "1148-20:54:50", nil))
    @plugin.run
  end

  it "should set uptime_seconds to uptime with days" do
    expect(@plugin[:uptime_seconds]).to eq(99262490)
  end

  it "should set uptime to a human readable date with days" do
    expect(@plugin[:uptime]).to eq("1148 days 20 hours 54 minutes 50 seconds")
  end
end
