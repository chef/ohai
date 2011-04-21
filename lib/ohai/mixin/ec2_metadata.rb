#
# Author:: Tim Dysinger (<tim@dysinger.net>)
# Author:: Benjamin Black (<bb@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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
    module Ec2Metadata

      EC2_METADATA_ADDR = "169.254.169.254" unless defined?(EC2_METADATA_ADDR)
      EC2_METADATA_URL = "/2008-02-01/meta-data" unless defined?(EC2_METADATA_URL)
      EC2_USERDATA_URL = "/2008-02-01/user-data" unless defined?(EC2_USERDATA_URL)
      EC2_ARRAY_VALUES = %w(security-groups)

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
        Net::HTTP.start(EC2_METADATA_ADDR).tap {|h| h.read_timeout = 600}
      end

      def fetch_metadata(id='')
        metadata = Hash.new
        http_client.get("#{EC2_METADATA_URL}/#{id}").body.split("\n").each do |o|
          key = "#{id}#{o.gsub(/\=.*$/, '/')}"
          if key[-1..-1] != '/'
            metadata[key.gsub(/\-|\//, '_').to_sym] =
              if EC2_ARRAY_VALUES.include? key
                http_client.get("#{EC2_METADATA_URL}/#{key}").body.split("\n")
              else
                http_client.get("#{EC2_METADATA_URL}/#{key}").body
              end
          else
            fetch_metadata(key).each{|k,v| metadata[k] = v}
          end
        end
        metadata
      end

      def fetch_userdata()
        response = http_client.get("#{EC2_USERDATA_URL}/")
        response.code == "200" ? response.body : nil
      end
    end
  end
end

