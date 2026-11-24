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

      # The metadata server's link-local address. Google documents it as an
      # alternative to metadata.google.internal, and using it avoids a DNS
      # lookup that fails when the instance uses its own resolvers.
      GCE_METADATA_ADDR ||= "169.254.169.254"
      # the metadata server answers 503 while it is temporarily unavailable,
      # for example during a host maintenance event
      GCE_RETRY_CODES ||= %w{503}.freeze
      GCE_MAX_ATTEMPTS ||= 3
      GCE_METADATA_URL ||= "/computeMetadata/v1"

      # fetch the meta content with a timeout and the required header
      def http_get(uri)
        # Connect directly: the metadata service is link-local, so the nil proxy
        # address keeps Net::HTTP from using http_proxy from the environment,
        # and open_timeout replaces Net::HTTP's 60 second default.
        conn = Net::HTTP.start(GCE_METADATA_ADDR, 80, nil, open_timeout: 3)
        conn.read_timeout = 6
        conn.get(uri, {
                        "Metadata-Flavor" => "Google",
                        "User-Agent" => "chef-ohai/#{Ohai::VERSION}",
                      })
      end

      def fetch_metadata(id = "")
        url = "#{GCE_METADATA_URL}/#{id}"
        url = "#{url}?recursive=true" if url.end_with?("/")
        response = http_get_with_retry(url)
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

      # http_get, retrying the responses the metadata server documents as
      # transient
      #
      # @return [Net::HTTPResponse] the last response
      def http_get_with_retry(uri)
        attempt = 0
        loop do
          attempt += 1
          response = http_get(uri)
          return response unless GCE_RETRY_CODES.include?(response.code) && attempt < GCE_MAX_ATTEMPTS

          logger.trace("Mixin GCEMetadata: Received HTTP #{response.code} for #{uri}, retrying")
          sleep(attempt)
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
