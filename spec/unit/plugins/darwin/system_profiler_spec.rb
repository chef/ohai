#
# Author:: Paul Mooring (<paul@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path("#{File.dirname(__FILE__)}/system_profiler_output.rb")

begin
  require 'plist'
rescue LoadError => e
  puts "The darwin systemprofile plugin spec tests will fail without the 'plist' library/gem.\n\n"
  raise e
end

describe Ohai::System, "Darwin system_profiler plugin", :unix_only do
  before(:each) do
    @ohai = Ohai::System.new

    @ohai.stub!(:require_plugin).and_return(true)
  end
  
  it "should return the right serial number" do
    mini_cmd = "system_profiler -xml -detailLevel mini SPParallelATAData SPAudioData SPBluetoothData"
    mini_cmd += " SPCardReaderData SPDiagnosticsData SPDiscBurningData SPEthernetData SPFibreChannelData"
    mini_cmd += " SPFireWireData SPDisplaysData SPHardwareRAIDData SPMemoryData SPModemData SPNetworkData"
    mini_cmd += " SPPCIData SPParallelSCSIData SPPrintersSoftwareData SPPrintersData SPSASData SPSerialATAData"
    mini_cmd += " SPSoftwareData SPThunderboltData SPUSBData SPWWANData SPAirPortData"
    full_cmd = "system_profiler -xml -detailLevel full SPHardwareDataType"
    @ohai.stub!(:popen4).with(full_cmd).and_yield(nil, StringIO.new, StringIO.new(SystemProfilerOutput::Full), nil)
    @ohai.stub!(:popen4).with(mini_cmd).and_yield(nil, StringIO.new, StringIO.new(SystemProfilerOutput::Mini), nil)
    @ohai._require_plugin("darwin::system_profiler")
    @ohai['system_profile'][18]["_items"][0]["serial_number"].should == 'ABCDEFG12345'
  end
end
