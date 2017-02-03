#
# Copyright:: 2017, Chef Software, Inc.
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

require "socket"

module Ohai
  module Mixin
    module HttpHelper

      def can_socket_connect?(addr, port, timeout = 2)
        t = Socket.new(Socket::Constants::AF_INET, Socket::Constants::SOCK_STREAM, 0)
        begin
          saddr = Socket.pack_sockaddr_in(port, addr)
        rescue SocketError => e # generally means dns resolution error
          Ohai::Log.debug("Mixin HttpHelper: can_socket_connect? failed setting up socket connection: #{e}")
          return false
        end

        connected = false

        begin
          t.connect_nonblock(saddr)
        rescue Errno::EINPROGRESS
          r, w, e = IO.select(nil, [t], nil, timeout)
          if !w.nil?
            connected = true
          else
            begin
              t.connect_nonblock(saddr)
            rescue Errno::EISCONN
              t.close
              connected = true
            rescue SystemCallError
            end
          end
        rescue SystemCallError
        end
        Ohai::Log.debug("Mixin HttpHelper: can_socket_connect? == #{connected}")
        connected
      end
    end
  end
end
