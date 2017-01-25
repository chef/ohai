#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Theodore Nordsieck (<theo@chef.io>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
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
    @version_module = {
      dm_crypt: "",
      psmouse: "",
      acpiphp: "",
      microcode: "1.2.3",
      serio_raw: "",
      virtio_balloon: "",
      floppy: "",
    }

    @expected_result = {
      "dm_crypt"       => { "size" => "22321", "refcount" => "0" },
      "psmouse"        => { "size" => "81038", "refcount" => "0" },
      "acpiphp"        => { "size" => "23314", "refcount" => "0" },
      "microcode"      => { "size" => "18286", "refcount" => "0", "version" => "1.2.3" },
      "serio_raw"      => { "size" => "13031", "refcount" => "0" },
      "virtio_balloon" => { "size" => "13168", "refcount" => "0" },
      "floppy"         => { "size" => "55441", "refcount" => "0" },
    }
    @plugin = get_plugin("kernel")
    allow(@plugin).to receive(:collect_os).and_return(:linux)
    allow(@plugin).to receive(:init_kernel).and_return({})
    allow(@plugin).to receive(:shell_out).with("uname -o").and_return(mock_shell_out(0, "Linux", ""))
    allow(@plugin).to receive(:shell_out).with("env lsmod").and_return(mock_shell_out(0, @env_lsmod, ""))
    @version_module.each do |mod, vers|
      allow(File).to receive(:exist?).with("/sys/module/#{mod}/version").and_return(true)
      allow(File).to receive(:read).with("/sys/module/#{mod}/version").and_return(vers)
    end
    expect(@plugin).to receive(:shell_out).with("env lsmod").at_least(1).times
    @plugin.run
  end

  it_should_check_from_deep_mash("linux::kernel", "kernel", "os", "uname -o", [0, "Linux", ""])

  it "collects linux::kernel::modules" do
    expect(@plugin.data["kernel"]["modules"]).to eq(@expected_result)
  end
end
