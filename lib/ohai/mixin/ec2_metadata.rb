#
# Author:: Tim Dysinger (<tim@dysinger.net>)
# Author:: Benjamin Black (<bb@chef.io>)
# Author:: Christopher Brown (<cb@chef.io>)
# Copyright:: 2009-2017 Chef Software, Inc.
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

      EC2_METADATA_ADDR = "169.254.169.254" unless defined?(EC2_METADATA_ADDR)
      EC2_SUPPORTED_VERSIONS = %w{ 1.0 2007-01-19 2007-03-01 2007-08-29 2007-10-10 2007-12-15
                                   2008-02-01 2008-09-01 2009-04-04 2011-01-01 2011-05-01 2012-01-12
                                   2014-02-25 2014-11-05 2015-10-20 2016-04-19 2016-06-30 2016-09-02 }
      EC2_ARRAY_VALUES = %w{security-groups}
      EC2_ARRAY_DIR    = %w{network/interfaces/macs}
      EC2_JSON_DIR     = %w{iam}

      def best_api_version
        @api_version ||= begin
          Ohai::Log.debug("ec2 metadata mixin: Fetching http://#{EC2_METADATA_ADDR}/ to determine the latest supported metadata release")
          response = http_client.get("/")
          if response.code == "404"
            Ohai::Log.debug("ec2 metadata mixin: Received HTTP 404 from metadata server while determining API version, assuming 'latest'")
            return "latest"
          elsif response.code != "200"
            raise "Unable to determine EC2 metadata version (returned #{response.code} response)"
          end
          # Note: Sorting the list of versions may have unintended consequences in
          # non-EC2 environments. It appears to be safe in EC2 as of 2013-04-12.
          versions = response.body.split("\n").sort
          until versions.empty? || EC2_SUPPORTED_VERSIONS.include?(versions.last)
            pv = versions.pop
            Ohai::Log.debug("ec2 metadata mixin: EC2 lists metadata version: #{pv} not yet supported by Ohai") unless pv == "latest"
          end
          Ohai::Log.debug("ec2 metadata mixin: Latest supported EC2 metadata version: #{versions.last}")
          if versions.empty?
            raise "Unable to determine EC2 metadata version (no supported entries found)"
          end
          versions.last
        end
      end

      def http_client
        @conn ||= Net::HTTP.start(EC2_METADATA_ADDR).tap do |h|
          h.read_timeout = 10
          h.keep_alive_timeout = 10
        end
      end

      # Get metadata for a given path and API version
      #
      # @details
      #   Typically, a 200 response is expected for valid metadata.
      #   On certain instance types, traversing the provided metadata path
      #   produces a 404 for some unknown reason. In that event, return
      #   `nil` and continue the run instead of failing it.
      def metadata_get(id, api_version)
        path = "/#{api_version}/meta-data/#{id}"
        Ohai::Log.debug("ec2 metadata mixin: Fetching http://#{EC2_METADATA_ADDR}#{path}")
        response = http_client.get(path)
        case response.code
        when "200"
          response.body
        when "404"
          Ohai::Log.debug("ec2 metadata mixin: Encountered 404 response retreiving EC2 metadata path: #{path} ; continuing.")
          nil
        else
          raise "Encountered error retrieving EC2 metadata (#{path} returned #{response.code} response)"
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
            elsif (not key.eql?(id)) && (not key.eql?("/"))
              name = key[0..-2]
              sym = metadata_key(name)
              if EC2_ARRAY_DIR.include?(name)
                metadata[sym] = fetch_dir_metadata(key, best_api_version)
              elsif EC2_JSON_DIR.include?(name)
                metadata[sym] = fetch_json_dir_metadata(key, best_api_version)
              else
                fetch_metadata(key, best_api_version).each { |k, v| metadata[k] = v }
              end
            end
          end
          metadata
        end
      end

      def fetch_dir_metadata(id, api_version)
        metadata = Hash.new
        retrieved_metadata = metadata_get(id, api_version)
        if retrieved_metadata
          retrieved_metadata.split("\n").each do |o|
            key = expand_path(o)
            if key[-1..-1] != "/"
              retr_meta = metadata_get("#{id}#{key}", api_version)
              metadata[metadata_key(key)] = retr_meta ? retr_meta : ""
            elsif not key.eql?("/")
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
              data = retr_meta ? retr_meta : ""
              json = StringIO.new(data)
              parser = FFI_Yajl::Parser.new
              metadata[metadata_key(key)] = parser.parse(json)
            elsif not key.eql?("/")
              metadata[key[0..-2]] = fetch_json_dir_metadata("#{id}#{key}", api_version)
            end
          end
          metadata
        end
      end

      def fetch_userdata
        Ohai::Log.debug("ec2 metadata mixin: Fetching http://#{EC2_METADATA_ADDR}/#{best_api_version}/user-data/")
        response = http_client.get("/#{best_api_version}/user-data/")
        response.code == "200" ? response.body : nil
      end

      def fetch_dynamic_data
        @fetch_dynamic_data ||= begin
          response = http_client.get("/#{best_api_version}/dynamic/instance-identity/document/")

          if json?(response.body) && response.code == "200"
            FFI_Yajl::Parser.parse(response.body)
          else
            {}
          end
        end
      end

      private

      def expand_path(file_name)
        path = file_name.gsub(/\=.*$/, "/")
        # ignore "./" and "../"
        path.gsub(%r{/\.\.?(?:/|$)}, "/").
          sub(%r{^\.\.?(?:/|$)}, "").
          sub(%r{^$}, "/")
      end

      def metadata_key(key)
        key.gsub(/\-|\//, "_")
      end

    end
  end
end
