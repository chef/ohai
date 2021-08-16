#
# Author:: Trevor O (<trevoro@joyent.com>)
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

describe Ohai::System, "Solaris plugin platform" do
  let(:plugin) { get_plugin("solaris2/platform") }

  before do
    allow(plugin).to receive(:collect_os).and_return(:solaris2)
    allow(plugin).to receive(:shell_out).with("/sbin/uname -X")
  end

  describe "on SmartOS" do
    before do
      @uname_x = <<~UNAME_X
        System = SunOS
        Node = node.example.com
        Release = 5.11
        KernelID = joyent_20120130T201844Z
        Machine = i86pc
        BusType = <unknown>
        Serial = <unknown>
        Users = <unknown>
        OEM# = 0
        Origin# = 1
        NumCPU = 16
      UNAME_X

      allow(File).to receive(:exist?).with("/sbin/uname").and_return(true)
      allow(plugin).to receive(:shell_out).with("/sbin/uname -X").and_return(mock_shell_out(0, @uname_x, ""))

      @release = StringIO.new("  SmartOS 20120130T201844Z x86_64\n")
      allow(File).to receive(:open).with("/etc/release").and_yield(@release)
      plugin.run
    end

    it "runs uname and set platform and build" do
      expect(plugin[:platform_build]).to eq("joyent_20120130T201844Z")
    end

    it "sets the platform" do
      expect(plugin[:platform]).to eq("smartos")
    end

    it "sets the platform_version" do
      expect(plugin[:platform_version]).to eq("5.11")
    end

  end

  describe "on Solaris 11" do
    before do
      @uname_x = <<~UNAME_X
        System = SunOS
        Node = node.example.com
        Release = 5.11
        KernelID = 11.1
        Machine = i86pc
        BusType = <unknown>
        Serial = <unknown>
        Users = <unknown>
        OEM# = 0
        Origin# = 1
        NumCPU = 1
      UNAME_X

      allow(File).to receive(:exist?).with("/sbin/uname").and_return(true)
      allow(plugin).to receive(:shell_out).with("/sbin/uname -X").and_return(mock_shell_out(0, @uname_x, ""))

      @release = StringIO.new("                             Oracle Solaris 11.1 X86\n")
      allow(File).to receive(:open).with("/etc/release").and_yield(@release)
      plugin.run
    end

    it "runs uname and set platform and build" do
      expect(plugin[:platform_build]).to eq("11.1")
    end

    it "sets the platform" do
      expect(plugin[:platform]).to eq("solaris2")
    end

    it "sets the platform_version" do
      expect(plugin[:platform_version]).to eq("5.11")
    end

  end

  describe "on OmniOS" do
    before do
      @uname_x = <<~UNAME_X
        System = SunOS
        Node = omniosce-vagrant
        Release = 5.11
        KernelID = omnios-r151026-673c59f55d
        Machine = i86pc
        BusType = <unknown>
        Serial = <unknown>
        Users = <unknown>
        OEM# = 0
        Origin# = 1
        NumCPU = 1
      UNAME_X

      allow(File).to receive(:exist?).with("/sbin/uname").and_return(true)
      allow(plugin).to receive(:shell_out).with("/sbin/uname -X").and_return(mock_shell_out(0, @uname_x, ""))

      @release = StringIO.new("  OmniOS v11 r151026\n  Copyright 2017 OmniTI Computer Consulting, Inc. All rights reserved.\n  Copyright 2018 OmniOS Community Edition (OmniOSce) Association.\n  All rights reserved. Use is subject to licence terms.")
      allow(File).to receive(:open).with("/etc/release").and_yield(@release)
      plugin.run
    end

    it "runs uname and set platform and build" do
      expect(plugin[:platform_build]).to eq("omnios-r151026-673c59f55d")
    end

    it "sets the platform" do
      expect(plugin[:platform]).to eq("omnios")
    end

    it "sets the platform_version" do
      expect(plugin[:platform_version]).to eq("151026")
    end

  end

  describe "on OpenIndiana Hipster" do
    before do
      @uname_x = <<~UNAME_X
        System = SunOS
        Node = openindiana
        Release = 5.11
        KernelID = illumos-c3e16711de
        Machine = i86pc
        BusType = <unknown>
        Serial = <unknown>
        Users = <unknown>
        OEM# = 0
        Origin# = 1
        NumCPU = 1
      UNAME_X

      allow(File).to receive(:exist?).with("/sbin/uname").and_return(true)
      allow(plugin).to receive(:shell_out).with("/sbin/uname -X").and_return(mock_shell_out(0, @uname_x, ""))

      @release = StringIO.new("             OpenIndiana Hipster 2020.04 (powered by illumos)\n        OpenIndiana Project, part of The Illumos Foundation (C) 2010-2020\n                        Use is subject to license terms.\n                           Assembled 03 May 2020")
      allow(File).to receive(:open).with("/etc/release").and_yield(@release)
      plugin.run
    end

    it "runs uname and set platform and build" do
      expect(plugin[:platform_build]).to eq("illumos-c3e16711de")
    end

    it "sets the platform" do
      expect(plugin[:platform]).to eq("openindiana")
    end

    it "sets the platform_version" do
      expect(plugin[:platform_version]).to eq("2020.04")
    end

  end

  describe "on OpenIndiana pre-Hipster" do
    before do
      @uname_x = <<~UNAME_X
        System = SunOS
        Node = openindiana
        Release = 5.11
        KernelID = illumos-cf2fa55
        Machine = i86pc
        BusType = <unknown>
        Serial = <unknown>
        Users = <unknown>
        OEM# = 0
        Origin# = 1
        NumCPU = 2
      UNAME_X

      allow(File).to receive(:exist?).with("/sbin/uname").and_return(true)
      allow(plugin).to receive(:shell_out).with("/sbin/uname -X").and_return(mock_shell_out(0, @uname_x, ""))
      @release = StringIO.new("             OpenIndiana Development oi_151.1.8 (powered by illumos)\n        Copyright 2011 Oracle and/or its affiliates. All rights reserved\n                        Use is subject to license terms.\n                           Assembled 20 July 2013")
      allow(File).to receive(:open).with("/etc/release").and_yield(@release)
      plugin.run
    end

    it "sets the platform" do
      expect(plugin[:platform]).to eq("openindiana")
    end

    it "sets the platform_version" do
      expect(plugin[:platform_version]).to eq("151.1.8")
    end

  end

end
