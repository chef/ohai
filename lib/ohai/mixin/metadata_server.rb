#
# Author:: Paul Rossman (<paulrossman@google.com>)
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
require 'stringio'
require 'yajl'

module Ohai
  module Mixin
    module MetadataServer

      def server_available?(addr, port, headers)
        http = Net::HTTP.new(addr, port)
        http.open_timeout = 2
        http.read_timeout = 2
        response = http.get("/", headers)
        response.code == "200"
      rescue StandardError => se
        Ohai::Log.error("http open/read error #{se.inspect}")
        false
      end

      def get_metadata(addr, port, headers, url)
        http = Net::HTTP.new(addr, port)
        http.open_timeout = 10
        http.read_timeout = 10
        begin
          response = http.get(url, headers)
        rescue StandardError => se
          Ohai::Log.error("http open/read error #{se.inspect}")
          return nil
        end
        return nil unless response.code == "200"
        if is_json?(response.body)
          data = StringIO.new(response.body)
          parser = Yajl::Parser.new
          parser.parse(data)
        else
          Ohai::Log.error("response body was not json")
          return nil
        end
      end

      def is_json?(data)
        data = StringIO.new(data)
        parser = Yajl::Parser.new
        begin
          parser.parse(data)
          true
        rescue Yajl::ParseError
          false
        end
      end
    
    end
  end
end
