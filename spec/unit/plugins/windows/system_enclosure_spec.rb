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

describe Ohai::System, "System Enclosure", :windows_only do
  before do
    require "wmi-lite/wmi"
    @plugin = get_plugin("windows/system_enclosure")
    manufacturer = double("WIN32OLE", name: "manufacturer", value: "My Fake Manufacturer")
    serialnumber = double("WIN32OLE", name: "serialnumber", value: "1234123412341234")
    property_map = [ manufacturer, serialnumber ]

    wmi_ole_object = double( "WIN32OLE", properties_: property_map)
    allow(wmi_ole_object).to receive(:invoke).with(manufacturer.name).and_return(manufacturer.value)
    allow(wmi_ole_object).to receive(:invoke).with(serialnumber.name).and_return(serialnumber.value)
    wmi_object = WmiLite::Wmi::Instance.new(wmi_ole_object)
    expect_any_instance_of(WmiLite::Wmi).to receive(:first_of).with(("Win32_SystemEnclosure")).and_return(wmi_object)
  end

  it "returns the manufacturer" do
    @plugin.run
    expect(@plugin["system_enclosure"]["manufacturer"]).to eql("My Fake Manufacturer")
  end

  it "returns a serial number" do
    @plugin.run
    expect(@plugin["system_enclosure"]["serialnumber"]).to eql("1234123412341234")
  end
end
