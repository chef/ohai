# frozen_string_literal: true
#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
  # Cached os-release info Hash, from /etc/os-release or, as os-release(5)
  # says, /usr/lib/os-release when it is missing. Also has logic for Cisco Nexus
  # switches that pulls the chained CISCO_RELEASE_INFO file into the Hash (other
  # distros can also reuse this method safely).
  #
  # @returns [Hash] the canonical, cached Hash of os-release info; empty when
  #   neither file exists
  #
  def os_release_info
    @os_release_info ||=
      begin
        os_release_info = read_os_release_info("/etc/os-release") ||
          read_os_release_info("/usr/lib/os-release") || {}
        cisco_release_info = os_release_info["CISCO_RELEASE_INFO"]
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
      "clear-linux-os" => "clearlinux",
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
    when /centos/, /redhat/, /oracle/, /almalinux/, /rocky/, /scientific/, /xenserver/, /xcp-ng/, /cloudlinux/, /alibabalinux/, /sangoma/, /clearos/, /ibm_powerkvm/, /nexus_centos/, /virtuozzo/
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
    # suse matches opensuse, suse-* opensuse-*, etc. sle[sd\-_] intends to match sles, sled, sle-*, sle_*
    when /suse/, /sle[sd\-_]/
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
    logger.trace("Plugin platform: Using os-release for platform detection")

    # fixup os-release names to ohai platform names. Without an os-release
    # file or an ID in it (os-release(5) would default it to "linux"), report
    # generic-linux.
    platform platform_id_remap(os_release_info["ID"] || "generic-linux")
    platform_version determine_os_version

    # unless we set it in a specific way with the platform logic above set based on platform data
    platform_family platform_family_from_platform(platform) if platform_family.nil?
  end
end
