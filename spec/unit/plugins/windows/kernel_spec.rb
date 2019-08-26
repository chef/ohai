#
# Copyright:: Copyright (c) 2018 Chef Software, Inc.
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

describe Ohai::System, "Windows kernel plugin", :windows_only do
  let(:plugin) { get_plugin("kernel") }

  before do
    require "wmi-lite/wmi"

    # Mock a Win32_OperatingSystem OLE32 WMI object
    caption = double("WIN32OLE", name: "Caption")
    version = double("WIN32OLE", name: "Version")
    build_number = double("WIN32OLE", name: "BuildNumber")
    csd_version  = double("WIN32OLE", name: "CsdVersion")
    os_type = double("WIN32OLE", name: "OsType")
    product_type = double("WIN32OLE", name: "ProductType")
    operating_system_sku = double("WIN32OLE", name: "OperatingSystemSKU")
    os_properties = [ caption, version, build_number, csd_version, os_type, product_type, operating_system_sku ]

    os = double( "WIN32OLE",
      properties_: os_properties)

    allow(os).to receive(:invoke).with(build_number.name).and_return("7601")
    allow(os).to receive(:invoke).with(csd_version.name).and_return("Service Pack 1")
    allow(os).to receive(:invoke).with(os_type.name).and_return(18)
    allow(os).to receive(:invoke).with(caption.name).and_return("Microsoft Windows 7 Ultimate")
    allow(os).to receive(:invoke).with(version.name).and_return("6.1.7601")
    allow(os).to receive(:invoke).with(product_type.name).and_return(1)
    allow(os).to receive(:invoke).with(operating_system_sku.name).and_return(48)

    os_wmi = WmiLite::Wmi::Instance.new(os)
    expect_any_instance_of(WmiLite::Wmi).to receive(:first_of).with("Win32_OperatingSystem").and_return(os_wmi)

    system_type = double("WIN32OLE", name: "SystemType")
    pc_system_type = double("WIN32OLE", name: "PCSystemType")
    free_virtual_memory = double("WIN32OLE", name: "FreeVirtualMemory")
    cs_properties = [ system_type, pc_system_type, free_virtual_memory]

    cs = double("WIN32OLE",
      properties_: cs_properties)

    allow(cs).to receive(:invoke).with(system_type.name).and_return("x64-based PC")
    allow(cs).to receive(:invoke).with(pc_system_type.name).and_return(2)
    allow(cs).to receive(:invoke).with(free_virtual_memory.name).and_return("Why would you want this data here?")

    cs_wmi = WmiLite::Wmi::Instance.new(cs)
    expect_any_instance_of(WmiLite::Wmi).to receive(:first_of).with("Win32_ComputerSystem").and_return(cs_wmi)

    plugin.run
  end

  it "sets the correct system information" do
    expect(plugin[:kernel][:name]).to eq("Microsoft Windows 7 Ultimate")
    expect(plugin[:kernel][:release]).to eq("6.1.7601")
    expect(plugin[:kernel][:version]).to eq("6.1.7601 Service Pack 1 Build 7601")
    expect(plugin[:kernel][:os]).to eq("WINNT")
    expect(plugin[:kernel][:machine]).to eq("x86_64")
    expect(plugin[:kernel][:system_type]).to eq("Mobile")
    expect(plugin[:kernel][:product_type]).to eq("Workstation")
    expect(plugin[:kernel][:server_core]).to eq(false)
    expect(plugin[:kernel]).not_to have_key(:free_virtual_memory)
  end
end
