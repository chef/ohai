# frozen_string_literal: true
#
# Author:: Ranjib Dey (<dey.ranjib@gmail.com>)
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
    module GCEMetadata

      # Trailing dot to host is added to avoid DNS search path
      GCE_METADATA_ADDR ||= "metadata.google.internal."
      GCE_METADATA_URL ||= "/computeMetadata/v1/?recursive=true"

      # fetch the meta content with a timeout and the required header
      def http_get(uri)
        conn = Net::HTTP.start(GCE_METADATA_ADDR)
        conn.read_timeout = 6
        conn.get(uri, {
                        "Metadata-Flavor" => "Google",
                        "User-Agent" => "chef-ohai/#{Ohai::VERSION}",
                      })
      end

      def fetch_metadata(id = "")
        response = http_get("#{GCE_METADATA_URL}/#{id}")
        if response.code == "200"
          json_data = parse_json(response.body)
          if json_data.nil?
            logger.warn("Mixin GCEMetadata: Metadata response is NOT valid JSON for id='#{id}'")
            if has_trailing_slash?(id) || (id == "")
              temp = {}
              response.body.split("\n").each do |sub_attr|
                temp[sanitize_key(sub_attr)] = fetch_metadata("#{id}#{sub_attr}")
              end
              temp
            else
              response.body
            end
          else
            json_data
          end
        else
          logger.warn("Mixin GCEMetadata: Received response code #{response.code} requesting metadata for id='#{id}'")
          nil
        end
      end

      # @param data [String]
      #
      # @return [Boolean] is there a trailing /?
      def has_trailing_slash?(data)
        !!( data =~ %r{/$} )
      end

      def sanitize_key(key)
        key.gsub(%r{\-|/}, "_")
      end
    end
  end
end
