#
# Author:: Aliasgar Batterywala (<aliasgar.batterywala@msystechnologies.com>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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

describe Ohai::System, "Windows plugin uptime" do

  let(:plugin) { get_plugin("uptime") }
  let(:wmi) { double("wmi", { first_of: "" }) }

  before do
    allow(WmiLite::Wmi).to receive(:new).and_return(wmi)
    allow(plugin).to receive(:collect_os).and_return(:windows)
  end

  it "uses Win32_OperatingSystem WMI class to fetch the system's uptime" do
    expect(wmi).to receive(:first_of).with("Win32_OperatingSystem")
    expect(Time).to receive(:new)
    expect(Time).to receive(:parse)
    expect(plugin).to receive(:seconds_to_human)
    plugin.run
  end
end
