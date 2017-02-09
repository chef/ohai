#
# Author:: Bryan McLellan <btm@chef.io>
# Copyright:: Copyright (c) 2012-2016 Chef Software, Inc.
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

describe Ohai::System, "BSD virtualization plugin" do
  before(:each) do
    @plugin = get_plugin("bsd/virtualization")
    allow(@plugin).to receive(:collect_os).and_return(:freebsd)
    allow(@plugin).to receive(:shell_out).with("sysctl -n security.jail.jailed").and_return(mock_shell_out(0, "0", ""))
    allow(@plugin).to receive(:shell_out).with("#{Ohai.abs_path( "/sbin/kldstat" )}").and_return(mock_shell_out(0, "", ""))
    allow(@plugin).to receive(:shell_out).with("jls -nd").and_return(mock_shell_out(0, "", ""))
    allow(@plugin).to receive(:shell_out).with("sysctl -n hw.model").and_return(mock_shell_out(0, "", ""))
    allow(@plugin).to receive(:shell_out).with("sysctl -n kern.vm_guest").and_return(mock_shell_out(0, "", ""))
    allow(File).to receive(:exist?).and_return false
  end

  context "when on a bhyve host" do
    it "detects we are a host" do
      allow(File).to receive(:exist?).with("/dev/vmm").and_return true
      @plugin.run
      expect(@plugin[:virtualization][:system]).to eq("bhyve")
      expect(@plugin[:virtualization][:role]).to eq("host")
      expect(@plugin[:virtualization][:systems][:bhyve]).to eq("host")
    end
  end

  context "when on a bhyve guest" do
    it "detects we are a guest" do
      allow(@plugin).to receive(:shell_out).with("sysctl -n kern.vm_guest").and_return(mock_shell_out(0, "bhyve", ""))
      @plugin.run
      expect(@plugin[:virtualization][:system]).to eq("bhyve")
      expect(@plugin[:virtualization][:role]).to eq("guest")
      expect(@plugin[:virtualization][:systems][:bhyve]).to eq("guest")
    end
  end

  context "jails" do
    it "detects we are in a jail" do
      allow(@plugin).to receive(:shell_out).with("sysctl -n security.jail.jailed").and_return(mock_shell_out(0, "1", ""))
      @plugin.run
      expect(@plugin[:virtualization][:system]).to eq("jail")
      expect(@plugin[:virtualization][:role]).to eq("guest")
      expect(@plugin[:virtualization][:systems][:jail]).to eq("guest")
    end

    it "detects we are hosting jails" do
      # from http://www.freebsd.org/doc/handbook/jails-application.html
      @jails = "JID  IP Address      Hostname                      Path\n     3  192.168.3.17    ns.example.org                /home/j/ns\n     2  192.168.3.18    mail.example.org              /home/j/mail\n     1  62.123.43.14    www.example.org               /home/j/www"
      allow(@plugin).to receive(:shell_out).with("jls -nd").and_return(mock_shell_out(0, @jails, ""))
      @plugin.run
      expect(@plugin[:virtualization][:system]).to eq("jail")
      expect(@plugin[:virtualization][:role]).to eq("host")
      expect(@plugin[:virtualization][:systems][:jail]).to eq("host")
    end
  end

  context "when on a virtualbox guest" do
    before do
      @vbox_guest = <<-OUT
Id Refs Address Size Name
1 40 0xffffffff80100000 d20428 kernel
7 3 0xffffffff81055000 41e88 vboxguest.ko
OUT
      allow(@plugin).to receive(:shell_out).with("#{Ohai.abs_path("/sbin/kldstat")}").and_return(mock_shell_out(0, @vbox_guest, ""))
    end

    it "detects we are a guest" do
      @plugin.run
      expect(@plugin[:virtualization][:system]).to eq("vbox")
      expect(@plugin[:virtualization][:role]).to eq("guest")
      expect(@plugin[:virtualization][:systems][:vbox]).to eq("guest")
    end
  end

  context "when on a virtualbox host" do
    before do
      @stdout = <<-OUT
Id Refs Address Size Name
1 40 0xffffffff80100000 d20428 kernel
7 3 0xffffffff81055000 41e88 vboxdrv.ko
OUT
      allow(@plugin).to receive(:shell_out).with("/sbin/kldstat").and_return(mock_shell_out(0, @stdout, ""))
    end

    it "detects we are a host" do
      @plugin.run
      expect(@plugin[:virtualization][:system]).to eq("vbox")
      expect(@plugin[:virtualization][:role]).to eq("host")
      expect(@plugin[:virtualization][:systems][:vbox]).to eq("host")
    end
  end

  context "when on a QEMU guest" do
    it "detects we are a guest" do
      [ "Common KVM processor", 'QEMU Virtual CPU version (cpu64-rhel6) ("GenuineIntel" 686-class)', "Common 32-bit KVM processor"].each do |kvm_string|
        allow(@plugin).to receive(:shell_out).with("sysctl -n hw.model").and_return(mock_shell_out(0, kvm_string, ""))
        @plugin.run
        expect(@plugin[:virtualization][:system]).to eq("kvm")
        expect(@plugin[:virtualization][:role]).to eq("guest")
        expect(@plugin[:virtualization][:systems][:kvm]).to eq("guest")
      end
    end
  end

  context "when on a xen guest" do
    it "detects we are a guest" do
      allow(@plugin).to receive(:shell_out).with("sysctl -n kern.vm_guest").and_return(mock_shell_out(0, "xen", ""))
      @plugin.run
      expect(@plugin[:virtualization][:system]).to eq("xen")
      expect(@plugin[:virtualization][:role]).to eq("guest")
      expect(@plugin[:virtualization][:systems][:xen]).to eq("guest")
    end
  end

  context "when on a vmware guest" do
    it "detects we are a guest" do
      allow(@plugin).to receive(:shell_out).with("sysctl -n kern.vm_guest").and_return(mock_shell_out(0, "vmware", ""))
      @plugin.run
      expect(@plugin[:virtualization][:system]).to eq("vmware")
      expect(@plugin[:virtualization][:role]).to eq("guest")
      expect(@plugin[:virtualization][:systems][:vmware]).to eq("guest")
    end
  end

  context "when on a hyper-v guest" do
    it "detects we are a guest" do
      allow(@plugin).to receive(:shell_out).with("sysctl -n kern.vm_guest").and_return(mock_shell_out(0, "hv", ""))
      @plugin.run
      expect(@plugin[:virtualization][:system]).to eq("hyperv")
      expect(@plugin[:virtualization][:role]).to eq("guest")
      expect(@plugin[:virtualization][:systems][:hyperv]).to eq("guest")
    end
  end
end
