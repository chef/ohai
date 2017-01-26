#
# Author:: Paul Mooring (<paul@chef.io>)
# Copyright:: Copyright (c) 2012-2016 Chef Software, Inc.
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
require_relative "system_profiler_output.rb"

describe Ohai::System, "Darwin system_profiler plugin", :unix_only do
  before(:each) do
    @plugin = get_plugin("darwin/system_profiler")
    allow(@plugin).to receive(:collect_os).and_return(:darwin)
  end

  it "should return the right serial number" do
    mini_cmd = "system_profiler -xml -detailLevel mini SPParallelATAData SPAudioData SPBluetoothData"
    mini_cmd += " SPCardReaderData SPDiagnosticsData SPDiscBurningData SPEthernetData SPFibreChannelData"
    mini_cmd += " SPFireWireData SPDisplaysData SPHardwareRAIDData SPMemoryData SPModemData SPNetworkData"
    mini_cmd += " SPPCIData SPParallelSCSIData SPPrintersSoftwareData SPPrintersData SPSASData SPSerialATAData"
    mini_cmd += " SPSoftwareData SPThunderboltData SPUSBData SPWWANData SPAirPortData"
    full_cmd = "system_profiler -xml -detailLevel full SPHardwareDataType"
    allow(@plugin).to receive(:shell_out).with(full_cmd).and_return(mock_shell_out(0, SystemProfilerOutput::Full, ""))
    allow(@plugin).to receive(:shell_out).with(mini_cmd).and_return(mock_shell_out(0, SystemProfilerOutput::Mini, ""))
    @plugin.run
    expect(@plugin["system_profile"][18]["_items"][0]["serial_number"]).to eq("ABCDEFG12345")
  end
end
