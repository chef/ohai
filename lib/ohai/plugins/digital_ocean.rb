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

Ohai.plugin(:DigitalOcean) do
  provides "digital_ocean"

  depends "network/interfaces"

  def ip_addresses_for_interface(eth)
    addresses = {'ipv4' => [], 'ipv6' => []}
    if eth_iface = network[:interfaces][eth]
      eth_iface[:addresses].each do |key, info|
        family = address_type_for_family(info[:family])
        addresses[family] << key if addresses.has_key?(family)
      end
    end
    addresses
  end

  def address_type_for_family(family)
    case family
    when 'inet'
      'ipv4'
    when 'inet6'
      'ipv6'
    end
  end

  collect_data do
    hint_metadata = hint?('digital_ocean')
    if hint_metadata
      digital_ocean Mash.new
      hint_metadata.each {|k, v| digital_ocean[k] = v}

      # Prefer actual IP address over hint data
      digital_ocean[:ip_addresses][:public] = ip_addresses_for_interface(:eth0)
      digital_ocean[:ip_addresses][:private] = ip_addresses_for_interface(:eth1)
    else
      Ohai::Log.debug("No hints present for digital_ocean.")
      false
    end
  end
end
