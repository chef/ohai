#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2015-2017, Chef Software Inc.
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
      key, value = line.split("=")
      map[key] = value.gsub(/\A"|"\Z/, "") if value
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
        os_release_info = read_os_release_info("/etc/os-release")
        cisco_release_info = os_release_info["CISCO_RELEASE_INFO"] if os_release_info
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
    File.exist?("/etc/os-release") && os_release_info["CISCO_RELEASE_INFO"]
  end

  #
  # Determines the platform version for Cumulus Linux systems
  #
  # @returns [String] cumulus Linux version from /etc/cumulus/etc.replace/os-release
  #
  def cumulus_version
    release_contents = File.read("/etc/cumulus/etc.replace/os-release")
    release_contents.match(/VERSION_ID=(.*)/)[1]
  rescue NoMethodError, Errno::ENOENT, Errno::EACCES # rescue regex failure, file missing, or permission denied
    Ohai::Log.warn("Detected Cumulus Linux, but /etc/cumulus/etc/replace/os-release could not be parsed to determine platform_version")
    nil
  end

  #
  # Determines the platform version for Debian based systems
  #
  # @returns [String] version of the platform
  #
  def debian_platform_version
    if platform == "cumulus"
      cumulus_version
    else # not cumulus
      File.read("/etc/debian_version").chomp
    end
  end

  #
  # Determines the platform_family based on the platform
  #
  # @returns [String] platform_family value
  #
  def determine_platform_family
    case platform
    when /debian/, /ubuntu/, /linuxmint/, /raspbian/, /cumulus/
      "debian"
    when /oracle/, /centos/, /redhat/, /scientific/, /enterpriseenterprise/, /xenserver/, /cloudlinux/, /ibm_powerkvm/, /parallels/, /nexus_centos/ # Note that 'enterpriseenterprise' is oracle's LSB "distributor ID"
      "rhel"
    when /amazon/
      "amazon"
    when /suse/
      "suse"
    when /fedora/, /pidora/, /arista_eos/
      "fedora"
    when /nexus/, /ios_xr/
      "wrlinux"
    when /gentoo/
      "gentoo"
    when /slackware/
      "slackware"
    when /arch/
      "arch"
    when /exherbo/
      "exherbo"
    when /alpine/
      "alpine"
    end
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
        elsif Dir.exist?("/etc/cumulus")
          platform "cumulus"
        else
          platform "debian"
        end
        platform_version debian_platform_version
      end
    elsif File.exist?("/etc/parallels-release")
      contents = File.read("/etc/parallels-release").chomp
      platform get_redhatish_platform(contents)
      platform_version contents.match(/(\d\.\d\.\d)/)[0]
    elsif File.exist?("/etc/redhat-release")
      if os_release_file_is_cisco? # Cisco guestshell
        platform "nexus_centos"
        platform_version os_release_info["VERSION"]
      else
        contents = File.read("/etc/redhat-release").chomp
        platform get_redhatish_platform(contents)
        platform_version get_redhatish_version(contents)
      end
    elsif File.exist?("/etc/system-release")
      contents = File.read("/etc/system-release").chomp
      platform get_redhatish_platform(contents)
      platform_version get_redhatish_version(contents)
    elsif File.exist?("/etc/SuSE-release")
      suse_release = File.read("/etc/SuSE-release")
      suse_version = suse_release.scan(/VERSION = (\d+)\nPATCHLEVEL = (\d+)/).flatten.join(".")
      suse_version = suse_release[/VERSION = ([\d\.]{2,})/, 1] if suse_version == ""
      platform_version suse_version
      if suse_release =~ /^openSUSE/
        # opensuse releases >= 42 are openSUSE Leap
        if platform_version.to_i < 42
          platform "opensuse"
        else
          platform "opensuseleap"
        end
      else
        platform "suse"
      end
    elsif File.exist?("/etc/Eos-release")
      platform "arista_eos"
      platform_version File.read("/etc/Eos-release").strip.split[-1]
      platform_family "fedora"
    elsif os_release_file_is_cisco?
      raise "unknown Cisco /etc/os-release or /etc/cisco-release ID_LIKE field" if
        os_release_info["ID_LIKE"].nil? || ! os_release_info["ID_LIKE"].include?("wrlinux")

      case os_release_info["ID"]
      when "nexus"
        platform "nexus"
      when "ios_xr"
        platform "ios_xr"
      else
        raise "unknown Cisco /etc/os-release or /etc/cisco-release ID field"
      end

      platform_family "wrlinux"
      platform_version os_release_info["VERSION"]
    elsif File.exist?("/etc/gentoo-release")
      platform "gentoo"
      # the gentoo release version is the base version used to bootstrap
      # a node and doesn't have a lot of meaning in a rolling release distro
      # kernel release will be used - ex. 3.18.7-gentoo
      platform_version `uname -r`.strip
    elsif File.exist?("/etc/slackware-version")
      platform "slackware"
      platform_version File.read("/etc/slackware-version").scan(/(\d+|\.+)/).join
    elsif File.exist?("/etc/arch-release")
      platform "arch"
      # no way to determine platform_version in a rolling release distribution
      # kernel release will be used - ex. 2.6.32-ARCH
      platform_version `uname -r`.strip
    elsif File.exist?("/etc/exherbo-release")
      platform "exherbo"
      # no way to determine platform_version in a rolling release distribution
      # kernel release will be used - ex. 3.13
      platform_version `uname -r`.strip
    elsif File.exist?("/etc/alpine-release")
      platform "alpine"
      platform_version File.read("/etc/alpine-release").strip()
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

    platform_family determine_platform_family
  end
end
