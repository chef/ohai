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

require "ipaddress"

module Ohai
  module Util
    module IpHelper
      # Corresponding to RFC 4192 + RFC 4193
      IPV6_LINK_LOCAL_UNICAST_BLOCK = IPAddress("fe80::/10")
      IPV6_PRIVATE_ADDRESS_BLOCK = IPAddress("fc00::/7")

      def private_address?(addr)
        ip = IPAddress(addr)

        if ip.respond_to? :private?
          ip.private?
        else
          IPV6_LINK_LOCAL_UNICAST_BLOCK.include?(ip) || IPV6_PRIVATE_ADDRESS_BLOCK.include?(ip)
        end
      end
      alias :unique_local_address? :private_address?

      def public_address?(addr)
        !private_address?(addr)
      end

      # The ipaddress gem doesn't implement loopback?
      # for IPv4 addresses
      # https://github.com/bluemonk/ipaddress/issues/25
      def loopback?(addr)
        ip = IPAddress(addr)

        if ip.respond_to? :loopback?
          ip.loopback?
        else
          IPAddress("127.0.0.0/8").include? ip
        end
      end
    end
  end
end
