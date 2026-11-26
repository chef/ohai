# frozen_string_literal: true
#
# Author:: Tim Dysinger (<tim@dysinger.net>)
# Author:: Benjamin Black (<bb@chef.io>)
# Author:: Christopher Brown (<cb@chef.io>)
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
    ##
    # This code parses the EC2 Instance Metadata API to provide details
    # of the running instance.
    #
    # Earlier version of this code assumed a specific version of the
    # metadata API was available. Unfortunately the API versions
    # supported by a particular instance are determined at instance
    # launch and are not extended over the life of the instance. As such
    # the earlier code would fail depending on the age of the instance.
    #
    # The updated code probes the instance metadata endpoint for
    # available versions, determines the most advanced version known to
    # work and executes the metadata retrieval using that version.
    #
    # If no compatible version is found, an empty hash is returned.
    #
    module Ec2Metadata

      EC2_METADATA_ADDR ||= "169.254.169.254"
      # Versions Ohai was originally written against. No longer used to filter:
      # Ohai uses the newest version the metadata service lists, since newer
      # versions only add categories (AWS recommends always using "latest").
      EC2_SUPPORTED_VERSIONS ||= %w{ 1.0
                                     2007-01-19
                                     2007-03-01
                                     2007-08-29
                                     2007-10-10
                                     2007-12-15
                                     2008-02-01
                                     2008-09-01
                                     2009-04-04
                                     2011-01-01
                                     2011-05-01
                                     2012-01-12
                                     2014-02-25
                                     2014-11-05
                                     2015-10-20
                                     2016-04-19
                                     2016-06-30
                                     2016-09-02
                                     2018-03-28
                                     2018-08-17
                                     2018-09-24
                                     2019-10-01
                                     2020-10-27
                                     2021-01-03
                                     2021-03-23
                                     2021-07-15 }.freeze
      EC2_ARRAY_VALUES ||= %w{security-groups local_ipv4s}.freeze
      EC2_ARRAY_DIR    ||= %w{network/interfaces/macs}.freeze
      EC2_JSON_DIR     ||= %w{iam}.freeze
      # IMDS answers transient failures with these; retry them with a backoff
      EC2_RETRY_CODES  ||= %w{429 500 503}.freeze
      EC2_MAX_ATTEMPTS ||= 3
      EC2_TOKEN_READ_TIMEOUT ||= 2
      # errors from the connection itself rather than an HTTP response
      # (Net::ReadTimeout and Net::OpenTimeout are Timeout::Errors)
      EC2_TRANSPORT_ERRORS ||= [Timeout::Error, SystemCallError, IOError, SocketError, Net::HTTPBadResponse].freeze

      #
      # The newest metadata version this instance supports
      # in AWS supported metadata versions are determined at instance start so we need to be
      # cautious here in case an instance has been running for a long time
      #
      # @return [String] the version
      #
      def best_api_version
        @api_version ||= begin
          logger.trace("Mixin EC2: Fetching http://#{EC2_METADATA_ADDR}/ to determine the latest supported metadata release")
          response = http_client.get("/", { 'X-aws-ec2-metadata-token': v2_token })
          if response.code == "404"
            logger.trace("Mixin EC2: Received HTTP 404 from metadata server while determining API version, assuming 'latest'")
            "latest"
          elsif response.code != "200"
            raise "Mixin EC2: Unable to determine EC2 metadata version (returned #{response.code} response)"
          else
            # Versions are "1.0" or dated ("2021-07-15"), so a string sort
            # orders them. Ignore "latest" and anything else an EC2-compatible
            # service such as OpenStack might list.
            versions = response.body.split("\n").map(&:strip).grep(/\A(1\.0|\d{4}-\d{2}-\d{2})\z/).sort
            if versions.empty?
              raise "Mixin EC2: Unable to determine EC2 metadata version (no supported entries found)"
            end

            logger.trace("Mixin EC2: Latest EC2 metadata version: #{versions.last}")
            versions.last
          end
        end
      end

      # a net/http client with a timeout of 10s and a keepalive of 10s
      #
      # @return [Net::HTTP]
      def http_client
        # Connect directly: the metadata service is link-local, so the nil proxy
        # address keeps Net::HTTP from using http_proxy from the environment,
        # and open_timeout replaces Net::HTTP's 60 second default.
        @conn ||= Net::HTTP.start(EC2_METADATA_ADDR, 80, nil, open_timeout: 3).tap do |h|
          h.read_timeout = 10
          h.keep_alive_timeout = 10
        end
      end

      #
      # Fetch an API token for use querying AWS IMDSv2 or return nil if no token if found
      # AWS like systems (think OpenStack) will not respond with a token here
      #
      # @return [NilClass, String] API token or nil
      #
      def v2_token
        # memoize nil too: AWS-like services without IMDSv2 (OpenStack) would
        # otherwise get a token request before every metadata request
        return @v2_token if defined?(@v2_token)

        @v2_token = fetch_v2_token
      end

      # Only a 200 response carries a token. Anything else (404 from AWS-like
      # services, 403 when IMDS is turned off, 400) or a timeout (inside a
      # container the default hop limit of 1 drops the response) falls back
      # to IMDSv1 requests without a token.
      #
      # @return [NilClass, String] API token or nil
      def fetch_v2_token
        client = http_client
        read_timeout = client.read_timeout
        client.read_timeout = EC2_TOKEN_READ_TIMEOUT
        # the token lasts the whole run, so a long metadata walk can't outlive it
        response = client.put("/latest/api/token", nil, { 'X-aws-ec2-metadata-token-ttl-seconds': "21600" })
        if response.code == "200"
          response.body
        else
          logger.trace("Mixin EC2: IMDSv2 token request returned #{response.code}; continuing without a token")
          nil
        end
      rescue Timeout::Error, SystemCallError, IOError => e
        logger.trace("Mixin EC2: IMDSv2 token request failed (#{e.class}); continuing without a token")
        nil
      ensure
        client.read_timeout = read_timeout if client && read_timeout
      end

      # Get metadata for a given path and API version
      #
      # Typically, a 200 response is expected for valid metadata.
      # On certain instance types, traversing the provided metadata path
      # produces a 404 for some unknown reason. In that event, return
      # `nil` and continue the run instead of failing it.
      #
      # A 401 means the token expired or was rejected, so it is fetched again
      # once. 429, 500 and 503 and connection errors (timeouts, resets) are
      # retried with a short backoff. Any other error skips this one path
      # instead of failing the whole plugin.
      #
      # A path whose every attempt fails to connect marks the service
      # unreachable, and the remaining paths are skipped without a request,
      # so a metadata service that goes away mid-walk costs one path's
      # timeouts rather than every path's.
      def metadata_get(id, api_version)
        path = "/#{api_version}/meta-data/#{escape_metadata_path(id)}"
        return nil if imds_unreachable?(path)

        token_refreshed = false
        attempt = 0
        loop do
          attempt += 1
          logger.trace("Mixin EC2: Fetching http://#{EC2_METADATA_ADDR}#{path}")
          begin
            response = http_client.get(path, { 'X-aws-ec2-metadata-token': v2_token })
          rescue *EC2_TRANSPORT_ERRORS => e
            if attempt < EC2_MAX_ATTEMPTS
              sleep(0.5 * attempt)
              next
            end

            logger.warn("Mixin EC2: Unable to reach the EC2 metadata service for #{path} (#{e.class}: #{e.message}); skipping the remaining paths")
            @imds_unreachable = true
            return nil
          end

          case response.code
          when "200"
            return response.body
          when "404"
            logger.trace("Mixin EC2: Encountered 404 response retrieving EC2 metadata path: #{path} ; continuing.")
            return nil
          when "401"
            unless token_refreshed
              token_refreshed = true
              remove_instance_variable(:@v2_token) if defined?(@v2_token)
              next
            end
          when *EC2_RETRY_CODES
            if attempt < EC2_MAX_ATTEMPTS
              sleep(0.5 * attempt)
              next
            end
          end

          logger.warn("Mixin EC2: Skipping EC2 metadata path #{path} after a #{response.code} response")
          return nil
        end
      end

      def fetch_metadata(id = "", api_version = nil)
        metadata = {}
        retrieved_metadata = metadata_get(id, best_api_version)
        if retrieved_metadata
          retrieved_metadata.split("\n").each do |o|
            key = expand_path("#{id}#{o}")
            if key[-1..-1] != "/"
              metadata[metadata_key(key)] =
                if EC2_ARRAY_VALUES.include? key
                  retr_meta = metadata_get(key, best_api_version)
                  retr_meta ? retr_meta.split("\n") : retr_meta
                else
                  metadata_get(key, best_api_version)
                end
            elsif (!key.eql?(id)) && (!key.eql?("/"))
              name = key[0..-2]
              sym = metadata_key(name)
              if EC2_ARRAY_DIR.include?(name)
                metadata[sym] = fetch_dir_metadata(key, best_api_version)
              elsif EC2_JSON_DIR.include?(name)
                metadata[sym] = fetch_json_dir_metadata(key, best_api_version)
              else
                # a directory listing that returns 404 comes back as nil
                (fetch_metadata(key, best_api_version) || {}).each { |k, v| metadata[k] = v }
              end
            end
          end
          metadata
        end
      end

      def fetch_dir_metadata(id, api_version)
        metadata = {}
        retrieved_metadata = metadata_get(id, api_version)
        if retrieved_metadata
          retrieved_metadata.split("\n").each do |o|
            key = expand_path(o)
            if key[-1..-1] != "/"
              retr_meta = metadata_get("#{id}#{key}", api_version)
              metadata[metadata_key(key)] = retr_meta || ""
            elsif !key.eql?("/")
              metadata[key[0..-2]] = fetch_dir_metadata("#{id}#{key}", api_version)
            end
          end
          metadata
        end
      end

      def fetch_json_dir_metadata(id, api_version)
        metadata = {}
        retrieved_metadata = metadata_get(id, api_version)
        if retrieved_metadata
          retrieved_metadata.split("\n").each do |o|
            key = expand_path(o)
            if key[-1..-1] != "/"
              retr_meta = metadata_get("#{id}#{key}", api_version)
              data = retr_meta || ""
              json = String(data)
              parser = FFI_Yajl::Parser.new
              metadata[metadata_key(key)] = parser.parse(json)
            elsif !key.eql?("/")
              metadata[key[0..-2]] = fetch_json_dir_metadata("#{id}#{key}", api_version)
            end
          end
          metadata
        end
      end

      def fetch_userdata
        path = "/#{best_api_version}/user-data/"
        return nil if imds_unreachable?(path)

        logger.trace("Mixin EC2: Fetching http://#{EC2_METADATA_ADDR}#{path}")
        response = http_client.get(path, { 'X-aws-ec2-metadata-token': v2_token })
        response.code == "200" ? response.body : nil
      rescue *EC2_TRANSPORT_ERRORS => e
        logger.warn("Mixin EC2: Unable to fetch EC2 user data: #{e.class}: #{e.message}")
        nil
      end

      def fetch_dynamic_data
        @fetch_dynamic_data ||= read_instance_identity_document
      end

      private

      def read_instance_identity_document
        path = "/#{best_api_version}/dynamic/instance-identity/document/"
        return {} if imds_unreachable?(path)

        response = http_client.get(path, { 'X-aws-ec2-metadata-token': v2_token })
        if response.code == "200"
          json_data = parse_json(response.body, {})
          if json_data.nil?
            logger.warn("Mixin Ec2Metadata: Metadata response is NOT valid JSON")
          end
          json_data
        else
          logger.warn("Mixin Ec2Metadata: Received response code #{response.code} requesting metadata")
          {}
        end
      rescue *EC2_TRANSPORT_ERRORS => e
        logger.warn("Mixin Ec2Metadata: Unable to fetch the instance identity document: #{e.class}: #{e.message}")
        {}
      end

      def imds_unreachable?(path)
        return false unless @imds_unreachable

        logger.trace("Mixin EC2: Skipping #{path}; the metadata service is unreachable")
        true
      end

      def expand_path(file_name)
        # public-keys lists its entries as "<index>=<key name>", and the index
        # is the directory to descend into. Other names can contain "=" too
        # (tag keys may), so only rewrite that exact form.
        path = file_name.sub(%r{(\A|/)(\d+)=[^/]*\z}, "\\1\\2/")

        # Handle relative path components
        path.gsub(%r{/\.\.?(?:/|$)}, "/")
          .sub(%r{^\.\.?(?:/|$)}, "")
          .sub(/^$/, "/")
      end

      # Tag keys can contain characters that aren't valid in a URL path, such
      # as the space in AWS Systems Manager's "Patch Group" tag. Escape each
      # path segment, keeping the "/" separators.
      def escape_metadata_path(id)
        id.split("/", -1).map { |segment| segment.gsub(/[^A-Za-z0-9\-._~!$&'()*+,;=:@]/) { |c| c.bytes.map { |b| format("%%%02X", b) }.join } }.join("/")
      end

      def metadata_key(key)
        key.gsub(%r{\-|/}, "_")
      end

    end
  end
end
