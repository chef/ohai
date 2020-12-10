#
# Author:: Davide Cavalca <dcavalca@fb.com>
# Copyright:: Copyright (c) 2020 Facebook
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

describe Ohai::System, "grub2 plugin" do
  let(:plugin) { get_plugin("grub2") }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
  end

  it "populates grub2 if grub2-editenv is found" do
    editenv_out = <<-EDITENV_OUT
saved_entry=f4fd6be6243646e1a76a42d50f219818-5.2.9-229
boot_success=1
kernelopts=root=UUID=6db0ffcd-70ec-4333-86c3-873a9e2a0d77 ro
    EDITENV_OUT
    allow(plugin).to receive(:which).with("grub2-editenv").and_return("/bin/grub2-editenv")
    allow(plugin).to receive(:shell_out).with("/bin/grub2-editenv list").and_return(mock_shell_out(0, editenv_out, ""))
    plugin.run
    expect(plugin[:grub2].to_hash).to eq({
      "environment" => {
        "saved_entry" => "f4fd6be6243646e1a76a42d50f219818-5.2.9-229",
        "boot_success" => "1",
        "kernelopts" => "root=UUID=6db0ffcd-70ec-4333-86c3-873a9e2a0d77 ro",
      },
    })
  end

  it "does not populate grub2 if grub2-editenv is not found" do
    allow(plugin).to receive(:which).with("grub2-editenv").and_return(false)
    plugin.run
    expect(plugin[:grub2]).to be(nil)
  end
end
