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
require "yaml" unless defined?(YAML)

module Ohai
  module Mixin
    #
    # Reads the Hetzner Cloud server metadata service:
    # https://docs.hetzner.cloud/#server-metadata
    #
    # It needs no token and answers in YAML.
    #
    module HetznerMetadata

      HETZNER_METADATA_ADDR ||= "169.254.169.254"
      HETZNER_METADATA_PATH ||= "/hetzner/v1/metadata"
      HETZNER_PRIVATE_NETWORKS_PATH ||= "/hetzner/v1/metadata/private-networks"

      # keys never stored on the node: vendor_data is cloud-config that can
      # carry credentials, and network-sysconfig repeats network-config.
      # User data lives at a separate path that is never fetched.
      HETZNER_SKIPPED_KEYS ||= %w{vendor_data network-sysconfig}.freeze

      # @return [Net::HTTP]
      def http_client
        # Connect directly: the metadata service is link-local, so the nil proxy
        # address keeps Net::HTTP from using http_proxy from the environment,
        # and open_timeout replaces Net::HTTP's 60 second default.
        Net::HTTP.start(HETZNER_METADATA_ADDR, 80, nil, open_timeout: 3).tap { |h| h.read_timeout = 6 }
      end

      # The server metadata, with "-" in top level keys replaced by "_" as
      # the other cloud plugins do, plus the private networks.
      #
      # @return [Hash]
      def fetch_metadata
        metadata = {}
        (fetch_yaml(HETZNER_METADATA_PATH) || {}).each do |key, value|
          next if HETZNER_SKIPPED_KEYS.include?(key)

          metadata[key.to_s.tr("-", "_")] = value
        end
        metadata["private_networks"] = fetch_yaml(HETZNER_PRIVATE_NETWORKS_PATH) || []
        metadata
      end

      # @param path [String]
      #
      # @return [Object, nil] the parsed document, or nil on any error
      def fetch_yaml(path)
        response = http_client.get(path)
        unless response.code == "200"
          logger.warn("Mixin HetznerMetadata: Received response code #{response.code} requesting #{path}")
          return nil
        end

        YAML.safe_load(response.body)
      rescue Psych::Exception => e
        logger.warn("Mixin HetznerMetadata: #{path} did not return valid YAML: #{e.message}")
        nil
      end
    end
  end
end
