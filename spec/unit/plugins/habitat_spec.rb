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

require "spec_helper"

describe "plugin habitat" do
  let(:plugin) { get_plugin("habitat") }

  before do
    pkg_result = <<~PKG
      line that would not match
      origin1/package1/version1/release1
      origin2/package2/version2/release2
    PKG
    svc_result = <<~SVC
      package                           type        desired  state  elapsed (s)  pid   group
      origin1/package1/version1/release1  standalone  up       up     60       100  package1.default
      origin2/package2/version2/release2  standalone  up       up     60       101  package2.default
    SVC
    allow(plugin).to receive(:habitat_binary).and_return("/some/path/hab")
    allow(plugin).to receive(:shell_out).with(["/some/path/hab",
                                              "-V"]).and_return(mock_shell_out(0, "hab 1.1.1/202001010000", ""))
    allow(plugin).to receive(:shell_out).with(["/some/path/hab", "pkg", "list",
                                               "--all"]).and_return(mock_shell_out(0, pkg_result, ""))
    allow(plugin).to receive(:shell_out).with(["/some/path/hab", "svc", "status"]).and_return(mock_shell_out(0, svc_result, ""))
    plugin.run
  end

  it "returns the installed version of Habitat" do
    expect(plugin.habitat[:version]).to eql("1.1.1/202001010000")
  end

  it "creates an array based on the installed Habitat packages" do
    expect(plugin.habitat[:packages]).to_not include("line that would not match")
    expect(plugin.habitat[:packages]).to include("origin1/package1/version1/release1")
    expect(plugin.habitat[:packages]).to include("origin2/package2/version2/release2")
  end

  it "creates an array based on the installed Habitat services" do
    expect(plugin.habitat[:services]).to_not include("package                           type        desired  state  elapsed (s)  pid   group")
    expect(plugin.habitat[:services]).to include({
                                                   identity: "origin1/package1/version1/release1",
                                                   state_actual: "up",
                                                   state_desired: "up",
                                                   topology: "standalone",
                                                 })
    expect(plugin.habitat[:services]).to include({
                                                   identity: "origin2/package2/version2/release2",
                                                   state_actual: "up",
                                                   state_desired: "up",
                                                   topology: "standalone",
                                                 })
  end
end
