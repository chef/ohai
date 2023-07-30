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
    # This code parses the Alibaba Instance Metadata API to provide details
    # of the running instance.
    #
    # Note: As of 2021-02-07 there is only one API release so we're not implementing
    # logic like the ec2 or azure mixins where we have to find the latest supported
    # release
    module AlibabaMetadata

      ALI_METADATA_ADDR ||= "100.100.100.200"

      def http_get(uri)
        conn = Net::HTTP.start(ALI_METADATA_ADDR)
        conn.read_timeout = 6
        conn.keep_alive_timeout = 6
        conn.get("/2016-01-01/#{uri}", { "User-Agent" => "chef-ohai/#{Ohai::VERSION}" })
      end

      def fetch_metadata(id = "", is_directory = true)
        response = http_get(id)
        if response.code == "200"

          if !is_directory
            json_data = parse_json(response.body)
            if json_data.nil?
              response.body
            else
              json_data
            end
          elsif is_directory
            temp = {}
            response.body.split("\n").each do |sub_attr|
              if "#{id}/#{sub_attr}" != "/user-data"
                uri = id == "" ? "#{id}#{sub_attr}/" : "#{id}#{sub_attr}"
                temp[sanitize_key(sub_attr).gsub(/_$/, "")] = fetch_metadata(uri, has_trailing_slash?(uri))
              end
            end
            temp
          end
        else
          logger.warn("Mixin AlibabaMetadata: Received response code #{response.code} requesting metadata for id='#{id}'")
          nil
        end
      end

      # @param data [String]
      #
      # @return [Boolean] is there a trailing /?
      def has_trailing_slash?(data)
        !!(data =~ %r{/$})
      end

      def sanitize_key(key)
        key.gsub(%r{\-|/}, "_")
      end
    end
  end
end
