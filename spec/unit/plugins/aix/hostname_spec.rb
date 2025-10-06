#
# Contributed by: Prabhu Das (<prabhu.das@clogeny.com>)
# Contributed by: Isa Farnik (<isa@chef.io>)
# Copyright © 2008-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require "spec_helper"

describe Ohai::System, "AIX hostname plugin" do
  before do
    @plugin = get_plugin("hostname")
    allow(@plugin).to receive(:collect_os).and_return(:aix)
    allow(@plugin).to receive(:resolve_fqdn).and_return("katie.bethell")
    allow(@plugin).to receive(:from_cmd).with("hostname -s").and_return("aix_admin")
    allow(@plugin).to receive(:from_cmd).with("hostname").and_return("aix_admin.ponyville.com")
    @plugin.run
  end

  it "sets the machinename" do
    expect(@plugin[:machinename]).to eql("aix_admin")
  end
end
