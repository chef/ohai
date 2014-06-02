#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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


require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Ohai::System, "plugin kernel" do
  before(:each) do
    @plugin = get_plugin("kernel")
    @plugin.stub(:collect_os).and_return(:default) # for debugging
    @plugin.stub(:shell_out).with("uname -s").and_return(mock_shell_out(0, "Darwin\n", ""))
    @plugin.stub(:shell_out).with("uname -r").and_return(mock_shell_out(0, "9.5.0\n", ""))
    @plugin.stub(:shell_out).with("uname -v").and_return(mock_shell_out(0, "Darwin Kernel Version 9.5.0: Wed Sep  3 11:29:43 PDT 2008; root:xnu-1228.7.58~1\/RELEASE_I386\n", ""))
    @plugin.stub(:shell_out).with("uname -m").and_return(mock_shell_out(0, "i386\n", ""))
    @plugin.stub(:shell_out).with("uname -o").and_return(mock_shell_out(0, "Linux\n", ""))
  end

  it_should_check_from_mash("kernel", "name", "uname -s", [0, "Darwin\n", ""])
  it_should_check_from_mash("kernel", "release", "uname -r", [0, "9.5.0\n", ""])
  it_should_check_from_mash("kernel", "version", "uname -v", [0, "Darwin Kernel Version 9.5.0: Wed Sep  3 11:29:43 PDT 2008; root:xnu-1228.7.58~1\/RELEASE_I386\n", ""])
  it_should_check_from_mash("kernel", "machine", "uname -m", [0, "i386\n", ""])

  describe "when running on windows", :windows_only do
    before do
      require 'wmi-lite/wmi'

      @ohai_system = Ohai::System.new
      @plugin = get_plugin("kernel", @ohai_system)

      # Mock a Win32_OperatingSystem OLE32 WMI object
      caption = double("WIN32OLE", :name => "Caption")
      version = double("WIN32OLE", :name => "Version")
      build_number = double("WIN32OLE", :name => "BuildNumber")
      csd_version  = double("WIN32OLE", :name => "CsdVersion")
      os_type = double("WIN32OLE", :name => "OsType")
      os_properties = [ caption, version, build_number, csd_version, os_type ]

      os =  double( "WIN32OLE",
                    :properties_ => os_properties)

      os.stub(:invoke).with(build_number.name).and_return('7601')
      os.stub(:invoke).with(csd_version.name).and_return('Service Pack 1')
      os.stub(:invoke).with(os_type.name).and_return(18)
      os.stub(:invoke).with(caption.name).and_return('Microsoft Windows 7 Ultimate')
      os.stub(:invoke).with(version.name).and_return('6.1.7601')

      os_wmi = WmiLite::Wmi::Instance.new(os)

      WmiLite::Wmi.any_instance.should_receive(:first_of).with('Win32_OperatingSystem').and_return(os_wmi)

      # Mock a Win32_ComputerSystem OLE32 WMI object
      x64_system_type = 'x64-based PC'

      cs = double("WIN32OLE",
                  :properties_ => [ double("WIN32OLE", :name => "SystemType") ])

      cs.stub(:invoke).with('SystemType').and_return(x64_system_type)

      cs_wmi = WmiLite::Wmi::Instance.new(cs)

      WmiLite::Wmi.any_instance.should_receive(:first_of).with('Win32_ComputerSystem').and_return(cs_wmi)
      WmiLite::Wmi.any_instance.should_receive(:instances_of).with('Win32_PnPSignedDriver').and_return([])

      @plugin.run
    end
    it "should set the corrent system information" do
      @ohai_system.data[:kernel][:name].should == "Microsoft Windows 7 Ultimate"
      @ohai_system.data[:kernel][:release].should == "6.1.7601"
      @ohai_system.data[:kernel][:version].should == "6.1.7601 Service Pack 1 Build 7601"
      @ohai_system.data[:kernel][:os].should == "WINNT"
      @ohai_system.data[:kernel][:machine].should == "x86_64"
    end
  end

end
