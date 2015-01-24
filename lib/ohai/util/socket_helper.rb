# Author:: Krzysztof Wilczynski (<kwilczynski@chef.io>)
#
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
#
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

module Ohai
  module Util
    module SocketHelper
      def tcp_port_open?(host, port, timeout = 2)
        Timeout.timeout(timeout) do
          begin
            Socket.do_not_reverse_lookup = true
            TCPSocket.new(host, port).close
            true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            false
          rescue SystemCallError
            false
          rescue SocketError => e
            # Check for DNS resolution failure and return false
            # when we stumble upon such, otherwise raise as it
            # might be something serious that needs attention.
            raise(e) unless e.to_s =~ /getaddrinfo/
            false
          end
        end
      rescue Timeout::Error
        false
      end
    end
  end
end
