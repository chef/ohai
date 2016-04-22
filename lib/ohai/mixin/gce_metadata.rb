#
# Author:: Ranjib Dey (<dey.ranjib@gmail.com>)
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

require "net/http"
require "socket"

module Ohai
  module Mixin
    module GCEMetadata

      # Trailing dot to host is added to avoid DNS search path
      GCE_METADATA_ADDR = "metadata.google.internal." unless defined?(GCE_METADATA_ADDR)
      GCE_METADATA_URL = "/computeMetadata/v1/?recursive=true" unless defined?(GCE_METADATA_URL)

      def can_metadata_connect?(addr, port, timeout = 2)
        t = Socket.new(Socket::Constants::AF_INET, Socket::Constants::SOCK_STREAM, 0)
        begin
          saddr = Socket.pack_sockaddr_in(port, addr)
        rescue SocketError => e # occurs when non-GCE systems try to resolve metadata.google.internal
          Ohai::Log.debug("Mixin GCE: can_metadata_connect? failed setting up socket: #{e}")
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
        Ohai::Log.debug("Mixin GCE: can_metadata_connect? == #{connected}")
        connected
      end

      # fetch the meta content with a timeout and the required header
      def http_get(uri)
        conn = Net::HTTP.start(GCE_METADATA_ADDR)
        conn.read_timeout = 6
        conn.get(uri, initheader = { "Metadata-Flavor" => "Google" })
      end

      def fetch_metadata(id = "")
        response = http_get("#{GCE_METADATA_URL}/#{id}")
        return nil unless response.code == "200"

        if json?(response.body)
          data = StringIO.new(response.body)
          parser = FFI_Yajl::Parser.new
          parser.parse(data)
        elsif has_trailing_slash?(id) || (id == "")
          temp = {}
          response.body.split("\n").each do |sub_attr|
            temp[sanitize_key(sub_attr)] = fetch_metadata("#{id}#{sub_attr}")
          end
          temp
        else
          response.body
        end
      end

      def json?(data)
        data = StringIO.new(data)
        parser = FFI_Yajl::Parser.new
        begin
          parser.parse(data)
          true
        rescue FFI_Yajl::ParseError
          false
        end
      end

      def multiline?(data)
        data.lines.to_a.size > 1
      end

      def has_trailing_slash?(data)
        !! ( data =~ %r{/$} )
      end

      def sanitize_key(key)
        key.gsub(/\-|\//, "_")
      end
    end
  end
end
