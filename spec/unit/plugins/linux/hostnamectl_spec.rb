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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "Linux hostnamectl plugin" do
  let(:plugin) { get_plugin("linux/hostnamectl") }

  before(:each) do
    allow(plugin).to receive(:collect_os).and_return(:linux)
  end

  it "should populate hostnamectl if hostnamectl is available" do
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
    expect(plugin[:hostnamectl].to_hash).to eq({
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

  it "should not populate hostnamectl if hostnamectl is not available" do
    allow(plugin).to receive(:which).with("hostnamectl").and_return(false)
    expect(plugin[:hostnamectl]).to eq(nil)
  end
end
