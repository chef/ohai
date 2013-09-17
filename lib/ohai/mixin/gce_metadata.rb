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

require 'net/http'
require 'socket'

module Ohai
  module Mixin
    module GCEMetadata

      extend self

      GCE_METADATA_ADDR = "metadata.google.internal" unless defined?(GCE_METADATA_ADDR)
      GCE_METADATA_URL = "/computeMetadata/v1beta1/?recursive=true" unless defined?(GCE_METADATA_URL)

      def can_metadata_connect?(addr, port, timeout=2)
        t = Socket.new(Socket::Constants::AF_INET, Socket::Constants::SOCK_STREAM, 0)
        saddr = Socket.pack_sockaddr_in(port, addr)
        connected = false

        begin
          t.connect_nonblock(saddr)
        rescue Errno::EINPROGRESS
          r,w,e = IO::select(nil,[t],nil,timeout)
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
        Ohai::Log.debug("can_metadata_connect? == #{connected}")
        connected
      end

      def http_client
        Net::HTTP.start(GCE_METADATA_ADDR).tap {|h| h.read_timeout = 600}
      end

      def fetch_metadata(id='')
        uri = "#{GCE_METADATA_URL}/#{id}"
        response = http_client.get(uri)
        return nil unless response.code == "200"
        
        if json?(response.body)
          data = StringIO.new(response.body)
          parser = Yajl::Parser.new
          parser.parse(data)
        elsif  has_trailing_slash?(id) or (id == '')
          temp={}
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
        parser = Yajl::Parser.new
        begin
          parser.parse(data)
          true
        rescue Yajl::ParseError
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
        key.gsub(/\-|\//, '_')
      end
    end
  end
end
