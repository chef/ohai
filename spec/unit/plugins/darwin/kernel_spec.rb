#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Ohai::System, "Darwin kernel plugin" do
  before do
    @plugin = get_plugin("kernel")
    allow(@plugin).to receive(:collect_os).and_return(:darwin)
    allow(@plugin).to receive(:init_kernel).and_return({})
  end

  it "populates kernel[:modules] from `kextstat -k -l`" do
    allow(@plugin).to receive(:shell_out).with("sysctl -n hw.optional.x86_64").and_return(mock_shell_out(0, "0", ""))
    allow(@plugin).to receive(:shell_out).with("kextstat -k -l").and_return(mock_shell_out(0, <<EOF, ""))
    8    0 0xffffff7f81aed000 0x41000    0x41000    com.apple.kec.corecrypto (1.0) <7 6 5 4 3 1>
    9   22 0xffffff7f807f3000 0x9000     0x9000     com.apple.iokit.IOACPIFamily (1.4) <7 6 4 3>
   10   30 0xffffff7f80875000 0x29000    0x29000    com.apple.iokit.IOPCIFamily (2.8) <7 6 5 4 3>
EOF

    modules = {
      "com.apple.kec.corecrypto" => { "version" => "1.0", "size" => 266240, "index" => "8", "refcount" => "0" },
      "com.apple.iokit.IOACPIFamily" => { "version" => "1.4", "size" => 36864, "index" => "9", "refcount" => "22" },
      "com.apple.iokit.IOPCIFamily" => { "version" => "2.8", "size" => 167936, "index" => "10", "refcount" => "30" } }

    @plugin.run
    expect(@plugin[:kernel][:modules]).to eql(modules)
  end

  it "includes kexts whose version has letters or whose bundle ID has a hyphen" do
    allow(@plugin).to receive(:shell_out).with("sysctl -n hw.optional.x86_64").and_return(mock_shell_out(0, "0", ""))
    allow(@plugin).to receive(:shell_out).with("kextstat -k -l").and_return(mock_shell_out(0, <<EOF, ""))
    8   15 0xfffffe000773d670 0x1e9b0    0x1e9b0    com.apple.kec.corecrypto (26.0) 6F8A08D8-BAF9-3914-A73B-C93A72D692DB <7 6 5 4 3 1>
   18    2 0xfffffe00072d3720 0x547      0x547      com.apple.kext.AppleMatch (1.0.0d1) 9726529E-39EE-3385-9F7A-C6DF555BEE24 <6 4 3 1>
   33    1 0xfffffe0007599550 0x191a     0x191a     com.apple.driver.mDNSOffloadUserClient (1.0.1b8) E4AB29C2-7BA6-34A0-B865-F96EC09D4562 <28 6 4 3 1>
  140    0 0xffffff7f83a1c000 0x2c000    0x2c000    com.paragon-software.filesystems.ntfs (82.0.38) 2D4B4D1D-8C5A-3E4B-9B62-1B9A3C8E1F00 <8 6 5 3 1>
EOF

    @plugin.run
    expect(@plugin[:kernel][:modules]).to eql(
      "com.apple.kec.corecrypto" => { "version" => "26.0", "size" => 125360, "index" => "8", "refcount" => "15" },
      "com.apple.kext.AppleMatch" => { "version" => "1.0.0d1", "size" => 1351, "index" => "18", "refcount" => "2" },
      "com.apple.driver.mDNSOffloadUserClient" => { "version" => "1.0.1b8", "size" => 6426, "index" => "33", "refcount" => "1" },
      "com.paragon-software.filesystems.ntfs" => { "version" => "82.0.38", "size" => 180224, "index" => "140", "refcount" => "0" }
    )
  end

  it "does not set kernel_machine to x86_64" do
    allow(@plugin).to receive(:shell_out).with("sysctl -n hw.optional.x86_64").and_return(mock_shell_out(0, "0", ""))
    allow(@plugin).to receive(:shell_out).with("kextstat -k -l").and_return(mock_shell_out(0, "", ""))
    @plugin.run
    expect(@plugin[:kernel][:machine]).not_to eq("x86_64")
  end

  it "sets kernel_machine to x86_64" do
    allow(@plugin).to receive(:shell_out).with("sysctl -n hw.optional.x86_64").and_return(mock_shell_out(0, "1", ""))
    allow(@plugin).to receive(:shell_out).with("kextstat -k -l").and_return(mock_shell_out(0, "", ""))
    @plugin.run
    expect(@plugin[:kernel][:machine]).to eq("x86_64")
  end

  it "sets the kernel_os to the kernel_name value" do
    allow(@plugin).to receive(:shell_out).with("sysctl -n hw.optional.x86_64").and_return(mock_shell_out(0, "1", ""))
    allow(@plugin).to receive(:shell_out).with("kextstat -k -l").and_return(mock_shell_out(0, "", ""))
    @plugin.run
    expect(@plugin[:kernel][:os]).to eq(@plugin[:kernel][:name])
  end
end
