#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright (c) 2026 Tim Smith
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

require "json"
require "stringio"
require "etc"

# Runs Ohai's darwin plugins against inputs recorded on a real macOS system
# (spec/data/darwin_replay/<name>.json): every command a plugin ran with its
# output and exit status, every `which` lookup, every file it checked or
# read, and uname.
#
# A command, file or program that wasn't recorded behaves as missing, so a
# plugin that starts reading something new shows up as a changed result.
module DarwinReplay
  FIXTURE_DIR = File.expand_path("../data/darwin_replay", __dir__)

  def self.fixture(name)
    JSON.parse(File.read(File.join(FIXTURE_DIR, "#{name}.json")))
  end

  def self.command(inputs, cmd)
    cmd = cmd.join(" ") if cmd.is_a?(Array)
    inputs["commands"].find { |c| c["cmd"] == cmd }
  end

  def self.file(inputs, path)
    entry = inputs["files"][path.to_s]
    entry if entry && entry["exist"]
  end

  # Runs the plugins that provide the given attributes, and those they
  # depend on, with the fixture's inputs. Returns the Ohai::System.
  def run_with_recorded_darwin_inputs(fixture, attributes)
    inputs = fixture["inputs"]
    allow(Etc).to receive(:uname).and_return(inputs["uname"].transform_keys(&:to_sym))
    allow_any_instance_of(Ohai::DSL::Plugin).to receive(:collect_os).and_return("darwin")

    %i{shell_out shell_out!}.each do |method|
      allow_any_instance_of(Ohai::DSL::Plugin).to receive(method) do |_plugin, cmd, **_opts|
        recorded = DarwinReplay.command(inputs, cmd)
        raise Ohai::Exceptions::Exec, "No such file or directory - #{cmd}" if recorded.nil? || recorded["raised"]

        double("Mixlib::ShellOut", stdout: recorded["stdout"], stderr: recorded["stderr"],
          exitstatus: recorded["exitstatus"], error!: nil,
          status: double(success?: recorded["exitstatus"] == 0))
      end
    end

    allow_any_instance_of(Ohai::DSL::Plugin).to receive(:which) do |_plugin, *cmds, **_opts|
      inputs["which"].fetch(cmds.join(" "), false)
    end
    allow_any_instance_of(Ohai::DSL::Plugin).to receive(:file_exist?) do |_plugin, path|
      !DarwinReplay.file(inputs, path).nil?
    end
    allow_any_instance_of(Ohai::DSL::Plugin).to receive(:file_read) do |_plugin, path|
      entry = DarwinReplay.file(inputs, path) || raise(Errno::ENOENT, path.to_s)
      entry["content"]
    end
    allow_any_instance_of(Ohai::DSL::Plugin).to receive(:file_open) do |_plugin, path, *_args, &blk|
      entry = DarwinReplay.file(inputs, path) || raise(Errno::ENOENT, path.to_s)
      io = StringIO.new(entry["content"])
      blk ? blk.call(io) : io
    end
    %i{file_directory? dir_exist?}.each do |method|
      allow_any_instance_of(Ohai::DSL::Plugin).to receive(method) do |_plugin, path|
        !!inputs["dirs"].dig(path.to_s, "exist")
      end
    end

    ohai = Ohai::System.new
    ohai.all_plugins(attributes)
    ohai
  end
end

RSpec.configure do |config|
  config.include DarwinReplay
end
