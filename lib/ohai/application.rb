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

require "chef-config/path_helper"
require "chef-config/workstation_config_loader"
require "info_getter"
require "info_getter/log"
require "mixlib/cli"

class info_getter::Application
  include Mixlib::CLI

  option :config_file,
    :short       => "-c CONFIG",
    :long        => "--config CONFIG",
    :description => "A configuration file to use",
    :proc => lambda { |path| File.expand_path(path, Dir.pwd) }

  option :directory,
    :short       => "-d DIRECTORY",
    :long        => "--directory DIRECTORY",
    :description => "A directory to add to the info_getter plugin search path",
    :proc        => lambda { |path| info_getter::Config.platform_specific_path(path) }

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
    :description  => "Show info_getter version",
    :boolean      => true,
    :proc         => lambda { |v| puts "info_getter: #{::info_getter::VERSION}" },
    :exit         => 0

  def initialize
    super

    # Always switch to a readable directory. Keeps subsequent Dir.chdir() {}
    # from failing due to permissions when launched as a less privileged user.
    Dir.chdir("/")
  end

  def run
    configure_info_getter
    run_application
  end

  def configure_info_getter
    @attributes = parse_options
    @attributes = nil if @attributes.empty?

    load_workstation_config
  end

  def run_application
    info_getter = info_getter::System.new(config)
    info_getter.all_plugins(@attributes)

    if @attributes
      @attributes.each do |a|
        puts info_getter.attributes_print(a)
      end
    else
      puts info_getter.json_pretty_print
    end
  end

  class << self
    # Log a fatal error message to both STDERR and the Logger, exit the application
    def fatal!(msg, err = -1)
      STDERR.puts("FATAL: #{msg}")
      info_getter::Log.fatal(msg)
      Process.exit err
    end

    def exit!(msg, err = -1)
      info_getter::Log.debug(msg)
      Process.exit err
    end
  end

  private

  def load_workstation_config
    config_loader = ChefConfig::WorkstationConfigLoader.new(
      config[:config_file], info_getter::Log
    )
    begin
      config_loader.load
    rescue ChefConfig::ConfigurationError => config_error
      info_getter::Application.fatal!(config_error.message)
    end
  end
end
