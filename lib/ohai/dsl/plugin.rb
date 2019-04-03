#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Claire McQuin (<claire@chef.io>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "ohai/mixin/os"
require "ohai/mixin/command"
require "ohai/mixin/seconds_to_human"
require "ohai/hints"
require "ohai/util/file_helper"

module Ohai

  # For plugin namespacing
  module NamedPlugin

    # Is the plugin a Symbol starting with a capital letter that has no underscores
    #
    # @param name [String] the plugin name
    # @return [Boolean]
    def self.valid_name?(name)
      name.is_a?(Symbol) && name.to_s.match(/^[^A-Z]|_/).nil?
    end

    # @return [Boolean]
    def self.strict_const_defined?(const)
      const_defined?(const, false)
    end
  end

  # @param name [String]
  def self.plugin(name, &block)
    raise Ohai::Exceptions::InvalidPluginName, "#{name} is not a valid plugin name. A valid plugin name is a symbol which begins with a capital letter and contains no underscores" unless NamedPlugin.valid_name?(name)

    plugin = nil

    # avoid already initialized constant warnings if already defined
    if NamedPlugin.strict_const_defined?(name)
      plugin = NamedPlugin.const_get(name)
      plugin.class_eval(&block)
    else
      klass = Class.new(DSL::Plugin::VersionVII, &block)
      plugin = NamedPlugin.const_set(name, klass)
    end

    plugin
  end

  # Cross platform /dev/null to support testability
  #
  # @return [String]
  def self.dev_null
    if RUBY_PLATFORM =~ /mswin|mingw|windows/
      "NUL"
    else
      "/dev/null"
    end
  end

  # Extracted abs_path to support testability:
  # This method gets overridden at test time, to force the shell to check
  # ohai/spec/unit/path/original/absolute/path/to/exe
  def self.abs_path( abs_path )
    abs_path
  end

  module DSL
    class Plugin

      def __collect_os(family)
        case family
        when /aix/
          "aix"
        when /darwin$/
          "darwin"
        when /linux/
          "linux"
        when /freebsd/
          "freebsd"
        when /openbsd/
          "openbsd"
        when /netbsd/
          "netbsd"
        when /dragonfly/
          "dragonflybsd"
        when /solaris2/
          "solaris2"
        when /mswin|mingw32|windows/
          # After long discussion in IRC the "powers that be" have come to a consensus
          # that no Windows platform exists that was not based on the
          # Windows_NT kernel, so we herby decree that "windows" will refer to all
          # platforms built upon the Windows_NT kernel and have access to win32 or win64
          # subsystems.
          "windows"
        else
          nil
        end
      end

      # include Ohai::Mixin::OS
      def collect_os
        # NOTE: The original mixin for this returned some values different than
        #   what is being returned by the train connection.
        # TODO: the result when on centos was the value redhat but really what 
        #   what we want is linux - at least that is what I believe is suppose
        #   to be the os value for the plugins to match on the collect_data blocks
        found_os = data[:backend].os[:family_hierarchy].find { |family| __collect_os(family) }
        # require 'pry' ; binding.pry
        if found_os.nil?
          require 'pry' ; binding.pry
          logger.error('There is a problem with the os detection mechanism')
        end
        found_os
      end

      # include Ohai::Mixin::Command
      # This mixin is replaced currently with this method.
      def shell_out(cmd, **options)
        # require 'pry' ; binding.pry
        logger.info("Running: #{cmd}")
        result = data[:backend].run_command(cmd)
        result
      end

      def can_connect?(address, port = 80, timeout = 2)
        # require 'pry' ; binding.pry
        shell_out("curl -Is #{address}:#{port} --connect-timeout #{timeout}").exit_status == 0
      end

      include Ohai::Mixin::SecondsToHuman
      
      # include Ohai::Util::FileHelper
      # This mixin is replaced currently with this method.
      def which(cmd)
        # require 'pry' ; binding.pry

        # TODO: the interface here is poor it returns the cmd back when it fails to find
        #   a full path. On success it returns the full path.
        #
        #   Perhaps:
        # 
        #     result = which('ifconfig').args('-a').run
        #     result.stdout
        #     result.stderr
        #     result.exit_status
        #     result.success?
        #     result.success!     # throw an exception if the command failed
        #     result.fail?
        #     result.fail!        # throw an exception if the command successful
        #
        #   If which were to fail then it would return a FailedToFindCommand that would still
        #   accept args which would still run. The choices with result feels mostly poor
        #   all around. Generally it could throw exception by default or be disabled by default
        #   Or it could be suggested to use the exclamation methods to control the flow 
        #   that way by default.

        # TODO: better performance can be found in the comments below
        # The ssh backend can give you the results of `echo $PATH`
        # But often commands found in /sbin were not being found and that may be because of
        # some difference in the shell created.
        #
        # We can call which and if it doesn't come up we could resort to combing every path ...
        #   but this is where it may more efficient to ls every directory and create a big table
        #   of paths and then search through that ... this means the first time which
        #   misses then the multple `ls` would fire and the data would be parsed and stored.
        #   all other calls would use that cache.

        which = data[:backend].run_command("which #{cmd}")
        return which.stdout.chomp if which.exit_status == 0

        # paths = ENV["PATH"].split(File::PATH_SEPARATOR) + [ "/bin", "/usr/bin", "/sbin", "/usr/sbin" ]
        paths = data[:backend].run_command("echo $PATH").stdout.split(File::PATH_SEPARATOR) + [ "/bin", "/usr/bin", "/sbin", "/usr/sbin" ]
        paths.each do |path|
          filename = File.join(path, cmd)
          if file_executable?(filename)
            logger.trace("Plugin #{name}: found #{cmd} at #{filename}")
            return filename
          end
        end
        logger.warn("Plugin #{name}: did not find #{cmd}")
        # NOTE this was a poor interface - originally this returned a filename or false
        #  I have changed it to return the same command that it was given and that will
        #  likely result in no data collected but at least a well-formed command
        cmd
      end

      # This is to provide a replacement for `File.exist?`
      def file_exist?(filename)
        # require 'pry' ; binding.pry
        data[:backend].file(filename).exist?
      end

      # This is to provide a replacement for `File.open`
      # returning a stringio gets you support for `gets` `lines`
      # taking the block brings it on par with `File.open` use of block
      def file_open(filename)
        # require 'pry' ; binding.pry
        content = data[:backend].file(filename).content
        # NOTE: StringIO is the superclass for File. This has a nearly
        #   the same interface which gives it the ability to be a replacement
        string_io = StringIO.new content
        yield string_io if block_given?
        string_io
      end

      # This is to provide a replacement for `File.executable?`
      def file_executable?(filename)
        # require 'pry' ; binding.pry
        # TODO: Is the file executable to the current user?
        #   At the moment I don't know how to get the current user (local and remote)          
        # TODO: this will need to be updated to support windows
        file_mode = data[:backend].file(filename).stat[:mode]
        permissions = file_mode.to_i.to_s(8)

        # TODO: use another mechanic to find executable - bit mask / etc.
        #   as this is a quick implementation to to satisfy some common modes
        permissions == "755" || permissions == "555"
      end

      # This is to provide a replacement for `File.read`
      def file_read(filename)
        # require 'pry' ; binding.pry
        data[:backend].file(filename).content
      end

      # This is to provide a replacement for `File.realines`
      def file_readlines(filename)
        file_read(filename).lines
      end

      # This is to provide a replacement for Dir[] and Dir.glob
      def files_in_dir(path)
        # require 'pry' ; binding.pry
        # TODO: This would need to support windows.
        data[:backend].run_command("ls -d #{path}").stdout.split
      end

      attr_reader :data
      attr_reader :failed
      attr_reader :logger

      def initialize(data, logger)
        @data = data
        @logger = logger.with_child({ subsystem: "plugin", plugin: name })
        @has_run = false
        @failed = false
      end

      def run
        @has_run = true

        if Ohai.config[:disabled_plugins].include?(name)
          logger.trace("Skipping disabled plugin #{name}")
        else
          run_plugin
        end
      end

      def has_run?
        @has_run
      end

      def reset!
        @has_run = false
      end

      def [](key)
        @data[key]
      end

      def []=(key, value)
        @data[key] = value
      end

      def each(&block)
        @data.each do |key, value|
          yield(key, value)
        end
      end

      def has_key?(name)
        @data.key?(name)
      end

      def attribute?(name, *keys)
        !safe_get_attribute(name, *keys).nil?
      end

      def set(name, *value)
        set_attribute(name, *value)
      end

      def from(cmd)
        _status, stdout, _stderr = run_command(command: cmd)
        return "" if stdout.nil? || stdout.empty?
        stdout.strip
      end

      # Set the value equal to the stdout of the command, plus
      # run through a regex - the first piece of match data is\
      # the value.
      def from_with_regex(cmd, *regex_list)
        regex_list.flatten.each do |regex|
          _status, stdout, _stderr = run_command(command: cmd)
          return "" if stdout.nil? || stdout.empty?
          stdout.chomp!.strip
          md = stdout.match(regex)
          return md[1]
        end
      end

      def set_attribute(name, *attrs, value)
        # Initialize the path in the @data Mash with new Mashes, if needed.
        # Will raise a TypeError if we hit a subattribute that is not a
        # Hash, Mash, or Array.
        keys = [name] + attrs
        attribute = keys[0..-2].inject(@data) do |atts, key|
          atts[key] ||= Mash.new
          atts[key]
        end

        # Set the subattribute to the value.
        attr_name = attrs.empty? ? name : attrs[-1]
        attribute[attr_name] = value
        @data[name]
      end

      def get_attribute(name, *keys)
        safe_get_attribute(name, *keys)
      end

      def hint?(name)
        Ohai::Hints.hint?(name)
      end

      # emulates the old plugin loading behavior
      def safe_run
        run
      rescue Ohai::Exceptions::Error => e
        @failed = true
        raise e
      rescue => e
        @failed = true
        logger.trace("Plugin #{name} threw #{e.inspect}")
        e.backtrace.each { |line| logger.trace( line ) }
      end

      def method_missing(name, *args)
        return get_attribute(name) if args.length == 0

        set_attribute(name, *args)
      end

      private

      def safe_get_attribute(*keys)
        keys.inject(@data) do |attrs, key|
          unless attrs.nil? || attrs.is_a?(Array) || attrs.is_a?(Hash)
            raise TypeError.new("Expected Hash but got #{attrs.class}.")
          end
          attrs[key]
        end
      rescue NoMethodError
        # NoMethodError occurs when trying to access a key on nil
        nil
      end
    end
  end
end
