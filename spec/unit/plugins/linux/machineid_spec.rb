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

describe Ohai::System, "Machine id plugin" do
  let(:plugin) { get_plugin("linux/machineid") }

  before(:each) do
    allow(plugin).to receive(:collect_os).and_return(:linux)
  end

  it "should read /etc/machine-id if available" do
    machine_id = "6f702523e2fc7499eb1dc68e5314dacf"

    allow(File).to receive(:exists?).with("/etc/machine-id").and_return(true)
    allow(File).to receive(:read).with("/etc/machine-id").and_return(machine_id)
    plugin.run
    expect(plugin[:machine_id]).to eq(machine_id)
  end

  it "should read /var/lib/dbus/machine-id if available" do
    machine_id = "6f702523e2fc7499eb1dc68e5314dacf"

    allow(File).to receive(:exists?).with("/etc/machine-id").and_return(false)
    allow(File).to receive(:exists?).with("/var/lib/dbus/machine-id").and_return(true)
    allow(File).to receive(:read).with("/var/lib/dbus/machine-id").and_return(machine_id)
    plugin.run
    expect(plugin[:machine_id]).to eq(machine_id)
  end
end
