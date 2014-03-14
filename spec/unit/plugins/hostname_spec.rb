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

describe Ohai::System, "hostname plugin" do
  before(:each) do
    @plugin = get_plugin("hostname")
    @plugin.stub(:collect_os).and_return(:default)
    @plugin.stub(:shell_out).with("hostname").and_return(mock_shell_out(0, "katie.local", ""))
  end

  context "when sigar is not installed" do
    before(:each) do
      @plugin.stub(:sigar_is_available?).and_return(false)
      @plugin.should_not_receive(:get_fqdn_from_sigar)
      @plugin.stub(:resolve_fqdn).and_return("katie.bethell")
    end
    it_should_check_from("linux::hostname", "machinename", "hostname", "katie.local")

    it "should use #resolve_fqdn to find the fqdn" do
      @plugin.run
      @plugin[:fqdn].should == "katie.bethell"
    end

    it "should set the domain to everything after the first dot of the fqdn" do
      @plugin.run
      @plugin[:domain].should == "bethell"
    end

    it "should set the [short] hostname to everything before the first dot of the fqdn" do
      @plugin.run
      @plugin[:hostname].should == "katie"
    end
  end

  context "when sigar is installed" do
    before(:each) do
      @plugin.stub(:sigar_is_available?).and_return(true)
      @plugin.stub(:get_fqdn_from_sigar).and_return("katie.bethell")
    end
    it_should_check_from("linux::hostname", "machinename", "hostname", "katie.local")
    it "should set the fqdn to the returned value from sigar" do
      @plugin.run
      @plugin[:fqdn].should == "katie.bethell"
    end

    it "should set the domain to everything after the first dot of the fqdn" do
      @plugin.run
      @plugin[:domain].should == "bethell"
    end

    it "should set the [short] hostname to everything before the first dot of the fqdn" do
      @plugin.run
      @plugin[:hostname].should == "katie"
    end
  end

  context "hostname --fqdn when it returns empty string" do
    before(:each) do
      @plugin.stub(:collect_os).and_return(:linux)
      @plugin.stub(:shell_out).with("hostname -s").and_return(
        mock_shell_out(0, "katie", ""))
      @plugin.stub(:shell_out).with("hostname --fqdn").and_return(
        mock_shell_out(0, "", ""), mock_shell_out(0, "katie.local", ""))
    end

    it "should be called twice" do
      @plugin.run
      @plugin[:fqdn].should == "katie.local"
    end
  end

  context "hostname --fqdn when it works" do
    before(:each) do
      @plugin.stub(:collect_os).and_return(:linux)
      @plugin.stub(:shell_out).with("hostname -s").and_return(
        mock_shell_out(0, "katie", ""))
      @plugin.stub(:shell_out).with("hostname --fqdn").and_return(
        mock_shell_out(0, "katie.local", ""))
    end

    it "should be not be called twice" do
      @plugin.run
      @plugin[:fqdn].should == "katie.local"
    end
  end
end
