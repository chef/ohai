#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

Ohai.plugin(:Platform) do
  provides "platform", "platform_version", "platform_family"
  depends "lsb"

  def get_redhatish_platform(contents)
    contents[/^Red Hat/i] ? "redhat" : contents[/(\w+)/i, 1].downcase
  end

  def get_redhatish_version(contents)
    contents[/Rawhide/i] ? contents[/((\d+) \(Rawhide\))/i, 1].downcase : contents[/release ([\d\.]+)/, 1]
  end

  #
  # Reads an os-release-info file and parse it into a hash
  #
  # @param file [String] the filename to read (e.g. '/etc/os-release')
  #
  # @returns [Hash] the file parsed into a Hash or nil
  #
  def read_os_release_info(file)
    return nil unless File.exist?(file)
    File.read(file).split.inject({}) do |map, line|
      key, value = line.split('=')
      map[key] = value.gsub(/\A"|"\Z/, '') if value
      map
    end
  end

  #
  # Cached /etc/os-release info Hash.  Also has logic for Cisco Nexus
  # switches that pulls the chained CISCO_RELEASE_INFO file into the Hash (other
  # distros can also reuse this method safely).
  #
  # @returns [Hash] the canonical, cached Hash of /etc/os-release info or nil
  #
  def os_release_info
    @os_release_info ||=
      begin
        os_release_info = read_os_release_info('/etc/os-release')
        cisco_release_info = os_release_info['CISCO_RELEASE_INFO'] if os_release_info
        if cisco_release_info && File.exist?(cisco_release_info)
          os_release_info.merge!(read_os_release_info(cisco_release_info))
        end
        os_release_info
      end
  end

  #
  # If /etc/os-release indicates we are Cisco based
  #
  # @returns [Boolean] if we are Cisco according to /etc/os-release
  #
  def os_release_file_is_cisco?
    File.exist?('/etc/os-release') && os_release_info['CISCO_RELEASE_INFO']
  end

  collect_data(:linux) do
    # platform [ and platform_version ? ] should be lower case to avoid dealing with RedHat/Redhat/redhat matching
    if File.exist?("/etc/oracle-release")
      contents = File.read("/etc/oracle-release").chomp
      platform "oracle"
      platform_version get_redhatish_version(contents)
    elsif File.exist?("/etc/enterprise-release")
      contents = File.read("/etc/enterprise-release").chomp
      platform "oracle"
      platform_version get_redhatish_version(contents)
    elsif File.exist?("/etc/debian_version")
      # Ubuntu and Debian both have /etc/debian_version
      # Ubuntu should always have a working lsb, debian does not by default
      if lsb[:id] =~ /Ubuntu/i
        platform "ubuntu"
        platform_version lsb[:release]
      elsif lsb[:id] =~ /LinuxMint/i
        platform "linuxmint"
        platform_version lsb[:release]
      else
        if File.exist?("/usr/bin/raspi-config")
          platform "raspbian"
        else
          platform "debian"
        end
        platform_version File.read("/etc/debian_version").chomp
      end
    elsif File.exist?("/etc/parallels-release")
      contents = File.read("/etc/parallels-release").chomp
      platform get_redhatish_platform(contents)
      platform_version contents.match(/(\d\.\d\.\d)/)[0]
    elsif File.exist?("/etc/redhat-release")
      if os_release_file_is_cisco? # Cisco guestshell
        platform 'nexus_centos'
        platform_version os_release_info['VERSION']
      else
        contents = File.read("/etc/redhat-release").chomp
        platform get_redhatish_platform(contents)
        platform_version get_redhatish_version(contents)
      end
    elsif File.exist?("/etc/system-release")
      contents = File.read("/etc/system-release").chomp
      platform get_redhatish_platform(contents)
      platform_version get_redhatish_version(contents)
    elsif File.exist?('/etc/gentoo-release')
      platform "gentoo"
      platform_version File.read('/etc/gentoo-release').scan(/(\d+|\.+)/).join
    elsif File.exist?('/etc/SuSE-release')
      suse_release = File.read("/etc/SuSE-release")
      suse_version = suse_release.scan(/VERSION = (\d+)\nPATCHLEVEL = (\d+)/).flatten.join(".")
      suse_version = suse_release[/VERSION = ([\d\.]{2,})/, 1] if suse_version == ""
      platform_version suse_version
      if suse_release =~ /^openSUSE/
        platform "opensuse"
      else
        platform "suse"
      end
    elsif File.exist?('/etc/slackware-version')
      platform "slackware"
      platform_version File.read("/etc/slackware-version").scan(/(\d+|\.+)/).join
    elsif File.exist?('/etc/arch-release')
      platform "arch"
      # no way to determine platform_version in a rolling release distribution
      # kernel release will be used - ex. 2.6.32-ARCH
      platform_version `uname -r`.strip
    elsif File.exist?('/etc/exherbo-release')
      platform "exherbo"
      # no way to determine platform_version in a rolling release distribution
      # kernel release will be used - ex. 3.13
      platform_version `uname -r`.strip
    elsif os_release_file_is_cisco?
      raise 'unknown Cisco /etc/os-release or /etc/cisco-release ID_LIKE field' if
        os_release_info['ID_LIKE'].nil? || ! os_release_info['ID_LIKE'].include?('wrlinux')

      case os_release_info['ID']
      when 'nexus'
        platform 'nexus'
      when 'ios_xr'
        platform 'ios_xr'
      else
        raise 'unknown Cisco /etc/os-release or /etc/cisco-release ID field'
      end

      platform_family 'wrlinux'
      platform_version os_release_info['VERSION']
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
    when /debian/, /ubuntu/, /linuxmint/, /raspbian/
      platform_family "debian"
    when /fedora/, /pidora/
      platform_family "fedora"
    when /oracle/, /centos/, /redhat/, /scientific/, /enterpriseenterprise/, /amazon/, /xenserver/, /cloudlinux/, /ibm_powerkvm/, /parallels/, /nexus_centos/ # Note that 'enterpriseenterprise' is oracle's LSB "distributor ID"
      platform_family "rhel"
    when /suse/
      platform_family "suse"
    when /gentoo/
      platform_family "gentoo"
    when /slackware/
      platform_family "slackware"
    when /arch/
      platform_family "arch"
    when /exherbo/
      platform_family "exherbo"
    end
  end
end
