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

require_plugin 'kernel'
require_plugin 'lsb'

if kernel == "SunOS"
  os "Solaris"
elsif kernel == "Linux"
  if lsb_dist_id == "Ubuntu"
    os "Ubuntu"
    os_release from_with_regex('cat /etc/issue', /Ubuntu (\d+.\d+)/)
  elsif FileTest.exists?("/etc/debian_version")
    os "Debian"
    os_release from_with_regex('cat /proc/version', /\(Debian (\d+.\d+).\d+-\d+\)/)    
  elsif FileTest.exists?("/etc/gentoo-release")
    os "Gentoo"
  elsif FileTest.exists?("/etc/fedora-release")
    os "Fedora"
    os_release from_with_regex("cat /etc/fedora-release", /\((Rawhide)\)/, /release (\d+)/)
  elsif FileTest.exists?("/etc/mandriva-release")
    os "Mandriva"
  elsif FileTest.exists?("/etc/mandrake-release")
    os "Mandrake"
  elsif FileTest.exists?("/etc/redhat-release")
    txt = File.read("/etc/redhat-release")
    if txt =~ /centos/i
      os "CentOS"
      os_release from_with_regex("rpm -q centos-release", /release-(\d+)/)
    else
      os "RedHat"
      if txt =~ /\(Rawhide\)$/
        os_release "Rawhide"
      elsif txt =~ /release (\d+)/
        os_release $1
      end
    end
  elsif FileTest.exists?("/etc/SuSE-release")
    os "SuSE"
  end
else
  os kernel
  os_release kernel_release
end
