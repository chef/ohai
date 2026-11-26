# frozen_string_literal: true
#
# Author:: Aaron Kalin (<akalin@martinisoftware.com>)
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Ohai.plugin(:Linode) do
  require_relative "../mixin/smbios"
  require_relative "../mixin/http_helper"
  require_relative "../mixin/linode_metadata"
  include Ohai::Mixin::Smbios
  include Ohai::Mixin::HttpHelper
  include Ohai::Mixin::LinodeMetadata

  provides "linode"

  depends "domain"
  depends "network/interfaces"

  # Checks to see if the node is in the members.linode.com domain
  #
  # @return [Boolean]
  #
  def has_linode_domain?
    domain&.include?("linode")
  end

  # Checks for linode mirrors in the apt sources.list file
  #
  # @return [Boolean]
  #
  def has_linode_apt_repos?
    file_exist?("/etc/apt/sources.list") && file_read("/etc/apt/sources.list").include?("linode")
  end

  # Linode (Akamai Cloud) instances report "Linode" as the system vendor
  # and BIOS vendor. Modern images have neither a linode domain nor linode
  # apt mirrors, so this is the check that finds them.
  #
  # @return [Boolean]
  #
  def has_linode_dmi?
    smbios_value(:sys_vendor).to_s.match?(/linode|akamai/i) || smbios_value(:bios_vendor).to_s.match?(/linode/i)
  end

  # Identifies the linode cloud by preferring the hint, then
  #
  # @return [Boolean]
  #
  def looks_like_linode?
    hint?("linode") || has_linode_dmi? || has_linode_domain? || has_linode_apt_repos?
  end

  # Alters linode mash with new interface based on name parameter
  #
  # @param [Symbol] name Ohai name (e.g. :public_ip)
  # @param [Symbol] eth Interface name (e.g. :eth0)
  #
  def get_ip_address(name, eth)
    if ( eth_iface = network[:interfaces][eth] )
      eth_iface[:addresses].each do |key, info|
        linode[name] = key if info["family"] == "inet"
      end
    end
  end

  # Addresses in the metadata network document carry a prefix length
  # ("192.0.2.10/32", "2001:db8::1/128").
  #
  # @return [String, nil] the first address in the list, without its prefix
  def first_address(addresses)
    address = Array(addresses).first
    address&.split("/")&.first
  end

  # Read the metadata service and prefer its addresses over the ones read
  # from eth0, which depend on the interface name and on eth0:1 aliases
  # that modern images don't create.
  def collect_metadata
    return unless can_socket_connect?(Ohai::Mixin::LinodeMetadata::LINODE_METADATA_ADDR, 80)

    metadata = fetch_metadata
    linode[:instance] = metadata["instance"] if metadata["instance"]
    return unless (network = metadata["network"])

    linode[:network] = network
    public_ip = first_address(network.dig("ipv4", "public"))
    private_ip = first_address(network.dig("ipv4", "private"))
    public_ipv6 = first_address(network.dig("ipv6", "slaac"))
    linode[:public_ip] = public_ip if public_ip
    linode[:private_ip] = private_ip if private_ip
    linode[:public_ipv6] = public_ipv6 if public_ipv6
  rescue => e
    logger.warn("Plugin Linode: Unable to read Linode metadata: #{e.class}: #{e.message}")
  end

  collect_data(:linux) do
    # Setup linode mash if it is a linode system
    if looks_like_linode?
      logger.trace("Plugin Linode: looks_like_linode? == true")
      linode Mash.new
      get_ip_address(:public_ip, :eth0)
      get_ip_address(:private_ip, "eth0:1")
      collect_metadata
      hint?("linode").each { |k, v| linode[k] = v } if hint?("linode").is_a?(Hash)
    else
      logger.trace("Plugin Linode: looks_like_linode? == false")
    end
  end
end
