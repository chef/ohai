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


require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Ohai::System, "plugin kernel" do
  before(:each) do
    @plugin = get_plugin("kernel")
    @plugin.stub(:collect_os).and_return(:default) # for debugging
    @plugin.stub(:shell_out).with("uname -s").and_return(mock_shell_out(0, "Darwin\n", ""))
    @plugin.stub(:shell_out).with("uname -r").and_return(mock_shell_out(0, "9.5.0\n", ""))
    @plugin.stub(:shell_out).with("uname -v").and_return(mock_shell_out(0, "Darwin Kernel Version 9.5.0: Wed Sep  3 11:29:43 PDT 2008; root:xnu-1228.7.58~1\/RELEASE_I386\n", ""))
    @plugin.stub(:shell_out).with("uname -m").and_return(mock_shell_out(0, "i386\n", ""))
    @plugin.stub(:shell_out).with("uname -o").and_return(mock_shell_out(0, "Linux\n", ""))
  end

  it_should_check_from_mash("kernel", "name", "uname -s", [0, "Darwin\n", ""])
  it_should_check_from_mash("kernel", "release", "uname -r", [0, "9.5.0\n", ""])
  it_should_check_from_mash("kernel", "version", "uname -v", [0, "Darwin Kernel Version 9.5.0: Wed Sep  3 11:29:43 PDT 2008; root:xnu-1228.7.58~1\/RELEASE_I386\n", ""])
  it_should_check_from_mash("kernel", "machine", "uname -m", [0, "i386\n", ""])

end
