#
# Author:: Joshua Timberman(<joshua@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

describe Ohai::System, "plugin perl" do
  before(:each) do
    @ohai = Ohai::System.new
    @plugin = Ohai::DSL::Plugin.new(@ohai, File.join(PLUGIN_PATH, "perl.rb"))
    @plugin[:languages] = Mash.new
    @plugin.stub!(:require_plugin).and_return(true)
    @pid = 2342
    @stderr = StringIO.new
    @stdout = StringIO.new(<<-OUT)
version='5.8.8';
archname='darwin-thread-multi-2level';
OUT
    @stdin = StringIO.new
    @status = 0
    @plugin.stub!(:run_command).with({:no_status_check=>true, :command=>"perl -V:version -V:archname"}).and_return([
      @status,
      @stdout,
      @stderr
    ])
  end

  it "should run perl -V:version -V:archname" do
    @plugin.should_receive(:run_command).with({:no_status_check=>true, :command=>"perl -V:version -V:archname"}).and_return(true)
    @plugin.run
  end

  it "should iterate over each line of perl command's stdout" do
    @stdout.should_receive(:each_line).and_return(true)
    @plugin.run
  end

  it "should set languages[:perl][:version]" do
    @plugin.run
    @plugin.languages[:perl][:version].should eql("5.8.8")
  end

  it "should set languages[:perl][:archname]" do
    @plugin.run
    @plugin.languages[:perl][:archname].should eql("darwin-thread-multi-2level")
  end

  it "should set languages[:perl] if perl command succeeds" do
    @status = 0
    @plugin.stub!(:run_command).with({:no_status_check=>true, :command=>"perl -V:version -V:archname"}).and_return([
      @status,
      @stdout,
      @stderr
    ])
    @plugin.run
    @plugin.languages.should have_key(:perl)
  end

  it "should not set languages[:perl] if perl command fails" do
     @status = 1
    @plugin.stub!(:run_command).with({:no_status_check=>true, :command=>"perl -V:version -V:archname"}).and_return([
      @status,
      @stdout,
      @stderr
     ])
     @plugin.run
     @plugin.languages.should_not have_key(:perl)
  end
end
