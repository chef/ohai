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

# Runs Ohai's Linux plugins against inputs recorded on a real system
# (spec/data/linux_replay/<name>.json): every command a plugin ran with its
# output and exit status, every file and directory it looked at or read,
# and uname. Plugin code sees those instead of the machine running the
# specs; any other caller of File and Dir is unaffected.
#
# A command or path that wasn't recorded behaves as missing, so a plugin
# that starts reading something new shows up as a changed result.
module LinuxReplay
  FIXTURE_DIR = File.expand_path("../data/linux_replay", __dir__)
  PLUGIN_CODE = %r{/lib/ohai/(plugins|mixin|dsl)/}

  class << self
    attr_accessor :inputs, :used

    def active?
      !inputs.nil?
    end

    def from_plugin?
      active? && caller_locations(2, 16).any? { |l| l.path.to_s.match?(PLUGIN_CODE) }
    end

    def file(path)
      used["files"][path] = true
      inputs["files"][path.to_s]
    end

    def dir(key)
      used["dirs"][key] = true
      inputs["dirs"][key]
    end

    def content(path)
      entry = file(path)
      raise Errno::ENOENT, path.to_s unless entry && entry["exist"]
      raise Errno::EACCES, path.to_s if entry["error"]
      raise Errno::EISDIR, path.to_s if entry["type"] == "directory"
      return entry["content_base64"].unpack1("m0") if entry["content_base64"]

      entry["content"] || ""
    end

    # commands are matched exactly, then by the program's basename: which()
    # can resolve a different but equivalent path on the machine running
    # the specs (/sbin/ip for /usr/sbin/ip)
    def command(cmd)
      cmd = cmd.join(" ") if cmd.is_a?(Array)
      used["commands"][cmd] = true
      recorded = inputs["commands"].find { |c| c["cmd"] == cmd }
      recorded ||= inputs["commands"].find { |c| basename_command(c["cmd"]) == basename_command(cmd) }
      used["commands"][recorded["cmd"]] = true if recorded
      recorded
    end

    def basename_command(cmd)
      cmd.sub(%r{\A/\S*/(\S+)}, '\1')
    end
  end

  module FileMethods
    %i{exist? file? directory? readable? executable? symlink? size size? readlink}.each do |m|
      define_method(m) do |path, *args, **kw, &blk|
        return super(path, *args, **kw, &blk) unless path.is_a?(String) && path.start_with?("/") && LinuxReplay.from_plugin?

        entry = LinuxReplay.file(path)
        dir = LinuxReplay.inputs["dirs"][path]
        exists = (entry && entry["exist"]) || (dir && dir["exist"])
        case m
        when :exist?, :readable?, :executable? then !!exists
        when :file? then !!(entry && entry["exist"] && entry["type"] == "file")
        when :directory? then !!((dir && dir["exist"]) || (entry && entry["type"] == "directory"))
        when :symlink? then !!(entry && entry["type"] == "link")
        when :readlink then entry&.dig("readlink") || raise(Errno::EINVAL, path)
        when :size? then exists ? LinuxReplay.content(path).bytesize : nil
        else # size
          raise Errno::ENOENT, path unless exists

          LinuxReplay.content(path).bytesize
        end
      end
    end

    def read(path, *args, **kw)
      return super unless path.is_a?(String) && path.start_with?("/") && LinuxReplay.from_plugin?

      LinuxReplay.content(path)
    end

    def binread(path, *args)
      return super unless path.is_a?(String) && path.start_with?("/") && LinuxReplay.from_plugin?

      LinuxReplay.content(path).b
    end

    def readlines(path, *args, **kw)
      return super unless path.is_a?(String) && path.start_with?("/") && LinuxReplay.from_plugin?

      LinuxReplay.content(path).lines
    end

    def foreach(path, *args, **kw, &blk)
      return super unless path.is_a?(String) && path.start_with?("/") && LinuxReplay.from_plugin?

      lines = LinuxReplay.content(path).lines
      blk ? lines.each(&blk) : lines.each
    end

    def open(path, *args, **kw, &blk)
      return super unless path.is_a?(String) && path.start_with?("/") && LinuxReplay.from_plugin?

      io = StringIO.new(LinuxReplay.content(path))
      blk ? blk.call(io) : io
    end
  end

  module DirMethods
    def exist?(path, *args, **kw)
      return super unless path.is_a?(String) && LinuxReplay.from_plugin?

      entry = LinuxReplay.dir(path)
      !!(entry && entry["exist"])
    end

    %i{children entries each_child}.each do |m|
      define_method(m) do |path, *args, **kw, &blk|
        return super(path, *args, **kw, &blk) unless path.is_a?(String) && LinuxReplay.from_plugin?

        entry = LinuxReplay.dir(path)
        raise Errno::ENOENT, path unless entry && entry["exist"]

        children = entry["children"] || []
        children = %w{. ..} + children if m == :entries
        return children.each(&blk) if blk

        m == :each_child ? children.each : children
      end
    end

    def glob(pattern, *args, **kw, &blk)
      return super unless LinuxReplay.from_plugin?

      entry = LinuxReplay.dir("glob:#{Array(pattern).join(",")}")
      matches = entry ? entry["glob"] : []
      blk ? matches.each(&blk) : matches
    end

    alias_method :[], :glob
  end

  ::File.singleton_class.prepend(FileMethods)
  ::Dir.singleton_class.prepend(DirMethods)

  def self.fixture(name)
    JSON.parse(File.read(File.join(FIXTURE_DIR, "#{name}.json")))
  end

  # Runs the plugins that provide the given attributes, and those they
  # depend on, with the fixture's inputs. Returns the Ohai::System.
  def run_with_recorded_inputs(fixture, attributes)
    LinuxReplay.inputs = fixture["inputs"]
    LinuxReplay.used = { "commands" => {}, "files" => {}, "dirs" => {} }
    uname = fixture["inputs"]["uname"].transform_keys(&:to_sym)
    allow(Etc).to receive(:uname).and_return(uname)
    allow_any_instance_of(Ohai::DSL::Plugin).to receive(:collect_os).and_return("linux")
    # shell_out! too: Ohai's dir_glob lists directories with "ls -d"
    %i{shell_out shell_out!}.each do |method|
      allow_any_instance_of(Ohai::DSL::Plugin).to receive(method) do |_plugin, cmd, **_opts|
        recorded = LinuxReplay.command(cmd)
        raise Ohai::Exceptions::Exec, "No such file or directory - #{cmd}" if recorded.nil? || recorded["raised"]

        double("Mixlib::ShellOut", stdout: recorded["stdout"], stderr: recorded["stderr"],
          exitstatus: recorded["exitstatus"], error!: nil,
          status: double(success?: recorded["exitstatus"] == 0))
      end
    end
    ohai = Ohai::System.new
    ohai.all_plugins(attributes)
    ohai
  ensure
    LinuxReplay.inputs = nil
  end
end

RSpec.configure do |config|
  config.include LinuxReplay
end
