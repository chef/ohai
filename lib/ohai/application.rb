#
# Author:: Mathieu Sauve-Frankel <msf@kisoku.net>
# Copyright:: Copyright (c) 2009 Mathieu Sauve-Frankel.
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

require 'ohai'
require 'ohai/log'
require 'mixlib/cli'

class Ohai::Application
  include Mixlib::CLI

  option :directory,
    :short       => "-d DIRECTORY",
    :long        => "--directory DIRECTORY",
    :description => "A directory to add to the Ohai search path"

  option :log_level,
    :short        => "-l LEVEL",
    :long         => "--log_level LEVEL",
    :description  => "Set the log level (debug, info, warn, error, fatal)",
    :proc         => lambda { |l| l.to_sym }

  option :log_location,
    :short        => "-L LOGLOCATION",
    :long         => "--logfile LOGLOCATION",
    :description  => "Set the log file location, defaults to STDOUT - recommended for daemonizing",
    :proc         => nil

  option :help,
    :short        => "-h",
    :long         => "--help",
    :description  => "Show this message",
    :on           => :tail,
    :boolean      => true,
    :show_options => true,
    :exit         => 0

  option :version,
    :short        => "-v",
    :long         => "--version",
    :description  => "Show Ohai version",
    :boolean      => true,
    :proc         => lambda {|v| puts "Ohai: #{::Ohai::VERSION}"},
    :exit         => 0

  def initialize
    super

    # Always switch to a readable directory. Keeps subsequent Dir.chdir() {}
    # from failing due to permissions when launched as a less privileged user.
    Dir.chdir("/")
  end

  def run
    configure_ohai
    configure_logging
    run_application
  end

  def configure_ohai
    @attributes = parse_options
    @attributes = nil if @attributes.empty?

    Ohai::Config.merge_deprecated_config
    Ohai.config.merge!(config)
    if Ohai.config[:directory]
      Ohai.config[:plugin_path] << Ohai.config[:directory]
    end
  end

  def configure_logging
    Ohai::Log.init(Ohai.config[:log_location])
    Ohai::Log.level = Ohai.config[:log_level]
  end

  def run_application
    ohai = Ohai::System.new
    ohai.all_plugins(@attributes)

    if @attributes
      @attributes.each do |a|
        puts ohai.attributes_print(a)
      end
    else
      puts ohai.json_pretty_print
    end
  end

  class << self
    # Log a fatal error message to both STDERR and the Logger, exit the application
    def fatal!(msg, err = -1)
      STDERR.puts("FATAL: #{msg}")
      Ohai::Log.fatal(msg)
      Process.exit err
    end

    def exit!(msg, err = -1)
      Ohai::Log.debug(msg)
      Process.exit err
    end
  end
end
