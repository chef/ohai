# frozen_string_literal: true
#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../mixin/json_helper"
include Ohai::Mixin::JsonHelper

module Ohai
  module Mixin
    #
    # This code parses the Azure Instance Metadata API to provide details
    # of the running instance.
    #
    # The code probes the instance metadata endpoint for
    # available versions, determines the most advanced version known to
    # work and executes the metadata retrieval using that version.
    #
    # If no compatible version is found, an empty hash is returned.
    #
    module AzureMetadata

      AZURE_METADATA_ADDR ||= "169.254.169.254"

      # it's important that the newer versions are at the end of this array so we can skip sorting it
      AZURE_SUPPORTED_VERSIONS ||= %w{ 2018-10-01 2019-02-01 2019-03-11 2019-04-30 2019-06-01
                                       2019-06-04 2019-08-01 2019-08-15 2019-11-01 2020-06-01
                                       2020-07-15 2020-09-01 2020-10-01 2020-12-01 2021-01-01
                                       2021-02-01 2021-03-01 2021-05-01 2021-10-01 }.freeze

      def best_api_version
        @api_version ||= begin
          logger.trace("Mixin AzureMetadata: Fetching http://#{AZURE_METADATA_ADDR}/metadata/instance to determine the latest supported metadata release")
          response = http_get("/metadata/instance")
          if response.code == "404"
            logger.trace("Mixin AzureMetadata: Received HTTP 404 from metadata server while determining API version, assuming #{AZURE_SUPPORTED_VERSIONS.last}")
            return AZURE_SUPPORTED_VERSIONS.last
          elsif response.code != "400" # 400 is actually what we want
            raise "Mixin AzureMetadata: Unable to determine Azure metadata version (returned #{response.code} response)"
          end

          # azure returns a list of the 3 latest versions it supports
          versions = parse_json(response.body).fetch("newest-versions", [])
          versions.sort!

          until versions.empty? || AZURE_SUPPORTED_VERSIONS.include?(versions.last)
            pv = versions.pop
            logger.trace("Mixin AzureMetadata: Azure metadata version #{pv} is not present in the versions provided by the Azure Instance Metadata service")
          end

          if versions.empty?
            logger.debug "Mixin AzureMetadata: The short list of supported versions provided by Azure Instance Metadata service doesn't match any known versions to Ohai. Using the latest supported release known to Ohai instead: #{AZURE_SUPPORTED_VERSIONS.last}"
            return AZURE_SUPPORTED_VERSIONS.last
          end

          logger.trace("Mixin AzureMetadata: Latest supported Azure metadata version: #{versions.last}")
          versions.last
        end
      end

      # fetch the meta content with a timeout and the required header and a read timeout of 6s
      #
      # @param [String] the relative uri to fetch from the Azure Metadata Service URL
      #
      # @return [Net::HTTP]
      def http_get(uri)
        conn = Net::HTTP.start(AZURE_METADATA_ADDR)
        conn.read_timeout = 6
        conn.get(uri, { "Metadata" => "true" })
      end

      def fetch_metadata(_api_version = nil)
        metadata_url = "/metadata/instance?api-version=#{best_api_version}"
        logger.trace("Mixin AzureMetadata: Fetching metadata from host #{AZURE_METADATA_ADDR} at #{metadata_url}")
        response = http_get(metadata_url)
        if response.code == "200"
          json_data = parse_json(response.body)
          if json_data.nil?
            logger.warn("Mixin AzureMetadata: Metadata response is NOT valid JSON")
          end
          json_data
        else
          logger.warn("Mixin AzureMetadata: Received response code #{response.code} requesting metadata")
          nil
        end
      end
    end
  end
end
