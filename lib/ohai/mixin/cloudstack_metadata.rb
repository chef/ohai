#
# Author:: Olle Lundberg (<geek@nerd.sh>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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

require 'ohai/mixin/ec2_metadata'
require 'ohai/hints'
require 'net/dhcp'
require 'socket'


module Ohai
  module Mixin
    module CloudstackMetadata
      include Ohai::Mixin::Ec2Metadata

      def self.discover_dhcp_server
        response = ''
        if Ohai::Hints.hint?('cloudstack')
          begin
            request = DHCP::Discover.new

            listensock = UDPSocket.new
            sendsock   = UDPSocket.new

            listensock.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
            sendsock.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)

            sendsock.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
            sendaddr   = "<broadcast>"
            listenport = 68

            listensock.bind('', listenport)
            sendsock.connect(sendaddr, 67)

            sendsock.send(request.pack, 0)

            data = listensock.recvfrom_nonblock(1500)
          rescue Exception => e
            if (defined?(IO::WaitReadable) && e.instance_of?(IO::WaitReadable)) ||
                (e.instance_of?(Errno::EAGAIN) || e.instance_of?(Errno::EWOULDBLOCK)) # This OR branch can be removed when ruby > 1.8.7
              unless IO.select([listensock], nil, nil, 10)
                # timeout reached
                Ohai::Log.debug("Timeout reached awaiting response from DHCP server")
              else
                # try to read from the socket again
                data = listensock.recvfrom_nonblock(1500)
              end
            else
              Ohai::Log.debug("Exceptions encountered when trying to connect to dhcp server. #{e.message}")
            end
          ensure
            sendsock.close
            listensock.close
            if data
              response = [DHCP::Message.from_udp_payload(data[0]).siaddr].pack('N').unpack('C4').join('.')
            end
          end
        end
        response
      end

      CLOUDSTACK_METADATA_ADDR = self.discover_dhcp_server unless defined?(CLOUDSTACK_METADATA_ADDR)

      def http_client
        Net::HTTP.start(CLOUDSTACK_METADATA_ADDR).tap { |h| h.read_timeout = 600 }
      end

      def best_api_version
        'latest'
      end

    end
  end
end

