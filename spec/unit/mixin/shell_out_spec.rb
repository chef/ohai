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

require "spec_helper"

describe Ohai::Mixin::ShellOut, "shell_out" do
  let(:cmd) { "sparkle-dream --version" }

  let(:shell_out) { double("Mixlib::ShellOut", live_stream: nil, :live_stream= => nil) }

  let(:plugin_name) { :OSSparkleDream }

  let(:timeout) { 30 }

  let(:options) do
    path_var = windows? ? "Path" : "PATH"

    # this just replicates the behavior of default_paths in chef-utils
    split_path = instance.send(:__env_path).split(File::PATH_SEPARATOR)
    default_paths = [ RbConfig::CONFIG["bindir"], Gem.bindir, split_path ].flatten.compact.uniq

    if windows?
      default_paths = default_paths.join(";")
    else
      default_paths = ( default_paths + [ "/usr/local/sbin", "/usr/local/bin", "/usr/sbin", "/usr/bin", "/sbin", "/bin" ] ).compact.uniq.join(":")
    end

    default_locale = ChefConfig::Config.guess_internal_locale
    {
      timeout: timeout,
      environment: {
        "LANG" => default_locale,
        "LANGUAGE" => default_locale,
        "LC_ALL" => default_locale,
        path_var => default_paths,
      },
    }
  end

  let(:logger) { instance_double("Mixlib::Log::Child", trace: nil, debug: nil, warn: nil, trace?: false, debug?: false) }

  class DummyPlugin
    include Ohai::Mixin::ShellOut
    def transport_connection
      nil
    end
  end

  let(:instance) { DummyPlugin.new }

  before do
    allow(instance).to receive(:logger).and_return(logger)
    allow(instance).to receive(:name).and_return(plugin_name)
    @original_env = ENV.to_hash
    ENV.clear
  end

  after do
    ENV.clear
    ENV.update(@original_env)
  end

  describe "when the command runs" do
    it "logs the command and exitstatus" do
      expect(Mixlib::ShellOut).to receive(:new).with(cmd, options).and_return(shell_out)
      expect(shell_out).to receive(:run_command)
      expect(shell_out).to receive(:exitstatus).and_return(256)
      expect(logger).to receive(:trace)
        .with("Plugin OSSparkleDream: ran 'sparkle-dream --version' and returned 256")
      instance.shell_out(cmd)
    end
  end

  describe "when the command does not exist" do
    it "logs the command and error message" do
      expect(Mixlib::ShellOut).to receive(:new).with(cmd, options).and_return(shell_out)
      expect(shell_out).to receive(:run_command).and_raise(Errno::ENOENT, "sparkle-dream")
      expect(logger).to receive(:trace)
        .with("Plugin OSSparkleDream: ran 'sparkle-dream --version' and failed " \
              "#<Errno::ENOENT: No such file or directory - sparkle-dream>")
      expect { instance.shell_out(cmd) }.to raise_error(Ohai::Exceptions::Exec)
    end
  end

  describe "when the command times out" do
    it "logs the command an timeout error message" do
      expect(Mixlib::ShellOut).to receive(:new).with(cmd, options).and_return(shell_out)
      expect(shell_out).to receive(:run_command).and_raise(Mixlib::ShellOut::CommandTimeout)
      expect(logger).to receive(:trace)
        .with("Plugin OSSparkleDream: ran 'sparkle-dream --version' and timed out after 30 seconds")
      expect { instance.shell_out(cmd) }.to raise_error(Ohai::Exceptions::Exec)
    end
  end

  describe "when a timeout option is provided" do
    let(:timeout) { 10 }

    it "runs the command with the provided timeout" do
      expect(Mixlib::ShellOut).to receive(:new).with(cmd, options).and_return(shell_out)
      expect(shell_out).to receive(:run_command)
      expect(shell_out).to receive(:exitstatus).and_return(256)
      expect(logger).to receive(:trace)
        .with("Plugin OSSparkleDream: ran 'sparkle-dream --version' and returned 256")
      instance.shell_out(cmd, timeout: 10)
    end

    describe "when the command times out" do
      it "logs the command an timeout error message" do
        expect(Mixlib::ShellOut).to receive(:new).with(cmd, options).and_return(shell_out)
        expect(shell_out).to receive(:run_command).and_raise(Mixlib::ShellOut::CommandTimeout)
        expect(logger).to receive(:trace)
          .with("Plugin OSSparkleDream: ran 'sparkle-dream --version' and timed out after 10 seconds")
        expect { instance.shell_out(cmd, timeout: 10) }.to raise_error(Ohai::Exceptions::Exec)
      end
    end
  end
end
