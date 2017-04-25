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

require_relative "../../spec_helper.rb"

describe Ohai::Mixin::Command, "shell_out" do
  let(:cmd) { "sparkle-dream --version" }

  let(:shell_out) { double("Mixlib::ShellOut") }

  let(:plugin_name) { :OSSparkleDream }

  let(:options) { windows? ? { timeout: 30 } : { timeout: 30, env: { "PATH" => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" } } }

  before(:each) do
    allow(Ohai::Mixin::Command).to receive(:name).and_return(plugin_name)
    @original_env = ENV.to_hash
    ENV.clear
  end

  after(:each) do
    ENV.clear
    ENV.update(@original_env)
  end

  describe "when the command runs" do
    it "logs the command and exitstatus" do
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

      Ohai::Mixin::Command.shell_out(cmd)
    end
  end

  describe "when the command does not exist" do
    it "logs the command and error message" do
      expect(Mixlib::ShellOut).
        to receive(:new).
        with(cmd, options).
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
        with(cmd, options).
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
    let(:options) { windows? ? { timeout: 10 } : { timeout: 10, env: { "PATH" => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" } } }

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
