# frozen_string_literal: true
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright (c) 2026 Tim Smith
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
require "ohai/mixin/smbios"

describe Ohai::Mixin::Smbios do
  let(:mixin) do
    Object.new.tap do |o|
      o.extend(described_class)
      o.define_singleton_method(:logger) { Ohai::Log }
      o.define_singleton_method(:file_exist?) { |_path| false }
      o.define_singleton_method(:file_read) { |_path| raise "unexpected read" }
      o.define_singleton_method(:shell_out) { |_cmd| raise "unexpected command" }
    end
  end

  def command_result(stdout, exitstatus = 0)
    double("Mixlib::ShellOut", stdout: stdout, exitstatus: exitstatus)
  end

  context "on Linux" do
    before { stub_const("RUBY_PLATFORM", "x86_64-linux") }

    it "reads the value from /sys/class/dmi/id" do
      allow(mixin).to receive(:file_exist?).with("/sys/class/dmi/id/sys_vendor").and_return(true)
      allow(mixin).to receive(:file_read).with("/sys/class/dmi/id/sys_vendor").and_return("Amazon EC2\n")
      expect(mixin.smbios_value(:sys_vendor)).to eq("Amazon EC2")
    end

    it "returns nil when the file doesn't exist" do
      expect(mixin.smbios_value(:chassis_asset_tag)).to be_nil
    end

    it "returns nil when the file is root-only" do
      allow(mixin).to receive(:file_exist?).with("/sys/class/dmi/id/product_serial").and_return(true)
      allow(mixin).to receive(:file_read).with("/sys/class/dmi/id/product_serial").and_raise(Errno::EACCES)
      expect(mixin.smbios_value(:product_serial)).to be_nil
    end

    it "returns nil for an empty value" do
      allow(mixin).to receive(:file_exist?).with("/sys/class/dmi/id/chassis_asset_tag").and_return(true)
      allow(mixin).to receive(:file_read).with("/sys/class/dmi/id/chassis_asset_tag").and_return(" \n")
      expect(mixin.smbios_value(:chassis_asset_tag)).to be_nil
    end

    it "reads each field only once" do
      expect(mixin).to receive(:file_exist?).with("/sys/class/dmi/id/product_name").once.and_return(true)
      expect(mixin).to receive(:file_read).with("/sys/class/dmi/id/product_name").once.and_return("Droplet")
      2.times { expect(mixin.smbios_value(:product_name)).to eq("Droplet") }
    end
  end

  context "on FreeBSD" do
    before { stub_const("RUBY_PLATFORM", "amd64-freebsd14") }

    it "reads the value with kenv" do
      allow(mixin).to receive(:shell_out).with("kenv -q smbios.system.maker").and_return(command_result("Amazon EC2\n"))
      expect(mixin.smbios_value(:sys_vendor)).to eq("Amazon EC2")
    end

    it "returns nil when kenv doesn't know the variable" do
      allow(mixin).to receive(:shell_out).with("kenv -q smbios.chassis.tag").and_return(command_result("", 1))
      expect(mixin.smbios_value(:chassis_asset_tag)).to be_nil
    end
  end

  context "on OpenBSD" do
    before { stub_const("RUBY_PLATFORM", "x86_64-openbsd7.5") }

    it "reads the value with sysctl" do
      allow(mixin).to receive(:shell_out).with("sysctl -n hw.vendor").and_return(command_result("Google\n"))
      expect(mixin.smbios_value(:sys_vendor)).to eq("Google")
    end

    it "returns nil without running anything for a field OpenBSD doesn't expose" do
      expect(mixin).not_to receive(:shell_out)
      expect(mixin.smbios_value(:bios_vendor)).to be_nil
    end
  end

  context "on NetBSD" do
    before { stub_const("RUBY_PLATFORM", "x86_64-netbsd") }

    it "reads the value from the machdep.dmi sysctl tree" do
      allow(mixin).to receive(:shell_out).with("sysctl -n machdep.dmi.system-product").and_return(command_result("OpenStack Nova\n"))
      expect(mixin.smbios_value(:product_name)).to eq("OpenStack Nova")
    end
  end

  context "on Windows" do
    before { stub_const("RUBY_PLATFORM", "x64-mingw-ucrt") }

    let(:wmi) { double("WmiLite::Wmi") }

    before do
      stub_const("WmiLite::Wmi", double(new: wmi))
    end

    it "reads the value from WMI" do
      allow(wmi).to receive(:first_of).with("Win32_SystemEnclosure").and_return({ "smbiosassettag" => "7783-7084-3265-9085-8269-3286-77" })
      expect(mixin.smbios_value(:chassis_asset_tag)).to eq("7783-7084-3265-9085-8269-3286-77")
    end

    it "returns nil when WMI has no instance" do
      allow(wmi).to receive(:first_of).with("Win32_ComputerSystemProduct").and_return(nil)
      expect(mixin.smbios_value(:sys_vendor)).to be_nil
    end

    it "returns nil when WMI raises" do
      allow(wmi).to receive(:first_of).and_raise(StandardError, "WMI is unavailable")
      expect(mixin.smbios_value(:bios_vendor)).to be_nil
    end
  end
end
