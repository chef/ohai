#
# Author:: Julian C. Dunn (<jdunn@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'spec_helper'

describe Ohai::System, "AIX virtualization plugin" do

  context "inside an LPAR" do
    before(:each) do
      @plugin = get_plugin("aix/virtualization")
      @plugin.stub(:collect_os).and_return(:aix)
      @plugin.stub(:shell_out).with("uname -L").and_return(mock_shell_out(0, "29 l273pp027", nil))
      @plugin.stub(:shell_out).with("uname -W").and_return(mock_shell_out(0, "0", nil))
      @plugin.run
    end

    it "uname -L detects the LPAR number and name" do
      @plugin[:virtualization][:lpar_no].should == "29"
      @plugin[:virtualization][:lpar_name].should == "l273pp027"
    end
  end

  context "inside a WPAR" do
    before(:each) do
      @plugin = get_plugin("aix/virtualization")
      @plugin.stub(:collect_os).and_return(:aix)
      @plugin.stub(:shell_out).with("uname -L").and_return(mock_shell_out(0, "43 l33t", nil))
      @plugin.stub(:shell_out).with("uname -W").and_return(mock_shell_out(0, "42", nil))
      @plugin.run
    end

    it "uname -W detects the WPAR number" do
      @plugin[:virtualization][:wpar_no].should == "42"
    end
  end

end
