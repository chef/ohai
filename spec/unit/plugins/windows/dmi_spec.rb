#
# Author:: Stuart Preston (<stuart@chef.io>)
# Copyright:: Copyright (c) 2018, Chef Software Inc.
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

describe Ohai::System, "DMI", :windows_only do
  let(:plugin) { get_plugin("windows/dmi") }

  CASES = [
    ["Depth",               "depth",                  "aaa",],
    ["PartNumber",          "part_number",            "bbb",],
    ["NumberOfPowerCords",  "number_of_power_cords",  "ccc",],
    ["SKU",                 "sku",                    "ddd",],
    ["SMBIOSAssetTag",      "smbios_asset_tag",       "eee",],
    ["DeviceID",            "device_id",              "fff",],
    ["L2CacheSize",         "l2_cache_size",          "ggg",],
  ]

  before do
    require "wmi-lite/wmi"

    properties = CASES.map do |name, _, value|
      double(name: name, value: value)
    end

    wmi_ole_object = double properties_: properties

    CASES.each do |name, _, value|
      allow(wmi_ole_object).to receive(:invoke).with(name).and_return(value)
    end

    wmi_object = WmiLite::Wmi::Instance.new(wmi_ole_object)
    expect_any_instance_of(WmiLite::Wmi).to receive(:first_of).with("Win32_SystemEnclosure").and_return(wmi_object)

    empty_wmi_object = WmiLite::Wmi::Instance.new(double(properties_: []))
    %w[Processor Bios ComputerSystemProduct BaseBoard].each do |type|
      expect_any_instance_of(WmiLite::Wmi).to receive(:first_of).with("Win32_#{type}").and_return(empty_wmi_object)
    end

    plugin.run
  end

  CASES.each do |name, transformed_name, value|
    it "adds #{name} to :all_records" do
      expect(plugin[:dmi][:chassis][:all_records].first[name]).to eq(value)
    end

    it "adds #{transformed_name} to the root" do
      expect(plugin[:dmi][:chassis][transformed_name]).to eq(value)
    end
  end
end
