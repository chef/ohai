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

      def fetch_metadata(id = "")
        response = http_get(id)
        if response.code == "200"
          json_data = parse_json(response.body)
          if json_data.nil?
            logger.warn("Mixin AlibabaMetadata: Metadata response is NOT valid JSON for id='#{id}'")
            if response.body.include?("\n")
              temp = {}
              response.body.split("\n").each do |sub_attr|
                temp[sanitize_key(sub_attr)] = fetch_metadata("#{id}/#{sub_attr}")
              end
              temp
            else
              response.body
            end
          else
            json_data
          end
        else
          logger.warn("Mixin AlibabaMetadata: Received response code #{response.code} requesting metadata for id='#{id}'")
          nil
        end
      end

      def sanitize_key(key)
        key.gsub(%r{\-|/}, "_")
      end
    end
  end
end
