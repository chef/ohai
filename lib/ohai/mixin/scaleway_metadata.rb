#
# Author:: Jonathan Amiez (<jonathan.amiez@gmail.com>)
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

require "net/http" unless defined?(Net::HTTP)

module Ohai
  module Mixin
    module ScalewayMetadata

      SCALEWAY_METADATA_ADDR ||= "169.254.42.42".freeze
      SCALEWAY_METADATA_URL ||= "/conf?format=json".freeze

      # @return [Net::HTTP] net/http object without timeout set to 6
      def http_client
        Net::HTTP.start(SCALEWAY_METADATA_ADDR).tap { |h| h.read_timeout = 6 }
      end

      # fetch scaleway metadata and parse the resulting JSON
      #
      # @return [Hash]
      def fetch_metadata
        uri = (SCALEWAY_METADATA_URL).to_s
        response = http_client.get(uri)
        case response.code
        when "200"
          parser = FFI_Yajl::Parser.new
          parser.parse(response.body)
        when "404"
          logger.trace("Mixin ScalewayMetadata: Encountered 404 response retrieving Scaleway metadata: #{uri} ; continuing.")
          {}
        else
          raise "Mixin ScalewayMetadata: Encountered error retrieving Scaleway metadata (#{uri} returned #{response.code} response)"
        end
      end
    end
  end
end
