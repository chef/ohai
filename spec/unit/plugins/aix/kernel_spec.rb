#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Author:: Isa Farnik (<isa@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "AIX kernel plugin" do
  before(:each) do
    @plugin = get_plugin("aix/kernel")
    allow(@plugin).to receive(:collect_os).and_return(:aix)
    allow(@plugin).to receive(:shell_out).with("uname -s").and_return(mock_shell_out(0, "AIX", nil))
    allow(@plugin).to receive(:shell_out).with("uname -r").and_return(mock_shell_out(0, "1", nil))
    allow(@plugin).to receive(:shell_out).with("uname -v").and_return(mock_shell_out(0, "6", nil))
    allow(@plugin).to receive(:shell_out).with("uname -p").and_return(mock_shell_out(0, "powerpc", nil))
    allow(@plugin).to receive(:shell_out).with("genkex -d").and_return(mock_shell_out(0, "    Text address     Size     Data address     Size File\nf1000000c0338000    77000 f1000000c0390000    1ec8c /usr/lib/drivers/cluster\n         6390000    20000          63a0000      ba8 /usr/lib/drivers/if_en", nil))
    allow(@plugin).to receive(:shell_out).with("getconf KERNEL_BITMODE").and_return(mock_shell_out(0, "64", nil))
    @plugin.run
  end

  it "uname -s detects the name" do
    expect(@plugin[:kernel][:name]).to eq("aix")
  end

  it "uname -r detects the release" do
    expect(@plugin[:kernel][:release]).to eq("1")
  end

  it "uname -v detects the version" do
    expect(@plugin[:kernel][:version]).to eq("6")
  end

  it "uname -p detects the machine" do
    expect(@plugin[:kernel][:machine]).to eq("powerpc")
  end

  it "getconf KERNEL_BITMODE detects the kernel's bittiness" do
    expect(@plugin[:kernel][:bits]).to eq("64")
  end

  it "detects the modules" do
    expect(@plugin[:kernel][:modules]["/usr/lib/drivers/cluster"]["text"]).to eq({ "address" => "f1000000c0338000", "size" => "77000" })
    expect(@plugin[:kernel][:modules]["/usr/lib/drivers/cluster"]["data"]).to eq({ "address" => "f1000000c0390000", "size" => "1ec8c" })
    expect(@plugin[:kernel][:modules]["/usr/lib/drivers/if_en"]["text"]).to eq({ "address" => "6390000", "size" => "20000" })
    expect(@plugin[:kernel][:modules]["/usr/lib/drivers/if_en"]["data"]).to eq({ "address" => "63a0000", "size" => "ba8" })

  end
end
