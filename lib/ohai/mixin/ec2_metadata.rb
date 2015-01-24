#
# Author:: Tim Dysinger (<tim@dysinger.net>)
# Author:: Benjamin Black (<bb@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'net/http'
require 'socket'

require 'ohai/util/socket_helper'

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
      include Ohai::Util::SocketHelper

      EC2_METADATA_ADDR = "169.254.169.254" unless defined?(EC2_METADATA_ADDR)
      EC2_SUPPORTED_VERSIONS = %w[ 1.0 2007-01-19 2007-03-01 2007-08-29 2007-10-10 2007-12-15
                                   2008-02-01 2008-09-01 2009-04-04 2011-01-01 2011-05-01 2012-01-12 ]

      EC2_ARRAY_VALUES = %w(security-groups)
      EC2_ARRAY_DIR    = %w(network/interfaces/macs)
      EC2_JSON_DIR     = %w(iam)

      def can_metadata_connect?(host, port, timeout = 2)
        connected = tcp_port_open?(host, port, timeout)
        Ohai::Log.debug("can_metadata_connect? == #{connected}")
        connected
      end

      def best_api_version
        response = http_client.get("/")
        if response.code == '404'
          Ohai::Log.debug("Received HTTP 404 from metadata server while determining API version, assuming 'latest'")
          return "latest"
        elsif response.code != '200'
          raise "Unable to determine EC2 metadata version (returned #{response.code} response)"
        end
        # Note: Sorting the list of versions may have unintended consequences in
        # non-EC2 environments. It appears to be safe in EC2 as of 2013-04-12.
        versions = response.body.split("\n")
        versions = response.body.split("\n").sort
        until (versions.empty? || EC2_SUPPORTED_VERSIONS.include?(versions.last)) do
          pv = versions.pop
          Ohai::Log.debug("EC2 shows unsupported metadata version: #{pv}") unless pv == 'latest'
        end
        Ohai::Log.debug("EC2 metadata version: #{versions.last}")
        if versions.empty?
          raise "Unable to determine EC2 metadata version (no supported entries found)"
        end
        versions.last
      end

      def http_client
        Net::HTTP.start(EC2_METADATA_ADDR).tap {|h| h.read_timeout = 600}
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
        response = http_client.get(path)
        case response.code
        when '200'
          response.body
        when '404'
          Ohai::Log.debug("Encountered 404 response retreiving EC2 metadata path: #{path} ; continuing.")
          nil
        else
          raise "Encountered error retrieving EC2 metadata (#{path} returned #{response.code} response)"
        end
      end

      def fetch_metadata(id='', api_version=nil)
        api_version ||= best_api_version
        return Hash.new if api_version.nil?

        metadata = Hash.new
        retrieved_metadata = metadata_get(id, api_version)
        if retrieved_metadata
          retrieved_metadata.split("\n").each do |o|
            key = expand_path("#{id}#{o}")
            if key[-1..-1] != '/'
              metadata[metadata_key(key)] =
                if EC2_ARRAY_VALUES.include? key
                  retr_meta = metadata_get(key, api_version)
                  retr_meta ? retr_meta.split("\n") : retr_meta
                else
                  metadata_get(key, api_version)
                end
            elsif not key.eql?(id) and not key.eql?('/')
              name = key[0..-2]
              sym = metadata_key(name)
              if EC2_ARRAY_DIR.include?(name)
                metadata[sym] = fetch_dir_metadata(key, api_version)
              elsif EC2_JSON_DIR.include?(name)
                metadata[sym] = fetch_json_dir_metadata(key, api_version)
              else
                fetch_metadata(key, api_version).each{|k,v| metadata[k] = v}
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
            if key[-1..-1] != '/'
              retr_meta = metadata_get("#{id}#{key}", api_version)
              metadata[metadata_key(key)] = retr_meta ? retr_meta : ''
            elsif not key.eql?('/')
              metadata[key[0..-2]] = fetch_dir_metadata("#{id}#{key}", api_version)
            end
          end
          metadata
        end
      end

      def fetch_json_dir_metadata(id, api_version)
        metadata = Hash.new
        retrieved_metadata = metadata_get(id, api_version)
        if retrieved_metadata
          retrieved_metadata.split("\n").each do |o|
            key = expand_path(o)
            if key[-1..-1] != '/'
              retr_meta = metadata_get("#{id}#{key}", api_version)
              data = retr_meta ? retr_meta : ''
              json = StringIO.new(data)
              parser = FFI_Yajl::Parser.new
              metadata[metadata_key(key)] = parser.parse(json)
            elsif not key.eql?('/')
              metadata[key[0..-2]] = fetch_json_dir_metadata("#{id}#{key}", api_version)
            end
          end
          metadata
        end
      end

      def fetch_userdata()
        api_version = best_api_version
        return nil if api_version.nil?
        response = http_client.get("/#{api_version}/user-data/")
        response.code == "200" ? response.body : nil
      end

      private

      def expand_path(file_name)
        path = file_name.gsub(/\=.*$/, '/')
        # ignore "./" and "../"
        path.gsub(%r{/\.\.?(?:/|$)}, '/').
          sub(%r{^\.\.?(?:/|$)}, '').
          sub(%r{^$}, '/')
      end

      def metadata_key(key)
        key.gsub(/\-|\//, '_')
      end

    end
  end
end
