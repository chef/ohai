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

# The BSD plugin runs its checks in a fixed order and each detection
# overwrites system and role, so the last match wins.
describe Ohai::System, "BSD virtualization detection order" do
  let(:plugin) { get_plugin("bsd/virtualization") }

  # jls -n prints one line of name=value parameters per jail (jls(8)); this
  # line is built from that format
  let(:jls_one_jail) { "devfs_ruleset=4 enforce_statfs=2 host=new ip4=disable ip6=disable jid=1 name=www parent=0 path=/usr/jails/www persist securelevel=-1 vnet=new\n" }

  def sysctl(name, value)
    allow(plugin).to receive(:shell_out).with("sysctl -n #{name}").and_return(mock_shell_out(0, "#{value}\n", ""))
  end

  before do
    allow(plugin).to receive(:collect_os).and_return(:freebsd)
    allow(plugin).to receive(:file_exist?).and_return(false)
    sysctl("security.jail.jailed", "0")
    sysctl("hw.model", "Intel(R) Xeon(R) CPU E5-2680 v4 @ 2.40GHz")
    sysctl("kern.vm_guest", "none")
    sysctl("kern.hostuuid", "")
    allow(plugin).to receive(:shell_out).with("jls -nd").and_return(mock_shell_out(0, "", ""))
    allow(plugin).to receive(:shell_out).with(Ohai.abs_path("/sbin/kldstat").to_s).and_return(mock_shell_out(0, "", ""))
  end

  it "reports nothing on hardware" do
    plugin.run
    expect(plugin[:virtualization]).to eq("systems" => {})
  end

  # hw.model of QEMU's default qemu64 CPU
  # (target/i386/cpu.c: "QEMU Virtual CPU version " QEMU_HW_VERSION)
  it "reports a kvm guest from a QEMU hw.model" do
    sysctl("hw.model", "QEMU Virtual CPU version 2.5+")
    plugin.run
    expect(plugin[:virtualization][:system]).to eq("kvm")
    expect(plugin[:virtualization][:role]).to eq("guest")
    expect(plugin[:virtualization][:systems]).to eq("kvm" => "guest")
  end

  it "reports a jail host over a jail guest when a jailed system runs its own jails" do
    sysctl("security.jail.jailed", "1")
    allow(plugin).to receive(:shell_out).with("jls -nd").and_return(mock_shell_out(0, jls_one_jail, ""))
    plugin.run
    expect(plugin[:virtualization][:system]).to eq("jail")
    expect(plugin[:virtualization][:role]).to eq("host")
    expect(plugin[:virtualization][:systems]).to eq("jail" => "host")
  end

  it "reports a jail host when jls lists a single jail" do
    allow(plugin).to receive(:shell_out).with("jls -nd").and_return(mock_shell_out(0, jls_one_jail, ""))
    plugin.run
    expect(plugin[:virtualization][:system]).to eq("jail")
    expect(plugin[:virtualization][:role]).to eq("host")
    expect(plugin[:virtualization][:systems]).to eq("jail" => "host")
  end

  it "reports kvm, not amazonec2, when kern.hostuuid has ec2 only inside it" do
    sysctl("kern.vm_guest", "kvm")
    sysctl("kern.hostuuid", "4a2c3ec2-5b1e-4c39-a7e2-0d6c4d5f8e91")
    plugin.run
    expect(plugin[:virtualization][:system]).to eq("kvm")
    expect(plugin[:virtualization][:role]).to eq("guest")
    expect(plugin[:virtualization][:systems]).to eq("kvm" => "guest")
  end

  it "reports the kern.vm_guest hypervisor over a jail guest" do
    sysctl("security.jail.jailed", "1")
    sysctl("kern.vm_guest", "xen")
    plugin.run
    expect(plugin[:virtualization][:system]).to eq("xen")
    expect(plugin[:virtualization][:role]).to eq("guest")
    expect(plugin[:virtualization][:systems]).to eq("jail" => "guest", "xen" => "guest")
  end
end
