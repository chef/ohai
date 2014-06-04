#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Ohai::System, "Darwin kernel plugin" do
  before(:each) do
    @plugin = get_plugin("kernel")
    @plugin.stub(:collect_os).and_return(:darwin)
    @plugin.stub(:init_kernel).and_return({})
  end

  it "should populate kernel[:modules] from `kextstat -k -l`" do
    @plugin.stub(:shell_out).with("sysctl -n hw.optional.x86_64").and_return(mock_shell_out(0, "0", ""))
    @plugin.stub(:shell_out).with("kextstat -k -l").and_return(mock_shell_out(0, <<EOF, ""))
    8    0 0xffffff7f81aed000 0x41000    0x41000    com.apple.kec.corecrypto (1.0) <7 6 5 4 3 1>
    9   22 0xffffff7f807f3000 0x9000     0x9000     com.apple.iokit.IOACPIFamily (1.4) <7 6 4 3>
   10   30 0xffffff7f80875000 0x29000    0x29000    com.apple.iokit.IOPCIFamily (2.8) <7 6 5 4 3>
EOF

    modules = {
      "com.apple.kec.corecrypto"=>
      {"version"=>"1.0", "size"=>266240, "index"=>"8", "refcount"=>"0"},
      "com.apple.iokit.IOACPIFamily"=>
      {"version"=>"1.4", "size"=>36864, "index"=>"9", "refcount"=>"22"},
      "com.apple.iokit.IOPCIFamily"=>
      {"version"=>"2.8", "size"=>167936, "index"=>"10", "refcount"=>"30"}}

    @plugin.run
    @plugin[:kernel][:modules].should eql(modules)
  end

  it "should not set kernel_machine to x86_64" do
    @plugin.stub(:shell_out).with("sysctl -n hw.optional.x86_64").and_return(mock_shell_out(0, "0", ""))
    @plugin.stub(:shell_out).with("kextstat -k -l").and_return(mock_shell_out(0, "", ""))
    @plugin.run
    @plugin[:kernel][:machine].should_not == 'x86_64'
  end

  it "should set kernel_machine to x86_64" do
    @plugin.stub(:shell_out).with("sysctl -n hw.optional.x86_64").and_return(mock_shell_out(0, "1", ""))
    @plugin.stub(:shell_out).with("kextstat -k -l").and_return(mock_shell_out(0, "", ""))
    @plugin.run
    @plugin[:kernel][:machine].should == 'x86_64'
  end

  it "should set the kernel_os to the kernel_name value" do
    @plugin.stub(:shell_out).with("sysctl -n hw.optional.x86_64").and_return(mock_shell_out(0, "1", ""))
    @plugin.stub(:shell_out).with("kextstat -k -l").and_return(mock_shell_out(0, "", ""))
    @plugin.run
    @plugin[:kernel][:os].should == @plugin[:kernel][:name]
  end
end
