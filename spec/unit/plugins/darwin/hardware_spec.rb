#
# Author:: Nate Walck (<nate.walck@gmail.com>)
# Copyright:: Copyright (c) 2016-present Facebook, Inc.
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
require_relative "hardware_system_profiler_output.rb"

describe Ohai::System, "Darwin hardware plugin", :unix_only do
  let (:plugin) { get_plugin("darwin/hardware") }
  before(:each) do
    allow(plugin).to receive(:collect_os).and_return(:darwin)
    # Make sure it always runs correct commands and mock the data as it calls them
    allow(plugin).to receive(:shell_out).with(
      "system_profiler SPHardwareDataType -xml"
    ).and_return(
      mock_shell_out(0, HardwareSystemProfilerOutput::HARDWARE, "")
    )

    allow(plugin).to receive(:shell_out).with(
      "sw_vers -productName"
    ).and_return(
      mock_shell_out(0, "Mac OS X", "")
    )

    allow(plugin).to receive(:shell_out).with(
      "sw_vers -productVersion"
    ).and_return(
      mock_shell_out(0, "10.12", "")
    )

    allow(plugin).to receive(:shell_out).with(
      "sw_vers -buildVersion"
    ).and_return(
      mock_shell_out(0, "16A239j", "")
    )

    allow(plugin).to receive(:shell_out).with(
      "uname -m"
    ).and_return(
      mock_shell_out(0, "x86_64", "")
    )

    allow(plugin).to receive(:shell_out).with(
      "system_profiler SPStorageDataType -xml"
    ).and_return(
      mock_shell_out(0, HardwareSystemProfilerOutput::STORAGE, "")
    )

    allow(plugin).to receive(:shell_out).with(
      "system_profiler SPPowerDataType -xml"
    ).and_return(
      mock_shell_out(0, HardwareSystemProfilerOutput::POWER, "")
    )
  end

  it "parses hardware data correctly" do
    plugin.run
    expect(plugin["hardware"]["SMC_version_system"]).to eq("2.16f68")
    expect(plugin["hardware"]["boot_rom_version"]).to eq("MBP111.0138.B17")
    expect(plugin["hardware"]["cpu_type"]).to eq("Intel Core i7")
    expect(plugin["hardware"]["current_processor_speed"]).to eq("3 GHz")
    expect(plugin["hardware"]["l2_cache_core"]).to eq("256 KB")
    expect(plugin["hardware"]["l3_cache"]).to eq("4 MB")
    expect(plugin["hardware"]["machine_model"]).to eq("MacBookPro11,1")
    expect(plugin["hardware"]["machine_name"]).to eq("MacBook Pro")
    expect(plugin["hardware"]["number_processors"]).to eq(2)
    expect(plugin["hardware"]["packages"]).to eq(1)
    expect(plugin["hardware"]["physical_memory"]).to eq("16 GB")
    expect(plugin["hardware"]["platform_UUID"]).to eq("F1A4AE0F-84A8-45D8-83C7-F3F904464FC5")
    expect(plugin["hardware"]["serial_number"]).to eq("ABCDEFG12345")
  end

  it "parses sw_vers and uname data correctly" do
    plugin.run
    expect(plugin["hardware"]["operating_system"]).to eq("Mac OS X")
    expect(plugin["hardware"]["operating_system_version"]).to eq("10.12")
    expect(plugin["hardware"]["build_version"]).to eq("16A239j")
    expect(plugin["hardware"]["architecture"]).to eq("x86_64")
  end

  it "parses storage data correctly" do
    plugin.run
    expect(plugin["hardware"]["storage"][0]["name"]).to eq("Macintosh HD")
    expect(plugin["hardware"]["storage"][0]["bsd_name"]).to eq("disk1")
    expect(plugin["hardware"]["storage"][0]["capacity"]).to eq(249661751296)
    expect(plugin["hardware"]["storage"][0]["drive_type"]).to eq("ssd")
    expect(plugin["hardware"]["storage"][0]["smart_status"]).to eq("Verified")
    expect(plugin["hardware"]["storage"][0]["partitions"]).to eq(1)
  end

  it "parses storage data correctly" do
    plugin.run
    expect(plugin["hardware"]["battery"]["current_capacity"]).to eq(5841)
    expect(plugin["hardware"]["battery"]["max_capacity"]).to eq(5841)
    expect(plugin["hardware"]["battery"]["fully_charged"]).to eq(true)
    expect(plugin["hardware"]["battery"]["is_charging"]).to eq(false)
    expect(plugin["hardware"]["battery"]["charge_cycle_count"]).to eq(201)
    expect(plugin["hardware"]["battery"]["health"]).to eq("Good")
    expect(plugin["hardware"]["battery"]["serial"]).to eq("D123456789ABCDEFG")
    expect(plugin["hardware"]["battery"]["remaining"]).to eq(100)
  end
end
