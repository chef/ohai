#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

def get_redhatish_platform(contents)
  contents[/^Red Hat/i] ? "redhat" : contents[/(\w+)/i, 1].downcase
end

def get_redhatish_version(contents)
  contents[/Rawhide/i] ? contents[/((\d+) \(Rawhide\))/i, 1].downcase : contents[/release ([\d\.]+)/, 1]
end

provides "platform", "platform_version", "platform_family"

require_plugin 'linux::lsb'

# platform [ and platform_version ? ] should be lower case to avoid dealing with RedHat/Redhat/redhat matching 
if File.exists?("/etc/oracle-release")
  contents = File.read("/etc/oracle-release").chomp
  platform "oracle"
  platform_version get_redhatish_version(contents)
elsif File.exists?("/etc/enterprise-release")
  contents = File.read("/etc/enterprise-release").chomp
  platform "oracle"
  platform_version get_redhatish_version(contents)
elsif File.exists?("/etc/debian_version")
  # Ubuntu, GCEL and Debian both have /etc/debian_version
  # Ubuntu, GCEL should always have a working lsb, debian does not by default
  if lsb[:id] =~ /Ubuntu/i
    platform "ubuntu"
    platform_version lsb[:release]
  elsif lsb[:id] =~ /gcel/i
    platform "gcel"
    platform_version lsb[:release]
  elsif lsb[:id] =~ /LinuxMint/i
    platform "linuxmint"
    platform_version lsb[:release]
  else 
    if File.exists?("/usr/bin/raspi-config")
      platform "raspbian"
    else
      platform "debian"
    end
    platform_version File.read("/etc/debian_version").chomp
  end
elsif File.exists?("/etc/redhat-release")
  contents = File.read("/etc/redhat-release").chomp
  platform get_redhatish_platform(contents)
  platform_version get_redhatish_version(contents)
elsif File.exists?("/etc/system-release")
  contents = File.read("/etc/system-release").chomp
  platform get_redhatish_platform(contents)
  platform_version get_redhatish_version(contents)
elsif File.exists?('/etc/gentoo-release')
  platform "gentoo"
  platform_version File.read('/etc/gentoo-release').scan(/(\d+|\.+)/).join
elsif File.exists?('/etc/SuSE-release')
  platform "suse"
  suse_release = File.read("/etc/SuSE-release")
  platform_version suse_release.scan(/VERSION = (\d+)\nPATCHLEVEL = (\d+)/).flatten.join(".")
  platform_version suse_release.scan(/VERSION = ([\d\.]{2,})/).flatten.join(".") if platform_version == ""
elsif File.exists?('/etc/slackware-version')
  platform "slackware"
  platform_version File.read("/etc/slackware-version").scan(/(\d+|\.+)/).join
elsif File.exists?('/etc/arch-release')
  platform "arch"
  # no way to determine platform_version in a rolling release distribution
  # kernel release will be used - ex. 2.6.32-ARCH
elsif lsb[:id] =~ /RedHat/i
  platform "redhat"
  platform_version lsb[:release]
elsif lsb[:id] =~ /Amazon/i
  platform "amazon"
  platform_version lsb[:release]
elsif lsb[:id] =~ /ScientificSL/i
  platform "scientific"
  platform_version lsb[:release]
elsif lsb[:id] =~ /XenServer/i
  platform "xenserver"
  platform_version lsb[:release]
elsif lsb[:id] # LSB can provide odd data that changes between releases, so we currently fall back on it rather than dealing with its subtleties 
  platform lsb[:id].downcase
  platform_version lsb[:release]
end


case platform
  when /debian/, /ubuntu/, /linuxmint/, /raspbian/, /gcel/
    platform_family "debian"
  when /fedora/
    platform_family "fedora"
  when /oracle/, /centos/, /redhat/, /scientific/, /enterpriseenterprise/, /amazon/, /xenserver/ # Note that 'enterpriseenterprise' is oracle's LSB "distributor ID"
    platform_family "rhel"
  when /suse/
    platform_family "suse"
  when /gentoo/
    platform_family "gentoo"
  when /slackware/
    platform_family "slackware"
  when /arch/ 
    platform_family "arch" 
end
