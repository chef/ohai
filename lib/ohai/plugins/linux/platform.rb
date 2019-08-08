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

  # the platform mappings between the 'ID' field in /etc/os-release and the value
  # ohai uses. If you're adding a new platform here and you want to change the name
  # you'll want to add it here and then add a spec for the platform_id_remap method
  PLATFORM_MAPPINGS ||= {
      "rhel" => "redhat",
      "amzn" => "amazon",
      "ol" => "oracle",
      "sles" => "suse",
      "sles_sap" => "suse",
      "opensuse-leap" => "opensuseleap",
      "xenenterprise" => "xenserver",
      "cumulus-linux" => "cumulus",
      "archarm" => "arch",
    }.freeze

  # @deprecated
  def get_redhatish_platform(contents)
    contents[/^Red Hat/i] ? "redhat" : contents[/(\w+)/i, 1].downcase
  end

  # See https://rubular.com/r/78c1yXYa7zDhdV for example matches
  #
  # @param contents [String] the contents of /etc/redhat-release
  #
  # @returns [String] the version string
  #
  def get_redhatish_version(contents)
    contents[/(release)? ([\d\.]+)/, 2]
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
  # Determines the platform version for F5 Big-IP systems
  #
  # @deprecated
  #
  # @returns [String] bigip Linux version from /etc/f5-release
  #
  def bigip_version
    release_contents = File.read("/etc/f5-release")
    release_contents.match(/BIG-IP release (\S*)/)[1] # http://rubular.com/r/O8nlrBVqSb
  rescue NoMethodError, Errno::ENOENT, Errno::EACCES # rescue regex failure, file missing, or permission denied
    logger.warn("Detected F5 Big-IP, but /etc/f5-release could not be parsed to determine platform_version")
    nil
  end

  # our platform names don't match os-release. given a time machine they would but ohai
  # came before the os-release file. This method remaps the os-release names to
  # the ohai names
  #
  # @param id [String] the platform ID from /etc/os-release
  #
  # @returns [String] the platform name to use in Ohai
  #
  def platform_id_remap(id)
    # this catches the centos guest shell in the nexus switch which identifies itself as centos
    return "nexus_centos" if id == "centos" && os_release_file_is_cisco?

    # remap based on the hash of platforms
    PLATFORM_MAPPINGS[id] || id
  end

  #
  # Determines the platform_family based on the platform
  #
  # @param plat [String] the platform name
  #
  # @returns [String] platform_family value
  #
  def platform_family_from_platform(plat)
    case plat
    when /debian/, /ubuntu/, /linuxmint/, /raspbian/, /cumulus/, /kali/
      # apt-get+dpkg almost certainly goes here
      "debian"
    when /oracle/, /centos/, /redhat/, /scientific/, /enterpriseenterprise/, /xcp/, /xenserver/, /cloudlinux/, /ibm_powerkvm/, /parallels/, /nexus_centos/, /clearos/, /bigip/ # Note that 'enterpriseenterprise' is oracle's LSB "distributor ID"
      # NOTE: "rhel" should be reserved exclusively for recompiled rhel versions that are nearly perfectly compatible down to the platform_version.
      # The operating systems that are "rhel" should all be as compatible as rhel7 = centos7 = oracle7 = scientific7 (98%-ish core RPM version compatibility
      # and the version numbers MUST track the upstream). The appropriate EPEL version repo should work nearly perfectly.  Some variation like the
      # oracle kernel version differences and tuning and extra packages are clearly acceptable.  Almost certainly some distros above (xenserver?)
      # should not be in this list.  Please use fedora, below, instead.  Also note that this is the only platform_family with this strict of a rule,
      # see the example of the debian platform family for how the rest of the platform_family designations should be used.
      "rhel"
    when /amazon/
      "amazon"
    when /suse/, /sles/, /opensuse/, /opensuseleap/, /sled/
      "suse"
    when /fedora/, /pidora/, /arista_eos/
      # In the broadest sense:  RPM-based, fedora-derived distributions which are not strictly re-compiled RHEL (if it uses RPMs, and smells more like redhat and less like
      # SuSE it probably goes here).
      "fedora"
    when /nexus/, /ios_xr/
      "wrlinux"
    when /gentoo/
      "gentoo"
    when /slackware/
      "slackware"
    when /arch/, /manjaro/, /antergos/
      "arch"
    when /exherbo/
      "exherbo"
    when /alpine/
      "alpine"
    when /clearlinux/
      "clearlinux"
    when /mangeia/
      "mandriva"
    end
  end

  # modern linux distros include a /etc/os-release file, which we now rely on for
  # OS detection. For older distros that do not include that file we fall back to
  # our pre-Ohai 15 detection logic, which is the method below. No new functionality
  # should be added to this logic.
  #
  # @deprecated
  def legacy_platform_detection
    # platform [ and platform_version ? ] should be lower case to avoid dealing with RedHat/Redhat/redhat matching
    if File.exist?("/etc/oracle-release")
      contents = File.read("/etc/oracle-release").chomp
      platform "oracle"
      platform_version get_redhatish_version(contents)
    elsif File.exist?("/etc/enterprise-release")
      contents = File.read("/etc/enterprise-release").chomp
      platform "oracle"
      platform_version get_redhatish_version(contents)
    elsif File.exist?("/etc/f5-release")
      platform "bigip"
      platform_version bigip_version
    elsif File.exist?("/etc/debian_version")
      # Ubuntu and Debian both have /etc/debian_version
      # Ubuntu should always have a working lsb, debian does not by default
      if lsb[:id] =~ /Ubuntu/i
        platform "ubuntu"
        platform_version lsb[:release]
      else
        platform "debian"
        platform_version File.read("/etc/debian_version").chomp
      end
    elsif File.exist?("/etc/parallels-release")
      contents = File.read("/etc/parallels-release").chomp
      platform get_redhatish_platform(contents)
      platform_version contents.match(/(\d\.\d\.\d)/)[0]
    elsif File.exist?("/etc/Eos-release")
      platform "arista_eos"
      platform_version File.read("/etc/Eos-release").strip.split[-1]
    elsif File.exist?("/etc/redhat-release")
      contents = File.read("/etc/redhat-release").chomp
      platform get_redhatish_platform(contents)
      platform_version get_redhatish_version(contents)
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
    elsif os_release_file_is_cisco?
      raise "unknown Cisco /etc/os-release or /etc/cisco-release ID_LIKE field" if
        os_release_info["ID_LIKE"].nil? || !os_release_info["ID_LIKE"].include?("wrlinux")

      case os_release_info["ID"]
      when "nexus"
        platform "nexus"
      when "ios_xr"
        platform "ios_xr"
      else
        raise "unknown Cisco /etc/os-release or /etc/cisco-release ID field"
      end

      platform_version os_release_info["VERSION"]
    elsif File.exist?("/etc/slackware-version")
      platform "slackware"
      platform_version File.read("/etc/slackware-version").scan(/(\d+|\.+)/).join
    elsif File.exist?("/etc/exherbo-release")
      platform "exherbo"
      # no way to determine platform_version in a rolling release distribution
      # kernel release will be used - ex. 3.13
      platform_version shell_out("/bin/uname -r").stdout.strip
    elsif File.exist?("/usr/lib/os-release")
      contents = File.read("/usr/lib/os-release")
      if /clear-linux-os/ =~ contents # Clear Linux https://clearlinux.org/
        platform "clearlinux"
        platform_version contents[/VERSION_ID=(\d+)/, 1]
      end
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
    elsif lsb[:id] =~ /XCP/i
      platform "xcp"
      platform_version lsb[:release]
    elsif lsb[:id] # LSB can provide odd data that changes between releases, so we currently fall back on it rather than dealing with its subtleties
      platform lsb[:id].downcase
      platform_version lsb[:release]
    end
  end

  # Grab the version from the VERSION_ID field and use the kernel release if that's not
  # available. It should be there for everything, but rolling releases like arch / gentoo
  # where we've traditionally used the kernel as the version
  # @return String the OS version
  def determine_os_version
    # centos only includes the major version in os-release for some reason
    if os_release_info["ID"] == "centos"
      get_redhatish_version(File.read("/etc/redhat-release").chomp)
    else
      os_release_info["VERSION_ID"] || shell_out("/bin/uname -r").stdout.strip
    end
  end

  collect_data(:linux) do
    if ::File.exist?("/etc/os-release")
      logger.trace("Plugin platform: Using /etc/os-release for platform detection")

      # fixup os-release names to ohai platform names
      platform platform_id_remap(os_release_info["ID"])

      platform_version determine_os_version
    else # we're on an old Linux distro
      legacy_platform_detection
    end

    # unless we set it in a specific way with the platform logic above set based on platform data
    platform_family platform_family_from_platform(platform) if platform_family.nil?
  end
end
