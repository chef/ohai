#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Theodore Nordsieck (<theo@opscode.com>)
# Copyright:: Copyright (c) 2008-2013 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../../path/ohai_plugin_common.rb')

describe Ohai::System, "Linux kernel plugin" do
  before(:each) do
    @env_lsmod = <<-ENV_LSMOD
Module                  Size  Used by
dm_crypt               22321  0
psmouse                81038  0
acpiphp                23314  0
microcode              18286  0
serio_raw              13031  0
virtio_balloon         13168  0
floppy                 55441  0
ENV_LSMOD
    @plugin = get_plugin("kernel")
    @plugin.stub(:collect_os).and_return(:linux)
    @plugin.stub(:init_kernel).and_return({})
    @plugin.stub(:shell_out).with("uname -o").and_return(mock_shell_out(0, "Linux", ""))
    @plugin.stub(:shell_out).with("env lsmod").and_return(mock_shell_out(0, @env_lsmod, ""))
    @plugin.should_receive(:shell_out).with("env lsmod").at_least(1).times
    @plugin.run
  end

  it_should_check_from_deep_mash("linux::kernel", "kernel", "os", "uname -o", [0, "Linux", ""])

  test_plugin([ "kernel" ], [ "uname", "env" ]) do | p |
    p.test([ "centos-5.9", "centos-6.4", "ubuntu-10.04", "ubuntu-12.04" ], [ "x86", "x64" ], [[]],
           { "kernel" => { "os" => "GNU/Linux" }})
    p.test([ "ubuntu-13.04" ], [ "x64" ], [[]],
           { "kernel" => { "os" => "GNU/Linux" }})
  end
end
