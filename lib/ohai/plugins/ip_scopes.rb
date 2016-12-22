#
# Author:: James Harton (<james@sociable.co.nz>)
# Copyright:: Copyright (c) 2010 Sociable Limited.
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

Ohai.plugin(:IpScopes) do
  provides "network_ip_scope", "privateaddress"

  depends "network/interfaces"

  collect_data do
    begin
      require "ipaddr_extensions"

      network["interfaces"].keys.sort.each do |if_name|
        next if network["interfaces"][if_name]["addresses"].nil?

        interface = network["interfaces"][if_name]
        interface["addresses"].each do |address, attrs|
          begin
            attrs["ip_scope"] = address.to_ip.scope

            if private_addr?(address) && !tunnel_iface?(interface) && !ppp_iface?(interface) && !docker_iface?(interface)
              privateaddress(address)
            end
          rescue ArgumentError
            # Just silently fail if we can't create an IP from the string.
          end
        end
      end

    rescue LoadError => e
      # our favourite gem is not installed. Boohoo.
      Ohai::Log.debug("Plugin IpScopes: cannot load gem, plugin disabled: #{e}")
    end
  end

  def private_addr?(address)
    address.to_ip.scope =~ /PRIVATE/
  end

  def ppp_iface?(interface)
    interface["type"] == "ppp"
  end

  def tunnel_iface?(interface)
    interface["type"] == "tunl"
  end

  def docker_iface?(interface)
    interface["type"] == "docker"
  end
end
