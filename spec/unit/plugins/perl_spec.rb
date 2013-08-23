#
# Author:: Joshua Timberman(<joshua@opscode.com>)
# Author:: Theodore Nordsieck (<theo@opscode.com>)
# Copyright:: Copyright (c) 2009-2013 Opscode, Inc.
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
    @plugin = get_plugin("perl")
    @plugin[:languages] = Mash.new
    @pid = 2342
    @stderr = StringIO.new
    @stdout = StringIO.new(<<-OUT)
version='5.8.8';
archname='darwin-thread-multi-2level';
OUT
    @stdin = StringIO.new
    @status = 0
    @plugin.stub(:run_command).with({:no_status_check=>true, :command=>"perl -V:version -V:archname"}).and_return([
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
    @plugin.stub(:run_command).with({:no_status_check=>true, :command=>"perl -V:version -V:archname"}).and_return([
                                                                                                                   @status,
                                                                                                                   @stdout,
                                                                                                                   @stderr
                                                                                                                  ])
    @plugin.run
    @plugin.languages.should have_key(:perl)
  end

  it "should not set languages[:perl] if perl command fails" do
    @status = 1
    @plugin.stub(:run_command).with({:no_status_check=>true, :command=>"perl -V:version -V:archname"}).and_return([
                                                                                                                   @status,
                                                                                                                   @stdout,
                                                                                                                   @stderr
                                                                                                                  ])
    @plugin.run
    @plugin.languages.should_not have_key(:perl)
  end

  #########

  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'path', 'ohai_plugin_common.rb'))

  test_plugin([ "languages", "perl" ], [ "perl" ]) do | p |
    p.test([ "centos-5.9" ], [ "x86" ], [[], [ "perl" ]],
           { "languages" => { "perl" => { "version" => "5.8.8", "archname" => "i386-linux-thread-multi" }}})
    p.test([ "centos-5.9" ], [ "x64" ], [[], [ "perl" ]],
           { "languages" => { "perl" => { "version" => "5.8.8", "archname" => "x86_64-linux-thread-multi" }}})
    p.test([ "centos-6.4" ], [ "x86" ], [[], [ "perl" ]],
           { "languages" => { "perl" => { "version" => "5.10.1", "archname" => "i386-linux-thread-multi" }}})
    p.test([ "centos-6.4" ], [ "x64" ], [[], [ "perl" ]],
           { "languages" => { "perl" => { "version" => "5.10.1", "archname" => "x86_64-linux-thread-multi" }}})
    p.test([ "ubuntu-10.04" ], [ "x86" ], [[], [ "perl" ]],
           { "languages" => { "perl" => { "version" => "5.10.1", "archname" => "i486-linux-gnu-thread-multi" }}})
    p.test([ "ubuntu-10.04" ], [ "x64" ], [[], [ "perl" ]],
           { "languages" => { "perl" => { "version" => "5.10.1", "archname" => "x86_64-linux-gnu-thread-multi" }}})
    p.test([ "ubuntu-12.04" ], [ "x86" ], [[], [ "perl" ]],
           { "languages" => { "perl" => { "version" => "5.14.2", "archname" => "i686-linux-gnu-thread-multi-64int" }}})
    p.test([ "ubuntu-12.04", "ubuntu-13.04" ], [ "x64" ], [[], [ "perl" ]],
           { "languages" => { "perl" => { "version" => "5.14.2", "archname" => "x86_64-linux-gnu-thread-multi" }}})
  end
end
