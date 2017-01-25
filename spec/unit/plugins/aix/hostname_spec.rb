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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "AIX hostname plugin" do
  before(:each) do
    @plugin = get_plugin("hostname")
    allow(@plugin).to receive(:collect_os).and_return(:aix)
    allow(@plugin).to receive(:from_cmd).with("hostname -s").and_return("aix_admin")
    allow(@plugin).to receive(:from_cmd).with("hostname").and_return("aix_admin.ponyville.com")
    @plugin.run
  end

  it "should set the machinename" do
    expect(@plugin[:machinename]).to eql("aix_admin")
  end
end
