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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "Windows plugin uptime" do

  let(:wmi) { double("wmi", { :first_of => "" }) }

  before(:each) do
    allow(WmiLite::Wmi).to receive(:new).and_return(wmi)
  end

  ## Windows newer versions category here includes server OS starting from Windows Server 2008 ##
  shared_context "WMI class for newer versions of Windows platform" do
    before do
      allow(uptime_plugin).to receive(:collect_os).and_return(:windows)
    end

    it "uses Win32_OperatingSystem WMI class to fetch the system's uptime" do
      expect(wmi).to receive(:first_of).with("Win32_OperatingSystem")
      expect(Time).to receive(:new)
      expect(Time).to receive(:parse)
      expect(uptime_plugin).to receive(:seconds_to_human)
      uptime_plugin.run
    end
  end

  ## Windows older versions category here includes server OS starting from Windows Server 2003 ##
  shared_context "WMI class for older versions of Windows platform" do
    before do
      allow(uptime_plugin).to receive(:collect_os).and_return(:windows)
    end

    it "uses Win32_PerfFormattedData_PerfOS_System WMI class to fetch the system's uptime" do
      expect(wmi).to receive(:first_of).with("Win32_PerfFormattedData_PerfOS_System")
      expect(Time).to_not receive(:new)
      expect(Time).to_not receive(:parse)
      expect(uptime_plugin).to receive(:seconds_to_human)
      uptime_plugin.run
    end
  end

  context "platform is Windows Server 2008 R2" do
    let(:uptime_plugin) do
      get_plugin("uptime").tap do |plugin|
        plugin[:platform_version] = "6.1.7601"
      end
    end

    include_context "WMI class for newer versions of Windows platform"
  end

  context "platform is Windows Server 2003 R2" do
    let(:uptime_plugin) do
      get_plugin("uptime").tap do |plugin|
        plugin[:platform_version] = "5.2.3790"
      end
    end

    include_context "WMI class for older versions of Windows platform"
  end

  context "platform is Windows Server 2012" do
    let(:uptime_plugin) do
      get_plugin("uptime").tap do |plugin|
        plugin[:platform_version] = "6.2.9200"
      end
    end

    include_context "WMI class for newer versions of Windows platform"
  end
end
