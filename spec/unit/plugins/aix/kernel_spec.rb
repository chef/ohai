#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Ohai::System, "AIX kernel plugin" do
  before(:each) do
    @plugin = get_plugin("aix/kernel")
    @plugin.stub(:collect_os).and_return(:aix)
    @plugin.stub(:shell_out).with("uname -s").and_return(mock_shell_out(0, "AIX", nil))
    @plugin.stub(:shell_out).with("uname -r").and_return(mock_shell_out(0, "1", nil))
    @plugin.stub(:shell_out).with("uname -v").and_return(mock_shell_out(0, "6", nil))
    @plugin.stub(:shell_out).with("uname -p").and_return(mock_shell_out(0, "powerpc", nil))
    @plugin.stub(:shell_out).with("genkex -d").and_return(mock_shell_out(0, "    Text address     Size     Data address     Size File\nf1000000c0338000    77000 f1000000c0390000    1ec8c /usr/lib/drivers/cluster\n         6390000    20000          63a0000      ba8 /usr/lib/drivers/if_en", nil))
    @plugin.run
  end

  it "uname -s detects the name" do
    @plugin[:kernel][:name].should == "aix"
  end

  it "uname -r detects the release" do
    @plugin[:kernel][:release].should == "1"
  end

  it "uname -v detects the version" do
    @plugin[:kernel][:version].should == "6"
  end

  it "uname -p detects the machine" do
    @plugin[:kernel][:machine].should == "powerpc"
  end

  it "detects the modules" do
    @plugin[:kernel][:modules]["/usr/lib/drivers/cluster"]["text"].should == { "address" => "f1000000c0338000", "size" => "77000" }
    @plugin[:kernel][:modules]["/usr/lib/drivers/cluster"]["data"].should == { "address" => "f1000000c0390000", "size" => "1ec8c" }
    @plugin[:kernel][:modules]["/usr/lib/drivers/if_en"]["text"].should == { "address" => "6390000", "size" => "20000"}
    @plugin[:kernel][:modules]["/usr/lib/drivers/if_en"]["data"].should == { "address" => "63a0000", "size" => "ba8"}

  end
end
