#
# Author:: Benjamin Black (<bb@chef.io>)
# Author:: Theodore Nordsieck (<theo@chef.io>)
# Copyright:: Copyright (c) 2009-2016 Chef Software, Inc.
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

require_relative "../../spec_helper.rb"

describe Ohai::System, "plugin java (Java5 Client VM)" do
  let(:plugin) { get_plugin("java") }

  before(:each) do
    plugin[:languages] = Mash.new
  end

  shared_examples_for "when the JRE is installed" do
    before do
      stderr = "java version \"1.5.0_16\"\nJava(TM) 2 Runtime Environment, Standard Edition (build 1.5.0_16-b06-284)\nJava HotSpot(TM) Client VM (build 1.5.0_16-133, mixed mode, sharing)"
      allow(plugin).to receive(:shell_out).with("java -mx64m -version").and_return(mock_shell_out(0, "", stderr))
    end

    it "runs java -mx64m -version" do
      expect(plugin).to receive(:shell_out).with("java -mx64m -version")
      plugin.run
    end

    it "sets java[:version]" do
      plugin.run
      expect(plugin[:languages][:java][:version]).to eql("1.5.0_16")
    end

    it "sets java[:runtime][:name] to runtime name" do
      plugin.run
      expect(plugin[:languages][:java][:runtime][:name]).to eql("Java(TM) 2 Runtime Environment, Standard Edition")
    end

    it "sets java[:runtime][:build] to runtime build" do
      plugin.run
      expect(plugin[:languages][:java][:runtime][:build]).to eql("1.5.0_16-b06-284")
    end

    it "sets java[:hotspot][:name] to hotspot name" do
      plugin.run
      expect(plugin[:languages][:java][:hotspot][:name]).to eql("Java HotSpot(TM) Client VM")
    end

    it "sets java[:hotspot][:build] to hotspot build" do
      plugin.run
      expect(plugin[:languages][:java][:hotspot][:build]).to eql("1.5.0_16-133, mixed mode, sharing")
    end

    it "does not set the languages[:java] tree up if java command fails" do
      stderr = "Some error output here"
      allow(plugin).to receive(:shell_out).with("java -mx64m -version").and_return(mock_shell_out(1, "", stderr))
      plugin.run
      expect(plugin[:languages]).not_to have_key(:java)
    end

    it "does not set the languages[:java] tree up if java command doesn't exist" do
      allow(plugin).to receive(:shell_out).and_raise(Ohai::Exceptions::Exec)
      plugin.run
      expect(plugin[:languages]).not_to have_key(:java)
    end
  end

  shared_examples_for "when the Server JRE is installed" do

    before(:each) do
      stderr = "java version \"1.6.0_22\"\nJava(TM) 2 Runtime Environment (build 1.6.0_22-b04)\nJava HotSpot(TM) Server VM (build 17.1-b03, mixed mode)"
      allow(plugin).to receive(:shell_out).with("java -mx64m -version").and_return(mock_shell_out(0, "", stderr))
    end

    it "runs java -mx64m -version" do
      expect(plugin).to receive(:shell_out).with("java -mx64m -version")
      plugin.run
    end

    it "sets java[:version]" do
      plugin.run
      expect(plugin[:languages][:java][:version]).to eql("1.6.0_22")
    end

    it "sets java[:runtime][:name] to runtime name" do
      plugin.run
      expect(plugin[:languages][:java][:runtime][:name]).to eql("Java(TM) 2 Runtime Environment")
    end

    it "sets java[:runtime][:build] to runtime build" do
      plugin.run
      expect(plugin[:languages][:java][:runtime][:build]).to eql("1.6.0_22-b04")
    end

    it "sets java[:hotspot][:name] to hotspot name" do
      plugin.run
      expect(plugin[:languages][:java][:hotspot][:name]).to eql("Java HotSpot(TM) Server VM")
    end

    it "sets java[:hotspot][:build] to hotspot build" do
      plugin.run
      expect(plugin[:languages][:java][:hotspot][:build]).to eql("17.1-b03, mixed mode")
    end

    it "does not set the languages[:java] tree up if java command fails" do
      stderr = "Some error output here"
      allow(plugin).to receive(:shell_out).with("java -mx64m -version").and_return(mock_shell_out(0, "", stderr))
      plugin.run
      expect(plugin[:languages]).not_to have_key(:java)
    end
  end

  shared_examples_for "when the openjdk 1.8 is installed" do

    before(:each) do
      stderr = "openjdk version \"1.8.0_71\"\nOpenJDK Runtime Environment (build 1.8.0_71-b15)\nOpenJDK 64-Bit Server VM (build 25.71-b15, mixed mode)"
      allow(plugin).to receive(:shell_out).with("java -mx64m -version").and_return(mock_shell_out(0, "", stderr))
    end

    it "runs java -mx64m -version" do
      expect(plugin).to receive(:shell_out).with("java -mx64m -version")
      plugin.run
    end

    it "sets java[:version]" do
      plugin.run
      expect(plugin[:languages][:java][:version]).to eql("1.8.0_71")
    end

    it "sets java[:runtime][:name] to runtime name" do
      plugin.run
      expect(plugin[:languages][:java][:runtime][:name]).to eql("OpenJDK Runtime Environment")
    end

    it "sets java[:runtime][:build] to runtime build" do
      plugin.run
      expect(plugin[:languages][:java][:runtime][:build]).to eql("1.8.0_71-b15")
    end

    it "sets java[:hotspot][:name] to hotspot name" do
      plugin.run
      expect(plugin[:languages][:java][:hotspot][:name]).to eql("OpenJDK 64-Bit Server VM")
    end

    it "sets java[:hotspot][:build] to hotspot build" do
      plugin.run
      expect(plugin[:languages][:java][:hotspot][:build]).to eql("25.71-b15, mixed mode")
    end

    it "does not set the languages[:java] tree up if java command fails" do
      stderr = "Some error output here"
      allow(plugin).to receive(:shell_out).with("java -mx64m -version").and_return(mock_shell_out(0, "", stderr))
      plugin.run
      expect(plugin[:languages]).not_to have_key(:java)
    end
  end

  context "when not on Mac OS X" do
    before do
      stub_const("RUBY_PLATFORM", "x86_64-linux")
    end

    context "and the client JRE is installed" do
      include_examples "when the JRE is installed"
    end
    context "and the server JRE is installed" do
      include_examples "when the Server JRE is installed"
    end
    context "and the openjdk 1.8 is installed" do
      include_examples "when the openjdk 1.8 is installed"
    end
  end

  context "when on Mac OS X with Java installed" do
    before do
      stub_const("RUBY_PLATFORM", "x86_64-darwin12.3.0")
    end

    it "detects that it is on a darwin platform" do
      expect(plugin).to be_on_darwin
    end

    context "and real Java is installed" do
      before do
        java_home_status = double(Process::Status, :success? => true)
        java_home_cmd = double(Mixlib::ShellOut, :status => java_home_status)
        expect(plugin).to receive(:shell_out).with("/usr/libexec/java_home").and_return(java_home_cmd)
      end

      context "and the client JRE is installed" do
        include_examples "when the JRE is installed"
      end
      context "and the server JRE is installed" do
        include_examples "when the Server JRE is installed"
      end
      context "and the openjdk 1.8 is installed" do
        include_examples "when the openjdk 1.8 is installed"
      end
    end

    context "and the JVM stubs are installed" do
      before do
        java_home_status = double(Process::Status, :success? => false)
        java_home_cmd = double(Mixlib::ShellOut, :status => java_home_status)
        expect(plugin).to receive(:shell_out).with("/usr/libexec/java_home").and_return(java_home_cmd)
      end

      it "does not attempt to get java info" do
        expect(plugin).not_to receive(:shell_out).with("java -mx64m -version")
        plugin.run
        expect(plugin[:languages]).not_to have_key(:java)
      end
    end
  end
end
