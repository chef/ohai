# frozen_string_literal: true
#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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
    return nil unless file_exist?(file)

    file_read(file).split.inject({}) do |map, line|
      key, value = line.split("=")
      map[key] = value.gsub(/\A"|"\Z/, "") if value
      map
    end
  end

  #
  # Cached /etc/os-release info Hash. Also has logic for Cisco Nexus
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
        if cisco_release_info && file_exist?(cisco_release_info)
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
    file_exist?("/etc/os-release") && os_release_info["CISCO_RELEASE_INFO"]
  end

  #
  # Determines the platform version for F5 Big-IP systems
  #
  # @deprecated
  #
  # @returns [String] bigip Linux version from /etc/f5-release
  #
  def bigip_version
    release_contents = file_read("/etc/f5-release")
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

    # the platform mappings between the 'ID' field in /etc/os-release and the value
    # ohai uses. If you're adding a new platform here and you want to change the name
    # you'll want to add it here and then add a spec for the platform_id_remap method
    {
      "alinux" => "alibabalinux",
      "amzn" => "amazon",
      "archarm" => "arch",
      "cumulus-linux" => "cumulus",
      "ol" => "oracle",
      "opensuse-leap" => "opensuseleap",
      "rhel" => "redhat",
      "sles_sap" => "suse",
      "sles" => "suse",
      "xenenterprise" => "xenserver",
    }[id.downcase] || id.downcase
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
    when /ubuntu/, /debian/, /linuxmint/, /raspbian/, /cumulus/, /kali/, /pop/
      # apt-get+dpkg almost certainly goes here
      "debian"
    when /centos/, /redhat/, /oracle/, /almalinux/, /rocky/, /scientific/, /enterpriseenterprise/, /xenserver/, /xcp-ng/, /cloudlinux/, /alibabalinux/, /sangoma/, /clearos/, /parallels/, /ibm_powerkvm/, /nexus_centos/, /bigip/, /virtuozzo/ # Note that 'enterpriseenterprise' is oracle's LSB "distributor ID"
      # NOTE: "rhel" should be reserved exclusively for recompiled rhel versions that are nearly perfectly compatible down to the platform_version.
      # The operating systems that are "rhel" should all be as compatible as rhel7 = centos7 = oracle7 = scientific7 (98%-ish core RPM version compatibility
      # and the version numbers MUST track the upstream). The appropriate EPEL version repo should work nearly perfectly.  Some variation like the
      # oracle kernel version differences and tuning and extra packages are clearly acceptable. Almost certainly some distros above (xenserver?)
      # should not be in this list. Please use fedora, below, instead. Also note that this is the only platform_family with this strict of a rule,
      # see the example of the debian platform family for how the rest of the platform_family designations should be used.
      #
      # TODO: when XCP-NG 7.4 support ends we can remove the xcp-ng match. 7.5+ reports as xenenterprise which we remap to xenserver
      "rhel"
    when /amazon/
      "amazon"
    when /suse/, /sles/, /opensuseleap/, /opensuse/, /sled/
      "suse"
    when /fedora/, /arista_eos/
      # In the broadest sense:  RPM-based, fedora-derived distributions which are not strictly re-compiled RHEL (if it uses RPMs, and smells more like redhat and less like
      # SuSE it probably goes here).
      "fedora"
    when /nexus/, /ios_xr/
      "wrlinux"
    when /gentoo/
      "gentoo"
    when /arch/, /manjaro/
      "arch"
    when /exherbo/
      "exherbo"
    when /alpine/
      "alpine"
    when /clearlinux/
      "clearlinux"
    when /mangeia/
      "mandriva"
    when /slackware/
      "slackware"
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
    if file_exist?("/etc/oracle-release")
      contents = file_read("/etc/oracle-release").chomp
      platform "oracle"
      platform_version get_redhatish_version(contents)
    elsif file_exist?("/etc/enterprise-release")
      contents = file_read("/etc/enterprise-release").chomp
      platform "oracle"
      platform_version get_redhatish_version(contents)
    elsif file_exist?("/etc/f5-release")
      platform "bigip"
      platform_version bigip_version
    elsif file_exist?("/etc/debian_version")
      # Ubuntu and Debian both have /etc/debian_version
      # Ubuntu should always have a working lsb, debian does not by default
      if /Ubuntu/i.match?(lsb[:id])
        platform "ubuntu"
        platform_version lsb[:release]
      else
        platform "debian"
        platform_version file_read("/etc/debian_version").chomp
      end
    elsif file_exist?("/etc/parallels-release")
      contents = file_read("/etc/parallels-release").chomp
      platform get_redhatish_platform(contents)
      platform_version contents.match(/(\d\.\d\.\d)/)[0]
    elsif file_exist?("/etc/Eos-release")
      platform "arista_eos"
      platform_version file_read("/etc/Eos-release").strip.split[-1]
    elsif file_exist?("/etc/redhat-release")
      contents = file_read("/etc/redhat-release").chomp
      platform get_redhatish_platform(contents)
      platform_version get_redhatish_version(contents)
    elsif file_exist?("/etc/system-release")
      contents = file_read("/etc/system-release").chomp
      platform get_redhatish_platform(contents)
      platform_version get_redhatish_version(contents)
    elsif file_exist?("/etc/SuSE-release")
      suse_release = file_read("/etc/SuSE-release")
      suse_version = suse_release.scan(/VERSION = (\d+)\nPATCHLEVEL = (\d+)/).flatten.join(".")
      suse_version = suse_release[/VERSION = ([\d\.]{2,})/, 1] if suse_version == ""
      platform_version suse_version
      if /^openSUSE/.match?(suse_release)
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
    elsif file_exist?("/etc/slackware-version")
      platform "slackware"
      platform_version file_read("/etc/slackware-version").scan(/(\d+|\.+)/).join
    elsif file_exist?("/etc/exherbo-release")
      platform "exherbo"
      # no way to determine platform_version in a rolling release distribution
      # kernel release will be used - ex. 3.13
      platform_version shell_out("/bin/uname -r").stdout.strip
    elsif file_exist?("/usr/lib/os-release")
      contents = file_read("/usr/lib/os-release")
      if /clear-linux-os/.match?(contents) # Clear Linux https://clearlinux.org/
        platform "clearlinux"
        platform_version contents[/VERSION_ID=(\d+)/, 1]
      end
    elsif /RedHat/i.match?(lsb[:id])
      platform "redhat"
      platform_version lsb[:release]
    elsif /Amazon/i.match?(lsb[:id])
      platform "amazon"
      platform_version lsb[:release]
    elsif /ScientificSL/i.match?(lsb[:id])
      platform "scientific"
      platform_version lsb[:release]
    elsif /XenServer/i.match?(lsb[:id])
      platform "xenserver"
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
      get_redhatish_version(file_read("/etc/redhat-release").chomp)
    # debian testing and unstable don't have VERSION_ID set
    elsif os_release_info["ID"] == "debian"
      os_release_info["VERSION_ID"] || file_read("/etc/debian_version").chomp
    else
      os_release_info["VERSION_ID"] || shell_out("/bin/uname -r").stdout.strip
    end
  end

  collect_data(:linux) do
    if file_exist?("/etc/os-release")
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
