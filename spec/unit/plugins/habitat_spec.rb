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

  it "returns the installed version of Habitat" do
    allow(plugin).to receive(:shell_out).with("hab -V").and_return(mock_shell_out(0, "hab 1.1.1/202001010000", ""))
    plugin.run
    expect(plugin.habitat[:version]).to eql("1.1.1/202001010000")
  end

  it "Creates arrays based on the installed Habitat services and packages on Linux" do
    allow(Dir).to receive(:exist?).with("C:/hab/svc").and_return(false)
    allow(Dir).to receive(:exist?).with("/hab/svc").and_return(true)
    allow(Dir).to receive(:exist?).with("C:/hab/pkgs").and_return(false)
    allow(Dir).to receive(:exist?).with("/hab/pkgs").and_return(true)
    allow(Dir).to receive(:glob).with("/hab/svc/*").and_return(["/hab/svc/service1", "/hab/svc/service2"])
    allow(Dir).to receive(:glob).with("/hab/pkgs/*/*/*/*/").and_return(["/hab/pkgs/origin/package/version/number/"])
    plugin.run
    expect(plugin.habitat[:services]).to include("service1")
    expect(plugin.habitat[:services]).to include("service2")
    expect(plugin.habitat[:packages]).to include("origin/package/version/number")
  end

  it "Creates arrays based on the installed Habitat services and packages on Windows" do
    allow(Dir).to receive(:exist?).with("C:/hab/svc").and_return(true)
    allow(Dir).to receive(:exist?).with("/hab/svc").and_return(false)
    allow(Dir).to receive(:exist?).with("C:/hab/pkgs").and_return(true)
    allow(Dir).to receive(:exist?).with("/hab/pkgs").and_return(false)
    allow(Dir).to receive(:glob).with("C:/hab/svc/*").and_return(["C:/hab/svc/service1", "C:/hab/svc/service2"])
    allow(Dir).to receive(:glob).with("C:/hab/pkgs/*/*/*/*/").and_return(["C:/hab/pkgs/origin/package/version/number/"])
    plugin.run
    expect(plugin.habitat[:packages]).to include("origin/package/version/number")
    expect(plugin.habitat[:services]).to include("service1")
    expect(plugin.habitat[:services]).to include("service2")
  end
end
