#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright 2017 Chef Software, Inc.
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
    module AzureMetadata

      AZURE_METADATA_ADDR ||= "169.254.169.254".freeze
      AZURE_METADATA_URL ||= "/metadata/instance?api-version=2017-08-01".freeze

      # fetch the meta content with a timeout and the required header
      def http_get(uri)
        conn = Net::HTTP.start(AZURE_METADATA_ADDR)
        conn.read_timeout = 6
        conn.get(uri, { "Metadata" => "true" })
      end

      def fetch_metadata
        logger.trace("Mixin AzureMetadata: Fetching metadata from host #{AZURE_METADATA_ADDR} at #{AZURE_METADATA_URL}")
        response = http_get(AZURE_METADATA_URL)
        if response.code == "200"
          begin
            data = StringIO.new(response.body)
            parser = FFI_Yajl::Parser.new
            parser.parse(data)
          rescue FFI_Yajl::ParseError
            logger.warn("Mixin AzureMetadata: Metadata response is NOT valid JSON")
            nil
          end
        else
          logger.warn("Mixin AzureMetadata: Received response code #{response.code} requesting metadata")
          nil
        end
      end
    end
  end
end
