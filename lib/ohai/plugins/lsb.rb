#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
# License:: GNU GPL, Version 3
#
# Copyright (C) 2008, OpsCode Inc. 
#
# Portions of this file benifited greatly from Facter 
# (http://reductivelabs.com/projects/facter/)
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

popen4("lsb_release -a") do |pid, stdin, stdout, stderr|
  stdin.close
  stdout.each do |line|
    case line
    when /^Distributor ID:\t(.*)$/
      lsb_dist_id $1
    when /^LSB Version:\t(.*)$/
      lsb_release $1
    when /^Release:\t(.*)$/
      lsb_dist_release $1
    when /^Description:\t(.*)$/
      lsb_dist_description $1
    when /^Codename:\t(.*)$/
      lsb_dist_codename $1
    end
  end
end
