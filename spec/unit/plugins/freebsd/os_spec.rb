#
# Author:: Richard Manyanza (<liseki@nyikacraftsmen.com>)
# Copyright:: Copyright (c) 2014 Richard Manyanza.
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

describe Ohai::System, "FreeBSD plugin os" do
  before(:each) do
    @plugin = get_plugin("freebsd/os")
    @plugin.stub(:shell_out).with("sysctl -n kern.osreldate").and_return(mock_shell_out(0, "902001\n", ""))
    @plugin.stub(:collect_os).and_return(:freebsd)
  end

  it "should set os_version to __FreeBSD_version" do
    @plugin.run
    @plugin[:os_version].should == "902001"
  end
end  
