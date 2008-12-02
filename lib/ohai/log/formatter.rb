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

require 'logger'
require 'time'

module Ohai
  class Log
    class Formatter < Logger::Formatter
      @@show_time = true
      
      def self.show_time=(show=false)
        @@show_time = show
      end
      
      # Prints a log message as '[time] severity: message' if Ohai::Log::Formatter.show_time == true.
      # Otherwise, doesn't print the time.
      def call(severity, time, progname, msg)
        if @@show_time
          sprintf("[%s] %s: %s\n", time.rfc2822(), severity, msg2str(msg))
        else
          sprintf("%s: %s\n", severity, msg2str(msg))
        end
      end
      
      # Converts some argument to a Logger.severity() call to a string.  Regular strings pass through like
      # normal, Exceptions get formatted as "message (class)\nbacktrace", and other random stuff gets 
      # put through "object.inspect"
      def msg2str(msg)
        case msg
        when ::String
          msg
        when ::Exception
          "#{ msg.message } (#{ msg.class })\n" <<
            (msg.backtrace || []).join("\n")
        else
          msg.inspect
        end
      end
    end
  end
end