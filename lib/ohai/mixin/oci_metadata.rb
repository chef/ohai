# frozen_string_literal: true

#
# Author:: Renato Covarrubias (<rnt@rnt.cl>)
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

require "net/http" unless defined?(Net::HTTP)

require_relative "../mixin/json_helper"
include Ohai::Mixin::JsonHelper

module Ohai
  module Mixin
    module OCIMetadata
      OCI_METADATA_ADDR = "169.254.169.254"
      OCI_METADATA_URL = "/opc/v2"
      CHASSIS_ASSET_TAG_FILE = "/sys/devices/virtual/dmi/id/chassis_asset_tag"

      # fetch the meta content with a timeout and the required header
      def http_get(uri)
        conn = Net::HTTP.start(OCI_METADATA_ADDR)
        conn.read_timeout = 6
        conn.get(
          uri,
          {
            "Authorization" => "Bearer Oracle",
            "User-Agent" => "chef-ohai/#{Ohai::VERSION}",
          }
        )
      end

      # Fetch metadata from api
      def fetch_metadata(metadata = "instance")
        response = http_get("#{OCI_METADATA_URL}/#{metadata}")
        if response.code == "200"
          json_data = parse_json(response.body)
          if json_data.nil?
            logger.warn("Mixin OciMetadata: Metadata response is NOT valid JSON")
          end
          json_data
        else
          logger.warn("Mixin OciMetadata: Received response code #{response.code} requesting metadata")
          nil
        end
      end
    end
  end
end
