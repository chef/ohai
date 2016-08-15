#
# Author:: Davide Cavalca <dcavalca@fb.com>
# Copyright:: Copyright (c) 2016 Facebook
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

require File.expand_path(File.dirname(__FILE__) + "/../../../spec_helper.rb")

describe Ohai::System, "Linux machine plugin" do
  let(:plugin) { get_plugin("linux/machine") }

  before(:each) do
    allow(plugin).to receive(:collect_os).and_return(:linux)
  end

  describe "if hostnamectl is available" do
    it "should populate machine" do
      hostnamectl_out = <<-HOSTNAMECTL_OUT
   Static hostname: foo
         Icon name: computer-laptop
           Chassis: laptop
        Machine ID: 6f702523e2fc7499eb1dc68e5314dacf
           Boot ID: e085ae9e65e245a8a7b62912adeebe97
  Operating System: Debian GNU/Linux 8 (jessie)
            Kernel: Linux 4.3.0-0.bpo.1-amd64
      Architecture: x86-64
HOSTNAMECTL_OUT

      allow(plugin).to receive(:which).with("hostnamectl").and_return("/bin/hostnamectl")
      allow(plugin).to receive(:shell_out).with("/bin/hostnamectl").and_return(mock_shell_out(0, hostnamectl_out, ""))
      plugin.run
      expect(plugin[:machine].to_hash).to eq({
        "static_hostname" => "foo",
        "icon_name" => "computer-laptop",
        "chassis" => "laptop",
        "machine_id" => "6f702523e2fc7499eb1dc68e5314dacf",
        "boot_id" => "e085ae9e65e245a8a7b62912adeebe97",
        "operating_system" => "Debian GNU/Linux 8 (jessie)",
        "kernel" => "Linux 4.3.0-0.bpo.1-amd64",
        "architecture" => "x86-64",
      })
    end
  end

  describe "if hostnamectl is not available" do
    before(:each) do
      allow(plugin).to receive(:which).with("hostnamectl").and_return(false)
    end

    it "should read /etc/machine-id if available" do
      machine_id = "6f702523e2fc7499eb1dc68e5314dacf"

      allow(File).to receive(:exists?).with("/etc/machine-id").and_return(true)
      allow(File).to receive(:read).with("/etc/machine-id").and_return(machine_id)
      allow(File).to receive(:exists?).with("/etc/machine-info").and_return(false)
      plugin.run
      expect(plugin[:machine][:machine_id]).to eq(machine_id)
    end

    it "should fallback to /var/lib/dbus/machine-id if available" do
      machine_id = "6f702523e2fc7499eb1dc68e5314dacf"

      allow(File).to receive(:exists?).with("/etc/machine-id").and_return(false)
      allow(File).to receive(:exists?).with("/var/lib/dbus/machine-id").and_return(true)
      allow(File).to receive(:read).with("/var/lib/dbus/machine-id").and_return(machine_id)
      allow(File).to receive(:exists?).with("/etc/machine-info").and_return(false)
      plugin.run
      expect(plugin[:machine][:machine_id]).to eq(machine_id)
    end

    it "should read /etc/machine-info if available" do
      machine_info = <<-MACHINE_INFO
PRETTY_HOSTNAME="My Tablet"
ICON_NAME=computer-tablet
CHASSIS=tablet
DEPLOYMENT=production
MACHINE_INFO

      allow(File).to receive(:exists?).with("/etc/machine-id").and_return(false)
      allow(File).to receive(:exists?).with("/var/lib/dbus/machine-id").and_return(false)
      allow(File).to receive(:exists?).with("/etc/machine-info").and_return(true)
      allow(File).to receive(:read).with("/etc/machine-info").and_return(machine_info)
      plugin.run
      expect(plugin[:machine].to_hash).to eq({
        "pretty_hostname" => "My Tablet",
        "icon_name" => "computer-tablet",
        "chassis" => "tablet",
        "deployment" => "production",
      })
    end
  end
end
