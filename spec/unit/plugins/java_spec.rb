#
# Author:: Benjamin Black (<bb@opscode.com>)
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

describe Ohai::System, "plugin java (Java5 Client VM)" do
  before(:each) do
    @plugin = get_plugin("java")
    @plugin[:languages] = Mash.new
    @stderr = "java version \"1.5.0_16\"\nJava(TM) 2 Runtime Environment, Standard Edition (build 1.5.0_16-b06-284)\nJava HotSpot(TM) Client VM (build 1.5.0_16-133, mixed mode, sharing)"
    @plugin.stub(:shell_out).with("java -version").and_return(mock_shell_out(0, "", @stderr))
  end

  it "should run java -version" do
    @plugin.should_receive(:shell_out).with("java -version").and_return(mock_shell_out(0, "", @stderr))
    @plugin.run
  end

  it "should set java[:version]" do
    @plugin.run
    @plugin[:languages][:java][:version].should eql("1.5.0_16")
  end

  it "should set java[:runtime][:name] to runtime name" do
    @plugin.run
    @plugin[:languages][:java][:runtime][:name].should eql("Java(TM) 2 Runtime Environment, Standard Edition")
  end

  it "should set java[:runtime][:build] to runtime build" do
    @plugin.run
    @plugin[:languages][:java][:runtime][:build].should eql("1.5.0_16-b06-284")
  end

  it "should set java[:hotspot][:name] to hotspot name" do
    @plugin.run
    @plugin[:languages][:java][:hotspot][:name].should eql("Java HotSpot(TM) Client VM")
  end

  it "should set java[:hotspot][:build] to hotspot build" do
    @plugin.run
    @plugin[:languages][:java][:hotspot][:build].should eql("1.5.0_16-133, mixed mode, sharing")
  end

  it "should not set the languages[:java] tree up if java command fails" do
    @stderr = "Some error output here"
    @plugin.stub(:shell_out).with("java -version").and_return(mock_shell_out(1, "", @stderr))
    @plugin.run
    @plugin[:languages].should_not have_key(:java)
  end
end

describe Ohai::System, "plugin java (Java6 Server VM)" do
  before(:each) do
    @plugin = get_plugin("java")
    @plugin[:languages] = Mash.new
    @stderr = "java version \"1.6.0_22\"\nJava(TM) 2 Runtime Environment (build 1.6.0_22-b04)\nJava HotSpot(TM) Server VM (build 17.1-b03, mixed mode)"
    @plugin.stub(:shell_out).with("java -version").and_return(mock_shell_out(0, "", @stderr))
  end

  it "should run java -version" do
    @plugin.should_receive(:shell_out).with("java -version").and_return(mock_shell_out(0, "", @stderr))
    @plugin.run
  end

  it "should set java[:version]" do
    @plugin.run
    @plugin[:languages][:java][:version].should eql("1.6.0_22")
  end

  it "should set java[:runtime][:name] to runtime name" do
    @plugin.run
    @plugin[:languages][:java][:runtime][:name].should eql("Java(TM) 2 Runtime Environment")
  end

  it "should set java[:runtime][:build] to runtime build" do
    @plugin.run
    @plugin[:languages][:java][:runtime][:build].should eql("1.6.0_22-b04")
  end

  it "should set java[:hotspot][:name] to hotspot name" do
    @plugin.run
    @plugin[:languages][:java][:hotspot][:name].should eql("Java HotSpot(TM) Server VM")
  end

  it "should set java[:hotspot][:build] to hotspot build" do
    @plugin.run
    @plugin[:languages][:java][:hotspot][:build].should eql("17.1-b03, mixed mode")
  end

  it "should not set the languages[:java] tree up if java command fails" do
    @stderr = "Some error output here"
    @plugin.stub(:shell_out).with("java -version").and_return(mock_shell_out(0, "", @stderr))
    @plugin.run
    @plugin[:languages].should_not have_key(:java)
  end


  ###########

  require File.expand_path(File.dirname(__FILE__) + '/../path/ohai_plugin_common.rb')

  test_plugin([ "languages", "java" ], [ "java" ]) do | p |
    p.test([ "centos-5.9", "centos-6.4", "ubuntu-10.04", "ubuntu-12.04" ], [ "x86", "x64" ], [[]],
           { "languages" => { "java" => nil }})
    p.test([ "ubuntu-13.04" ], [ "x64" ], [[]],
           { "languages" => { "java" => nil }})
    p.test([ "centos-5.9" ], [ "x86" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_24",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.11.11.90)", "build" => "rhel-1.41.1.11.11.90.el5_9-i386" },
                 "hotspot" => { "name" => "OpenJDK Client VM", "build" => "20.0-b12, mixed mode" }}}})
    p.test([ "centos-5.9" ], [ "x64" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_24",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.11.11.90)", "build" => "rhel-1.41.1.11.11.90.el5_9-x86_64" },
                 "hotspot" => { "name" => "OpenJDK 64-Bit Server VM", "build" => "20.0-b12, mixed mode" }}}})
    p.test([ "centos-6.4" ], [ "x86" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_24",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.11.11.90)", "build" => "rhel-1.62.1.11.11.90.el6_4-i386" },
                 "hotspot" => { "name" => "OpenJDK Client VM", "build" => "20.0-b12, mixed mode" }}}})
    p.test([ "centos-6.4" ], [ "x64" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_24",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.11.11.90)", "build" => "rhel-1.62.1.11.11.90.el6_4-x86_64" },
                 "hotspot" => { "name" => "OpenJDK 64-Bit Server VM", "build" => "20.0-b12, mixed mode" }}}})
    p.test([ "ubuntu-10.04" ], [ "x86" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_27",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.12.5)", "build" => "6b27-1.12.5-0ubuntu0.10.04.1" },
                 "hotspot" => { "name" => "OpenJDK Client VM", "build" => "20.0-b12, mixed mode, sharing" }}}})
    p.test([ "ubuntu-10.04" ], [ "x64" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_27",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.12.5)", "build" => "6b27-1.12.5-0ubuntu0.10.04.1" },
                 "hotspot" => { "name" => "OpenJDK 64-Bit Server VM", "build" => "20.0-b12, mixed mode" }}}})
    p.test([ "ubuntu-12.04" ], [ "x86" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_27",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.12.5)", "build" => "6b27-1.12.5-0ubuntu0.12.04.1" },
                 "hotspot" => { "name" => "OpenJDK Client VM", "build" => "20.0-b12, mixed mode, sharing" }}}})
    p.test([ "ubuntu-12.04" ], [ "x64" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_27",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.12.5)", "build" => "6b27-1.12.5-0ubuntu0.12.04.1" },
                 "hotspot" => { "name" => "OpenJDK 64-Bit Server VM", "build" => "20.0-b12, mixed mode" }}}})
    p.test([ "ubuntu-13.04" ], [ "x64" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_27",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.12.5)", "build" => "6b27-1.12.5-1ubuntu1" },
                 "hotspot" => { "name" => "OpenJDK 64-Bit Server VM", "build" => "20.0-b12, mixed mode" }}}})
  end
end
