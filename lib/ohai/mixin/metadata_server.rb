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
      rescue StandardError,Timeout::Error => se
        Ohai::Log.error("http open/read error #{se.inspect}")
        false
      end

      def get_metadata(addr, port, headers, url)
        http = Net::HTTP.new(addr, port)
        http.open_timeout = 10
        http.read_timeout = 60
        begin
          response = http.get(url, headers)
        rescue StandardError,Timeout::Error => se
          Ohai::Log.error("http open/read error #{se.inspect}")
          return nil
        end
        return nil unless response.code == "200"
        data = safe_json_parse(response.body)
        Ohai::Log.error("response body was not json") if data.nil?
        data
      end

      def safe_json_parse(data)
        parser = Yajl::Parser.new
        begin
          parser.parse(data)
        rescue Yajl::ParseError
          nil
        end
      end
    
    end
  end
end
