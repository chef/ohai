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
      o.extend(Ohai::Mixin::OS)
      o.extend(described_class)
      o.define_singleton_method(:logger) { Ohai::Log }
      o.define_singleton_method(:target_mode?) { false }
      o.define_singleton_method(:file_exist?) { |_path| false }
      o.define_singleton_method(:file_read) { |_path| raise "unexpected read" }
      o.define_singleton_method(:shell_out) { |_cmd| raise "unexpected command" }
    end
  end

  def command_result(stdout, exitstatus = 0)
    double("Mixlib::ShellOut", stdout: stdout, exitstatus: exitstatus)
  end

  context "on Linux" do
    before { allow(mixin).to receive(:collect_os_local).and_return("linux") }

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
    before { allow(mixin).to receive(:collect_os_local).and_return("freebsd") }

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
    before { allow(mixin).to receive(:collect_os_local).and_return("openbsd") }

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
    before { allow(mixin).to receive(:collect_os_local).and_return("netbsd") }

    it "reads the value from the machdep.dmi sysctl tree" do
      allow(mixin).to receive(:shell_out).with("sysctl -n machdep.dmi.system-product").and_return(command_result("OpenStack Nova\n"))
      expect(mixin.smbios_value(:product_name)).to eq("OpenStack Nova")
    end
  end

  context "on Solaris" do
    before { allow(mixin).to receive(:collect_os_local).and_return("solaris2") }

    # smbios(8) output from Oracle Solaris 11.4 on an OCI VM.Standard.E5.Flex
    let(:smbios_chassis) do
      <<~OUTPUT
        ID    SIZE TYPE
        768   53   SMB_TYPE_CHASSIS (system enclosure or chassis)

          Manufacturer: QEMU
          Version: pc-q35-7.2
          Asset Tag: OracleCloud.com

          SKU Number:#{" "}
          OEM Data: 0x0
          Lock Present: N
          Chassis Type: 0x1 (other)
      OUTPUT
    end

    let(:smbios_system) do
      <<~OUTPUT
        ID    SIZE TYPE
        256   73   SMB_TYPE_SYSTEM (system information)

          Manufacturer: QEMU
          Product: Standard PC (Q35 + ICH9, 2009)
          Version: pc-q35-7.2

          UUID: 1c3a2f9e-5b7d-4e61-9a0c-2d8f6b4e7a13
          Wake-Up Event: 0x6 (power switch)
          SKU Number:#{" "}
          Family:#{" "}
      OUTPUT
    end

    let(:smbios_bios) do
      <<~OUTPUT
        ID    SIZE TYPE
        0     53   SMB_TYPE_BIOS (BIOS information)

          Vendor: Oracle
          Version String: 20260902
          Release Date: Sep-02-2026
          Characteristics Extension Byte 2: 0x1c
        	SMB_BIOSXB2_VIRT (SMBIOS describes a virtual machine)
          Version Number: 0.0
      OUTPUT
    end

    it "reads the chassis asset tag with smbios" do
      allow(mixin).to receive(:shell_out).with("smbios -t SMB_TYPE_CHASSIS").and_return(command_result(smbios_chassis))
      expect(mixin.smbios_value(:chassis_asset_tag)).to eq("OracleCloud.com")
    end

    it "reads several fields of one type with a single smbios run" do
      expect(mixin).to receive(:shell_out).with("smbios -t SMB_TYPE_SYSTEM").once.and_return(command_result(smbios_system))
      expect(mixin.smbios_value(:sys_vendor)).to eq("QEMU")
      expect(mixin.smbios_value(:product_name)).to eq("Standard PC (Q35 + ICH9, 2009)")
      expect(mixin.smbios_value(:product_uuid)).to eq("1c3a2f9e-5b7d-4e61-9a0c-2d8f6b4e7a13")
    end

    it "matches the whole label, not a prefix of a longer one" do
      allow(mixin).to receive(:shell_out).with("smbios -t SMB_TYPE_BIOS").and_return(command_result(smbios_bios))
      expect(mixin.smbios_value(:bios_vendor)).to eq("Oracle")
      expect(mixin.smbios_value(:bios_version)).to eq("20260902")
    end

    it "returns nil for a label with an empty value or a missing label" do
      allow(mixin).to receive(:shell_out).with("smbios -t SMB_TYPE_SYSTEM").and_return(command_result(smbios_system))
      expect(mixin.smbios_value(:product_serial)).to be_nil
    end

    it "returns nil when the structure type isn't present" do
      allow(mixin).to receive(:shell_out).with("smbios -t SMB_TYPE_BASEBOARD").and_return(command_result(""))
      expect(mixin.smbios_value(:board_asset_tag)).to be_nil
    end

    it "returns nil when smbios fails" do
      allow(mixin).to receive(:shell_out).with("smbios -t SMB_TYPE_CHASSIS").and_return(command_result("", 1))
      expect(mixin.smbios_value(:chassis_asset_tag)).to be_nil
    end
  end

  context "on Windows" do
    before { allow(mixin).to receive(:collect_os_local).and_return("windows") }

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

  context "in target mode" do
    let(:target_os) { double("Train OS", aix?: false, darwin?: false, linux?: false, solaris?: false, windows?: false, family: nil) }

    before do
      connection = double("Train connection", os: target_os)
      mixin.define_singleton_method(:target_mode?) { true }
      mixin.define_singleton_method(:transport_connection) { connection }
    end

    context "with a Linux runner and a FreeBSD target" do
      before do
        allow(mixin).to receive(:collect_os_local).and_return("linux")
        allow(target_os).to receive(:family).and_return("freebsd")
      end

      it "reads the target with kenv, not the runner's sysfs" do
        expect(mixin).not_to receive(:file_exist?)
        allow(mixin).to receive(:shell_out).with("kenv -q smbios.system.maker").and_return(command_result("Amazon EC2\n"))
        expect(mixin.smbios_value(:sys_vendor)).to eq("Amazon EC2")
      end
    end

    context "with a Windows runner and a Linux target" do
      before do
        allow(mixin).to receive(:collect_os_local).and_return("windows")
        allow(target_os).to receive(:linux?).and_return(true)
      end

      it "reads the target's sysfs, not the runner's WMI" do
        allow(mixin).to receive(:file_exist?).with("/sys/class/dmi/id/sys_vendor").and_return(true)
        allow(mixin).to receive(:file_read).with("/sys/class/dmi/id/sys_vendor").and_return("Google\n")
        expect(mixin.smbios_value(:sys_vendor)).to eq("Google")
      end
    end

    context "with a Windows target" do
      before do
        allow(mixin).to receive(:collect_os_local).and_return("windows")
        allow(target_os).to receive(:windows?).and_return(true)
      end

      it "reads the target with PowerShell over the transport, not the runner's WMI" do
        stub_const("WmiLite::Wmi", double("WmiLite::Wmi").tap { |w| expect(w).not_to receive(:new) })
        allow(mixin).to receive(:shell_out)
          .with("powershell.exe -NoProfile -NonInteractive -Command \"Get-CimInstance -ClassName Win32_SystemEnclosure | Select-Object -First 1 -ExpandProperty smbiosassettag\"")
          .and_return(command_result("7783-7084-3265-9085-8269-3286-77\r\n"))
        expect(mixin.smbios_value(:chassis_asset_tag)).to eq("7783-7084-3265-9085-8269-3286-77")
      end

      it "returns nil when PowerShell fails" do
        allow(mixin).to receive(:shell_out).and_return(command_result("", 1))
        expect(mixin.smbios_value(:sys_vendor)).to be_nil
      end
    end
  end
end
