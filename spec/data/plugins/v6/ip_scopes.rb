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

begin
  require 'ipaddr_extensions'

  provides "network_ip_scope", "privateaddress"

  require_plugin "hostname"
  require_plugin "network"

  network['interfaces'].keys.each do |ifName|
    next if network['interfaces'][ifName]['addresses'].nil?

    network['interfaces'][ifName]['addresses'].each do |address,attrs|
      begin
        attrs.merge! 'ip_scope' => address.to_ip.scope
        privateaddress address if address.to_ip.scope =~ /PRIVATE/
      rescue ArgumentError
        # Just silently fail if we can't create an IP from the string.
      end
    end
  end

rescue LoadError => e
  # our favourite gem is not installed. Boohoo.
  Ohai::Log.debug("ip_scopes: cannot load gem, plugin disabled: #{e}")
end
