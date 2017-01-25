#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
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

require_relative "../../spec_helper.rb"

describe Ohai::System, "plugin kernel" do
  before(:each) do
    @plugin = get_plugin("kernel")
    allow(@plugin).to receive(:collect_os).and_return(:default) # for debugging
    allow(@plugin).to receive(:shell_out).with("uname -s").and_return(mock_shell_out(0, "Darwin\n", ""))
    allow(@plugin).to receive(:shell_out).with("uname -r").and_return(mock_shell_out(0, "9.5.0\n", ""))
    allow(@plugin).to receive(:shell_out).with("uname -v").and_return(mock_shell_out(0, "Darwin Kernel Version 9.5.0: Wed Sep  3 11:29:43 PDT 2008; root:xnu-1228.7.58~1\/RELEASE_I386\n", ""))
    allow(@plugin).to receive(:shell_out).with("uname -m").and_return(mock_shell_out(0, "i386\n", ""))
    allow(@plugin).to receive(:shell_out).with("uname -o").and_return(mock_shell_out(0, "Linux\n", ""))
    allow(@plugin).to receive(:shell_out).with("uname -p").and_return(mock_shell_out(0, "i386\n", ""))
  end

  it_should_check_from_mash("kernel", "name", "uname -s", [0, "Darwin\n", ""])
  it_should_check_from_mash("kernel", "release", "uname -r", [0, "9.5.0\n", ""])
  it_should_check_from_mash("kernel", "version", "uname -v", [0, "Darwin Kernel Version 9.5.0: Wed Sep  3 11:29:43 PDT 2008; root:xnu-1228.7.58~1\/RELEASE_I386\n", ""])
  it_should_check_from_mash("kernel", "machine", "uname -m", [0, "i386\n", ""])
  it_should_check_from_mash("kernel", "processor", "uname -p", [0, "i386\n", ""])

  describe "when running on windows", :windows_only do
    before do
      require "wmi-lite/wmi"

      @ohai_system = Ohai::System.new
      @plugin = get_plugin("kernel", @ohai_system)

      # Mock a Win32_OperatingSystem OLE32 WMI object
      caption = double("WIN32OLE", :name => "Caption")
      version = double("WIN32OLE", :name => "Version")
      build_number = double("WIN32OLE", :name => "BuildNumber")
      csd_version  = double("WIN32OLE", :name => "CsdVersion")
      os_type = double("WIN32OLE", :name => "OsType")
      os_properties = [ caption, version, build_number, csd_version, os_type ]

      os = double( "WIN32OLE",
                    :properties_ => os_properties)

      allow(os).to receive(:invoke).with(build_number.name).and_return("7601")
      allow(os).to receive(:invoke).with(csd_version.name).and_return("Service Pack 1")
      allow(os).to receive(:invoke).with(os_type.name).and_return(18)
      allow(os).to receive(:invoke).with(caption.name).and_return("Microsoft Windows 7 Ultimate")
      allow(os).to receive(:invoke).with(version.name).and_return("6.1.7601")

      os_wmi = WmiLite::Wmi::Instance.new(os)

      expect_any_instance_of(WmiLite::Wmi).to receive(:first_of).with("Win32_OperatingSystem").and_return(os_wmi)

      # Mock a Win32_ComputerSystem OLE32 WMI object
      x64_system_type = "x64-based PC"

      cs = double("WIN32OLE",
                  :properties_ => [ double("WIN32OLE", :name => "SystemType") ])

      allow(cs).to receive(:invoke).with("SystemType").and_return(x64_system_type)

      cs_wmi = WmiLite::Wmi::Instance.new(cs)

      expect_any_instance_of(WmiLite::Wmi).to receive(:first_of).with("Win32_ComputerSystem").and_return(cs_wmi)

      @plugin.run
    end
    it "should set the correct system information" do
      expect(@ohai_system.data[:kernel][:name]).to eq("Microsoft Windows 7 Ultimate")
      expect(@ohai_system.data[:kernel][:release]).to eq("6.1.7601")
      expect(@ohai_system.data[:kernel][:version]).to eq("6.1.7601 Service Pack 1 Build 7601")
      expect(@ohai_system.data[:kernel][:os]).to eq("WINNT")
      expect(@ohai_system.data[:kernel][:machine]).to eq("x86_64")
    end
  end

end
