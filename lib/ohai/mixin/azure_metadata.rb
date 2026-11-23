# frozen_string_literal: true
#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

      # Azure sets this SMBIOS chassis asset tag on every VM. It comes from
      # the hypervisor, so unlike the agent or a DHCP lease it doesn't survive
      # moving a disk to another cloud. cloud-init's ds-identify uses it too.
      AZURE_CHASSIS_ASSET_TAG ||= "7783-7084-3265-9085-8269-3286-77"

      # where WALinuxAgent installs waagent: most distros, Azure Linux and
      # Mariner, FreeBSD and OpenBSD, Flatcar
      WAAGENT_PATHS ||= %w{/usr/sbin/waagent /usr/bin/waagent /usr/local/sbin/waagent /usr/share/oem/bin/waagent}.freeze

      # Known versions, newest last. IMDS lists the versions it supports when
      # asked without one, and Ohai uses the newest of those; this list is the
      # fallback when that list can't be read.
      AZURE_SUPPORTED_VERSIONS ||= %w{ 2018-10-01 2019-02-01 2019-03-11 2019-04-30 2019-06-01
                                       2019-06-04 2019-08-01 2019-08-15 2019-11-01 2020-06-01
                                       2020-07-15 2020-09-01 2020-10-01 2020-12-01 2021-01-01
                                       2021-02-01 2021-03-01 2021-05-01 2021-10-01 2021-11-01
                                       2021-11-15 2021-12-13 2023-07-01 }.freeze

      # IMDS answers 410 while a VM is starting, 429 when callers exceed its
      # rate limit and 500 on transient errors; all are worth retrying
      AZURE_RETRY_CODES ||= %w{410 429 500 503}.freeze
      AZURE_MAX_ATTEMPTS ||= 3

      def best_api_version
        @api_version ||= begin
          logger.trace("Mixin AzureMetadata: Fetching http://#{AZURE_METADATA_ADDR}/metadata/instance to determine the latest supported metadata release")
          response = http_get_with_retry("/metadata/instance")
          if response.code == "404"
            logger.trace("Mixin AzureMetadata: Received HTTP 404 from metadata server while determining API version, assuming #{AZURE_SUPPORTED_VERSIONS.last}")
            AZURE_SUPPORTED_VERSIONS.last
          elsif response.code != "400" # 400 is actually what we want
            raise "Mixin AzureMetadata: Unable to determine Azure metadata version (returned #{response.code} response)"
          else
            # Azure returns the 3 newest versions it supports. Use the newest
            # one even if Ohai doesn't list it: the instance document only
            # gains fields between versions, and an allowlist that lags
            # behind IMDS hides them (physicalZone needs 2023-11-15).
            versions = Array((parse_json(response.body) || {})["newest-versions"]).sort
            if versions.empty?
              logger.debug "Mixin AzureMetadata: The Azure Instance Metadata service listed no versions. Using the latest release known to Ohai: #{AZURE_SUPPORTED_VERSIONS.last}"
              AZURE_SUPPORTED_VERSIONS.last
            else
              logger.trace("Mixin AzureMetadata: Latest Azure metadata version: #{versions.last}")
              versions.last
            end
          end
        end
      end

      # http_get, retrying the responses IMDS documents as transient
      #
      # @param [String] the relative uri to fetch from the Azure Metadata Service URL
      #
      # @return [Net::HTTPResponse] the last response
      def http_get_with_retry(uri)
        attempt = 0
        loop do
          attempt += 1
          response = http_get(uri)
          return response unless AZURE_RETRY_CODES.include?(response.code) && attempt < AZURE_MAX_ATTEMPTS

          logger.trace("Mixin AzureMetadata: Received HTTP #{response.code} for #{uri}, retrying")
          sleep(attempt)
        end
      end

      # fetch the meta content with a timeout and the required header and a read timeout of 6s
      #
      # @param [String] the relative uri to fetch from the Azure Metadata Service URL
      #
      # @return [Net::HTTP]
      def http_get(uri)
        # Connect directly: the metadata service is link-local, so the nil proxy
        # address keeps Net::HTTP from using http_proxy from the environment,
        # and open_timeout replaces Net::HTTP's 60 second default.
        conn = Net::HTTP.start(AZURE_METADATA_ADDR, 80, nil, open_timeout: 3)
        conn.read_timeout = 6
        conn.get(uri, { "Metadata" => "true" })
      end

      def fetch_metadata(_api_version = nil)
        metadata_url = "/metadata/instance?api-version=#{best_api_version}"
        logger.trace("Mixin AzureMetadata: Fetching metadata from host #{AZURE_METADATA_ADDR} at #{metadata_url}")
        response = http_get_with_retry(metadata_url)
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
