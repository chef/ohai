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

  # Identifies the linode cloud by preferring the hint, then
  #
  # @return [Boolean]
  #
  def looks_like_linode?
    hint?("linode") || has_linode_domain? || has_linode_apt_repos?
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

  collect_data(:linux) do
    # Setup linode mash if it is a linode system
    if looks_like_linode?
      logger.trace("Plugin Linode: looks_like_linode? == true")
      linode Mash.new
      get_ip_address(:public_ip, :eth0)
      get_ip_address(:private_ip, "eth0:1")
      hint?("linode").each { |k, v| linode[k] = v } if hint?("linode").is_a?(Hash)
    else
      logger.trace("Plugin Linode: looks_like_linode? == false")
    end
  end
end
