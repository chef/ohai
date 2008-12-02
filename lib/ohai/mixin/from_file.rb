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

module Ohai
  module Mixin
    module FromFile
    
      # Loads a given ruby file, and runs instance_eval against it in the context of the current 
      # object.  
      #
      # Raises an IOError if the file cannot be found, or is not readable.
      def from_file(filename)
        if File.exists?(filename) && File.readable?(filename)
          self.instance_eval(IO.read(filename), filename, 1)
        else
          raise IOError, "Cannot open or read #{filename}!"
        end
      end
    end
  end
end
