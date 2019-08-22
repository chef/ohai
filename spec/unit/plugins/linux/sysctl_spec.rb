#
# Author:: Joshua Miller <joshmiller@fb.com>
# Copyright:: Copyright (c) 2019 Facebook
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

describe Ohai::System, "sysctl plugin", :unix_only do
  let(:plugin) { get_plugin("linux/sysctl") }

  it "should populate sysctl if sysctl is found" do
    sysctl_out = <<-SYSCTL_OUT
  vm.nr_overcommit_hugepages = 0
  vm.numa_stat = 1
  vm.numa_zonelist_order = Node
  vm.oom_dump_tasks = 1
  vm.oom_kill_allocating_task = 0
  vm.overcommit_kbytes = 0
    SYSCTL_OUT
    allow(plugin).to receive(:collect_os).and_return(:linux)
    allow(plugin).to receive(:which).with("sysctl").and_return("/usr/sbin/sysctl")
    allow(plugin).to receive(:shell_out).with("/usr/sbin/sysctl -a").and_return(mock_shell_out(0, sysctl_out, ""))
    plugin.run
    expect(plugin[:sysctl].to_hash).to eq({
      "vm.nr_overcommit_hugepages" => "0",
      "vm.numa_stat" => "1",
      "vm.numa_zonelist_order" => "Node",
      "vm.oom_dump_tasks" => "1",
      "vm.oom_kill_allocating_task" => "0",
      "vm.overcommit_kbytes" => "0",
    })
  end

  it "should not populate sysctl if sysctl is not found" do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    allow(plugin).to receive(:which).with("sysctl").and_return(false)
    plugin.run
    expect(plugin[:sysctl]).to be(nil)
  end
end
