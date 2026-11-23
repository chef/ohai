# frozen_string_literal: true
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright (c) 2026 Tim Smith
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
#

require "net/http" unless defined?(Net::HTTP)
require_relative "json_helper"

module Ohai
  module Mixin
    #
    # Reads the Akamai (Linode) Metadata Service:
    # https://techdocs.akamai.com/cloud-computing/docs/overview-of-the-metadata-service
    #
    # Every request needs a token from PUT /v1/token, sent back in the
    # Metadata-Token header. Responses are JSON when asked for with Accept.
    #
    module LinodeMetadata
      include Ohai::Mixin::JsonHelper

      LINODE_METADATA_ADDR ||= "169.254.169.254"
      # the instance and network documents; user data is never requested
      LINODE_METADATA_DOCUMENTS ||= %w{instance network}.freeze

      # @return [Net::HTTP]
      def http_client
        # Connect directly: the metadata service is link-local, so the nil proxy
        # address keeps Net::HTTP from using http_proxy from the environment,
        # and open_timeout replaces Net::HTTP's 60 second default.
        @http_client ||= Net::HTTP.start(LINODE_METADATA_ADDR, 80, nil, open_timeout: 3).tap { |h| h.read_timeout = 6 }
      end

      # @return [String, nil] a short-lived token, or nil if none was issued
      def metadata_token
        response = http_client.put("/v1/token", "", { "Metadata-Token-Expiry-Seconds" => "300" })
        if response.code == "200"
          response.body.to_s.strip
        else
          logger.warn("Mixin LinodeMetadata: Received response code #{response.code} requesting a metadata token")
          nil
        end
      end

      # @return [Hash] "instance" and "network" documents that could be read
      def fetch_metadata
        token = metadata_token
        return {} if token.nil? || token.empty?

        LINODE_METADATA_DOCUMENTS.each_with_object({}) do |document, metadata|
          response = http_client.get("/v1/#{document}", { "Metadata-Token" => token, "Accept" => "application/json" })
          unless response.code == "200"
            logger.warn("Mixin LinodeMetadata: Received response code #{response.code} requesting /v1/#{document}")
            next
          end

          data = parse_json(response.body)
          if data.is_a?(Hash)
            metadata[document] = data
          else
            logger.warn("Mixin LinodeMetadata: /v1/#{document} did not return a JSON object")
          end
        end
      rescue Timeout::Error, SystemCallError, IOError => e
        logger.warn("Mixin LinodeMetadata: Unable to reach the metadata service: #{e.class}: #{e.message}")
        {}
      end
    end
  end
end
