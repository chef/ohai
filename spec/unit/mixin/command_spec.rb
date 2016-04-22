# encoding: utf-8
#
# Author:: Diego Algorta (diego@oboxodo.com)
# Copyright:: Copyright (c) 2009 Diego Algorta
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

require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper.rb")

describe Ohai::Mixin::Command, "popen4" do
  break if RUBY_PLATFORM =~ /(win|w)32$/

  it "should default all commands to be run in the POSIX standard C locale" do
    Ohai::Mixin::Command.popen4("echo $LC_ALL") do |pid, stdin, stdout, stderr|
      stdin.close
      expect(stdout.read.strip).to eq("C")
    end
  end

  it "should respect locale when specified explicitly" do
    Ohai::Mixin::Command.popen4("echo $LC_ALL", :environment => { "LC_ALL" => "es" }) do |pid, stdin, stdout, stderr|
      stdin.close
      expect(stdout.read.strip).to eq("es")
    end
  end

  if defined?(::Encoding) && "".respond_to?(:force_encoding) #i.e., ruby 1.9
    context "when external commands return UTF-8 strings and we are running under LANG=C encoding" do
      before do
        @saved_default_external = Encoding.default_external
        @saved_default_internal = Encoding.default_internal
        Encoding.default_external = Encoding::US_ASCII
        Encoding.default_internal = Encoding::US_ASCII
      end

      after do
        Encoding.default_external = @saved_default_external
        Encoding.default_internal = @saved_default_internal
      end

      it "should force encode the string to UTF-8" do
        extend Ohai::Mixin::Command
        snowy = run_command(:command => ("echo '" + ("☃" * 8096) + "'"))[1]
        expect(snowy.encoding).to eq(Encoding::UTF_8)
      end
    end

    it "should force encode the string to UTF-8" do
      extend Ohai::Mixin::Command
      snowy = run_command(:command => ("echo '" + ("☃" * 8096) + "'"))[1]
      expect(snowy.encoding).to eq(Encoding::UTF_8)
    end
  end

  it "reaps zombie processes after exec fails [OHAI-455]" do
    # NOTE: depending on ulimit settings, GC, etc., before the OHAI-455 patch,
    # ohai could also exhaust the available file descriptors when creating this
    # many zombie processes. A regression _could_ cause Errno::EMFILE but this
    # probably won't be consistent on different environments.
    created_procs = 0
    100.times do
      begin
        Ohai::Mixin::Command.popen4("/bin/this-is-not-a-real-command") { |p, i, o, e| nil }
      rescue Ohai::Exceptions::Exec
        created_procs += 1
      end
    end
    expect(created_procs).to eq(100)
    reaped_procs = 0
    begin
      loop { Process.wait(-1); reaped_procs += 1 }
    rescue Errno::ECHILD
    end
    expect(reaped_procs).to eq(0)
  end
end

describe Ohai::Mixin::Command, "shell_out" do
  let(:cmd) { "sparkle-dream --version" }

  let(:shell_out) { double("Mixlib::ShellOut") }

  let(:plugin_name) { :OSSparkleDream }

  before(:each) do
    allow(Ohai::Mixin::Command).to receive(:name).and_return(plugin_name)
  end

  describe "when the command runs" do
    it "logs the command and exitstatus" do
      expect(Mixlib::ShellOut).
        to receive(:new).
        with(cmd, { timeout: 30 }).
        and_return(shell_out)

      expect(shell_out).
        to receive(:run_command)

      expect(shell_out).
        to receive(:exitstatus).
        and_return(256)

      expect(Ohai::Log).to receive(:debug).
        with("Plugin OSSparkleDream: ran 'sparkle-dream --version' and returned 256")

      Ohai::Mixin::Command.shell_out(cmd)
    end
  end

  describe "when the command does not exist" do
    it "logs the command and error message" do
      expect(Mixlib::ShellOut).
        to receive(:new).
        with(cmd, { timeout: 30 }).
        and_return(shell_out)

      expect(shell_out).
        to receive(:run_command).
        and_raise(Errno::ENOENT, "sparkle-dream")

      expect(Ohai::Log).
        to receive(:debug).
        with("Plugin OSSparkleDream: ran 'sparkle-dream --version' and failed " \
             "#<Errno::ENOENT: No such file or directory - sparkle-dream>")

      expect { Ohai::Mixin::Command.shell_out(cmd) }.
        to raise_error(Ohai::Exceptions::Exec)
    end
  end

  describe "when the command times out" do
    it "logs the command an timeout error message" do
      expect(Mixlib::ShellOut).
        to receive(:new).
        with(cmd, { timeout: 30 }).
        and_return(shell_out)

      expect(shell_out).
        to receive(:run_command).
        and_raise(Mixlib::ShellOut::CommandTimeout)

      expect(Ohai::Log).
        to receive(:debug).
        with("Plugin OSSparkleDream: ran 'sparkle-dream --version' and timed " \
             "out after 30 seconds")

      expect { Ohai::Mixin::Command.shell_out(cmd) }.
        to raise_error(Ohai::Exceptions::Exec)
    end
  end

  describe "when a timeout option is provided" do
    let(:options) { { timeout: 10 } }

    it "runs the command with the provided timeout" do
      expect(Mixlib::ShellOut).
        to receive(:new).
        with(cmd, options).
        and_return(shell_out)

      expect(shell_out).
        to receive(:run_command)

      expect(shell_out).
        to receive(:exitstatus).
        and_return(256)

      expect(Ohai::Log).to receive(:debug).
        with("Plugin OSSparkleDream: ran 'sparkle-dream --version' and returned 256")

      Ohai::Mixin::Command.shell_out(cmd, options)
    end

    describe "when the command times out" do
      it "logs the command an timeout error message" do
        expect(Mixlib::ShellOut).
          to receive(:new).
          with(cmd, options).
          and_return(shell_out)

        expect(shell_out).
          to receive(:run_command).
          and_raise(Mixlib::ShellOut::CommandTimeout)

        expect(Ohai::Log).
          to receive(:debug).
          with("Plugin OSSparkleDream: ran 'sparkle-dream --version' and timed " \
               "out after 10 seconds")

        expect { Ohai::Mixin::Command.shell_out(cmd, options) }.
          to raise_error(Ohai::Exceptions::Exec)
      end
    end
  end
end
