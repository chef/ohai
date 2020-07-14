# frozen_string_literal: true
#
# Author:: Pete Higgins (pete@peterhiggins.org)
# Copyright:: Copyright (c) Chef Software Inc.
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

  before do
    require "wmi-lite/wmi"

    empty_wmi_object = WmiLite::Wmi::Instance.new(double(properties_: []))
    %w{Processor Bios ComputerSystemProduct BaseBoard}.each do |type|
      expect_any_instance_of(WmiLite::Wmi).to receive(:instances_of).with("Win32_#{type}").and_return([empty_wmi_object])
    end
  end

  context "when property names are different types of camel casing" do
    # Each test case has 3 elements:
    # * The name of the property as it comes from the Windows APIs
    # * The transformed snake-case version of the property name
    # * A unique dummy value per test case
    CASES = [
      %w{Depth depth aaa},
      %w{PartNumber part_number bbb},
      %w{NumberOfPowerCords number_of_power_cords ccc},
      %w{SKU sku ddd},
      %w{SMBIOSAssetTag smbios_asset_tag eee},
      %w{DeviceID device_id fff},
      %w{L2CacheSize l2_cache_size ggg},
    ].freeze

    before do
      properties = CASES.map { |name, _, _| double(name: name) }
      wmi_ole_object = double properties_: properties

      CASES.each do |name, _, value|
        allow(wmi_ole_object).to receive(:invoke).with(name).and_return(value)
      end

      wmi_object = WmiLite::Wmi::Instance.new(wmi_ole_object)
      expect_any_instance_of(WmiLite::Wmi).to receive(:instances_of).with("Win32_SystemEnclosure").and_return([wmi_object])

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

  context "when multiple objects of one type are returned from the Windows API" do
    before do
      properties = [
        double(name: "UniqueProperty"),
        double(name: "SharedProperty"),
      ]

      wmi_ole_objects = %w{tacos nachos}.map do |value|
        object = double properties_: properties
        allow(object).to receive(:invoke).with("UniqueProperty").and_return(value)
        allow(object).to receive(:invoke).with("SharedProperty").and_return("Taco Bell")
        object
      end

      wmi_objects = wmi_ole_objects.map { |o| WmiLite::Wmi::Instance.new(o) }
      expect_any_instance_of(WmiLite::Wmi).to receive(:instances_of).with("Win32_SystemEnclosure").and_return(wmi_objects)

      plugin.run
    end

    it "adds unique values to :all_records" do
      values = plugin[:dmi][:chassis][:all_records].map { |r| r["UniqueProperty"] }
      expect(values).to eq(%w{tacos nachos})
    end

    it "adds shared values to the root with snake case key" do
      expect(plugin[:dmi][:chassis]["shared_property"]).to eq("Taco Bell")
    end
  end

  context "with extra information that should be filtered out" do
    # Each test case has 3 elements:
    # * The name of the property as it comes from the Windows APIs
    # * The transformed snake-case version of the property name
    # * A unique dummy value per test case
    FILTERED_KEYS = [
      %w{Caption caption aaa},
      %w{CreationClassName creation_class_name bbb},
      %w{SystemCreationClassName system_creation_class_name ccc},
    ].freeze

    before do
      properties = FILTERED_KEYS.map { |name, _, _| double(name: name) }
      wmi_ole_object = double properties_: properties

      FILTERED_KEYS.each do |name, _, value|
        allow(wmi_ole_object).to receive(:invoke).with(name).and_return(value)
      end

      wmi_object = WmiLite::Wmi::Instance.new(wmi_ole_object)
      expect_any_instance_of(WmiLite::Wmi).to receive(:instances_of).with("Win32_SystemEnclosure").and_return([wmi_object])

      plugin.run
    end

    FILTERED_KEYS.each do |name, transformed_name, value|
      it "adds #{name} to :all_records" do
        expect(plugin[:dmi][:chassis][:all_records].first[name]).to eq(value)
      end

      it "does not add #{transformed_name} to the root" do
        expect(plugin[:dmi][:chassis]).not_to have_key(transformed_name)
      end
    end
  end

  context "with information that should be made to match other platforms" do
    # Each test case has 4 elements:
    # * The name of the property as it comes from the Windows APIs
    # * The transformed snake-case version of the property name
    # * The Unix equivalent of the property name
    # * A unique dummy value per test case
    RENAMED_KEYS = [
      %w{Vendor vendor manufacturer aaa},
      %w{IdentifyingNumber identifying_number serial_number bbb},
      %w{Name name family ccc},
    ].freeze

    before do
      properties = RENAMED_KEYS.map { |name, _, _, _| double(name: name) }
      wmi_ole_object = double properties_: properties

      RENAMED_KEYS.each do |name, _, _, value|
        allow(wmi_ole_object).to receive(:invoke).with(name).and_return(value)
      end

      wmi_object = WmiLite::Wmi::Instance.new(wmi_ole_object)
      expect_any_instance_of(WmiLite::Wmi).to receive(:instances_of).with("Win32_SystemEnclosure").and_return([wmi_object])

      plugin.run
    end

    RENAMED_KEYS.each do |name, transformed_name, renamed_name, value|
      it "adds #{name} to :all_records" do
        expect(plugin[:dmi][:chassis][:all_records].first[name]).to eq(value)
      end

      it "adds #{renamed_name} to the root" do
        expect(plugin[:dmi][:chassis][renamed_name]).to eq(value)
      end

      it "does not add #{transformed_name} to the root" do
        expect(plugin[:dmi][:chassis]).not_to have_key(transformed_name)
      end
    end
  end
end
