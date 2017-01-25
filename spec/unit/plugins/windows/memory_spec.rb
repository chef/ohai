#
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

describe Ohai::System, "Windows memory plugin", :windows_only do
  before do
    require "wmi-lite/wmi"
    @plugin = get_plugin("windows/memory")
    mock_os = {
                "TotalVisibleMemorySize" => "10485760",
                "FreePhysicalMemory" => "5242880",
                "SizeStoredInPagingFiles" => "20971520",
                "FreeSpaceInPagingFiles" =>  "15728640",
              }
    expect_any_instance_of(WmiLite::Wmi).to receive(:first_of).with("Win32_OperatingSystem").and_return(mock_os)
  end

  it "should get total memory" do
    @plugin.run
    expect(@plugin["memory"]["total"]).to eql("10485760kB")
  end

  it "should get free memory" do
    @plugin.run
    expect(@plugin["memory"]["free"]).to eql("5242880kB")
  end

  it "should get total swap" do
    @plugin.run
    expect(@plugin["memory"]["swap"]["total"]).to eql("20971520kB")
  end

  it "should get free memory" do
    @plugin.run
    expect(@plugin["memory"]["swap"]["free"]).to eql("15728640kB")
  end

end
