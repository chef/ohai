#
# Author:: Doug MacEachern <dougm@vmware.com>
# Copyright:: Copyright (c) 2009 VMware, Inc.
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


require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '/spec_helper.rb'))

describe Ohai::System, "plugin mono" do

  before(:each) do
    @ohai = Ohai::System.new
    @plugin = Ohai::DSL::Plugin.new(@ohai, File.join(PLUGIN_PATH, "mono.rb"))
    @plugin[:languages] = Mash.new
    @plugin.stub!(:require_plugin).and_return(true)
    @status = 0
    @stdout = "Mono JIT compiler version 1.2.6 (tarball)\nCopyright (C) 2002-2007 Novell, Inc and Contributors. www.mono-project.com\n"
    @stderr = ""
    @plugin.stub!(:run_command).with({:no_status_check=>true, :command=>"mono -V"}).and_return([@status, @stdout, @stderr])
  end

  it "should get the mono version from running mono -V" do
    @plugin.should_receive(:run_command).with({:no_status_check=>true, :command=>"mono -V"}).and_return([0, "Mono JIT compiler version 1.2.6 (tarball)\nCopyright (C) 2002-2007 Novell, Inc and Contributors. www.mono-project.com\n", ""])
    @plugin.run
  end

  it "should set languages[:mono][:version]" do
    @plugin.run
    @plugin.languages[:mono][:version].should eql("1.2.6")
  end

  it "should not set the languages[:mono] tree up if mono command fails" do
    @status = 1
    @stdout = "Mono JIT compiler version 1.2.6 (tarball)\nCopyright (C) 2002-2007 Novell, Inc and Contributors. www.mono-project.com\n"
    @stderr = ""
    @plugin.stub!(:run_command).with({:no_status_check=>true, :command=>"mono -V"}).and_return([@status, @stdout, @stderr])
    @plugin.run
    @plugin.languages.should_not have_key(:mono)
  end

end
