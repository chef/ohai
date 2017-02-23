
# Author:: Dylan Page (<dpage@digitalocean.com>)
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

module Ohai
  module Mixin
    module DOMetadata

      DO_METADATA_ADDR = "169.254.169.254" unless defined?(DO_METADATA_ADDR)
      DO_METADATA_URL = "/metadata/v1.json" unless defined?(DO_METADATA_URL)

      def http_client
        Net::HTTP.start(DO_METADATA_ADDR).tap { |h| h.read_timeout = 6 }
      end

      def fetch_metadata
        uri = "#{DO_METADATA_URL}"
        response = http_client.get(uri)
        case response.code
        when "200"
          parser = FFI_Yajl::Parser.new
          parser.parse(response.body)
        when "404"
          Ohai::Log.debug("Mixin DOMetadata: Encountered 404 response retreiving Digital Ocean metadata: #{uri} ; continuing.")
          {}
        else
          raise "Mixin DOMetadata: Encountered error retrieving Digital Ocean metadata (#{uri} returned #{response.code} response)"
        end
      end

    end
  end
end
