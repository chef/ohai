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

require "json"
require "net/http"

# Answers a cloud plugin's metadata requests with responses recorded on a
# real instance (spec/data/cloud_metadata), so a spec runs the plugin's own
# HTTP, token, version-probe and parsing code against what the service
# actually returns. Identifiers in the recordings are replaced with
# documentation values.
#
# API versions are masked when matching requests: metadata services return
# the same document for every version they support, and this keeps a
# recording valid when Ohai moves to a newer version.
module MetadataReplay
  FIXTURE_DIR = File.expand_path("../data/cloud_metadata", __dir__)

  # @param name [String] a recording in spec/data/cloud_metadata
  # @return [Array<Hash>] the recorded exchanges
  def replay_metadata(name)
    exchanges = JSON.parse(File.read(File.join(FIXTURE_DIR, "#{name}.json")))
    @replayed_requests = []
    allow_any_instance_of(Net::HTTP).to receive(:connect)
    # Net::HTTP#get and friends pass a block and take the response from it
    allow_any_instance_of(Net::HTTP).to receive(:request) do |http, request, *, &block|
      @replayed_requests << { method: request.method, address: http.address, path: request.path, headers: request.to_hash }
      exchange = exchanges.find do |e|
        e["method"] == request.method && e["address"] == http.address && mask_api_version(e["path"]) == mask_api_version(request.path)
      end
      raise "no recorded response for #{request.method} http://#{http.address}#{request.path}" unless exchange

      response = recorded_response(exchange)
      block&.call(response)
      response
    end
    exchanges
  end

  # @return [Array<Hash>] the requests the plugin made, in order, with
  #   :method, :address, :path and :headers (lowercase names, array values)
  def replayed_requests
    @replayed_requests || []
  end

  private

  def mask_api_version(path)
    path.gsub(%r{/\d{4}-\d{2}-\d{2}(?=/)}, "/VERSION").sub(/api-version=[\d-]+/, "api-version=VERSION")
  end

  def recorded_response(exchange)
    response = Net::HTTPResponse::CODE_TO_OBJ.fetch(exchange["status"], Net::HTTPUnknownResponse).new("1.1", exchange["status"], "")
    response["content-type"] = exchange["content_type"] if exchange["content_type"]
    response.instance_variable_set(:@body, exchange["body"])
    response.instance_variable_set(:@read, true)
    response
  end
end

RSpec.configure do |config|
  config.include MetadataReplay
end
