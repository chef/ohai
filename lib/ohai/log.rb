#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
# License:: GNU GPL, Version 3
#
# Copyright (C) 2008, OpsCode Inc. 
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'ohai/config'
require 'ohai/log/formatter'
require 'logger'

module Ohai
  class Log
  
    @logger = nil
    
    class << self
      attr_accessor :logger #:nodoc
      
      # Use Ohai::Logger.init when you want to set up the logger manually.  Arguments to this method
      # get passed directly to Logger.new, so check out the documentation for the standard Logger class
      # to understand what to do here.
      #
      # If this method is called with no arguments, it will log to STDOUT at the :info level.
      #
      # It also configures the Logger instance it creates to use the custom Ohai::Log::Formatter class.
      def init(*opts)
        if opts.length == 0
          @logger = Logger.new(STDOUT)
        else
          @logger = Logger.new(*opts)
        end
        @logger.formatter = Ohai::Log::Formatter.new()
        level(Ohai::Config.log_level)
      end
      
      # Sets the level for the Logger object by symbol.  Valid arguments are:
      #
      #  :debug
      #  :info
      #  :warn
      #  :error
      #  :fatal
      #
      # Throws an ArgumentError if you feed it a bogus log level.
      def level(loglevel)
        init() unless @logger
        case loglevel
        when :debug
          @logger.level = Logger::DEBUG
        when :info
          @logger.level = Logger::INFO
        when :warn
          @logger.level = Logger::WARN
        when :error
          @logger.level = Logger::ERROR
        when :fatal
          @logger.level = Logger::FATAL
        else
          raise ArgumentError, "Log level must be one of :debug, :info, :warn, :error, or :fatal"
        end
      end
      
      # Passes any other method calls on directly to the underlying Logger object created with init. If
      # this method gets hit before a call to Ohai::Logger.init has been made, it will call 
      # Ohai::Logger.init() with no arguments.
      def method_missing(method_symbol, *args)
        init() unless @logger
        if args.length > 0
          @logger.send(method_symbol, *args)
        else
          @logger.send(method_symbol)
        end
      end
      
    end # class << self
  end
end