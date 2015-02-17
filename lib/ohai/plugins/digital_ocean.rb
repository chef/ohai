#
# Author:: Stafford Brunk (<stafford.brunk@gmail.com>)
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

require 'ohai/util/ip_helper'

Ohai.plugin(:DigitalOcean) do
  include Ohai::Util::IpHelper

  DIGITALOCEAN_FILE = '/etc/digitalocean' unless defined?(DIGITALOCEAN_FILE)

  provides "digital_ocean"

  depends "network/interfaces"

  def extract_droplet_ip_addresses
    addresses = Mash.new({'v4' => [], 'v6' => []})
    network[:interfaces].each_value do |iface|
      iface[:addresses].each do |address, details|
        next if loopback?(address) || details[:family] == 'lladdr'

        ip = IPAddress(address)
        type = digital_ocean_address_type(ip)
        address_hash = build_address_hash(ip, details)
        addresses[type] << address_hash
      end 
    end
    addresses
  end

  def build_address_hash(ip, details)
    address_hash = Mash.new({
      'ip_address' => ip.address,
      'type' => private_address?(ip.address) ? 'private' : 'public'
    })

    if ip.ipv4?
      address_hash['netmask'] = details[:netmask]
    elsif ip.ipv6?
      address_hash['cidr'] = ip.prefix
    end
    address_hash
  end

  def digital_ocean_address_type(ip)
    ip.ipv4? ? 'v4' : 'v6'
  end

  def looks_like_digital_ocean?
    hint?('digital_ocean') || File.exist?(DIGITALOCEAN_FILE)
  end

  collect_data do
    if looks_like_digital_ocean?
      digital_ocean Mash.new
      hint = hint?('digital_ocean') || {}
      hint.each {|k, v| digital_ocean[k] = v unless k == 'ip_addresses'}

      # Extract actual ip addresses
      # The networks sub-hash is structured similarly to how
      # Digital Ocean's v2 API structures things:
      # https://developers.digitalocean.com/#droplets
      digital_ocean[:networks] = extract_droplet_ip_addresses
    else
      Ohai::Log.debug("No hints present for digital_ocean.")
      false
    end
  end
end
