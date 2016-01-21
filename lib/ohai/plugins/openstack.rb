#
# Author:: Anthony Caiafa (<acaiafa1@bloomberg.net>)
# Copyright 2015-2016, Bloomberg Finance L.P.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Ohai.plugin(:Openstack) do
  provides "openstack"

  def collect_openstack_metadata(addr, api_version)
    require "net/http"
    require "json"

    Timeout.timeout(5) do
      path = "/openstack/#{api_version}/meta_data.json"
      uri = URI.parse("http://#{addr}/#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      if response.code.to_i == 404
        Ohai::Log.warn("Encountered 404 response retreiving OpenStack specific metadata path: #{path} ; continuing.")
        return nil
      elsif response.code.to_i != 200
        Ohai::Log.warn("Encountered error retrieving OpenStack specific metadata (#{path} returned #{response.code} response)")
        return nil
      else
        data = JSON(response.body)
        return data
      end
    end
  rescue Timeout::Error
    Ohai::Log.warn("Timeout connecting to OpenStack metadata service.")
    nil
  rescue Exception => e
    Ohai::Log.error("Error retrieving node information from Openstack: #{e}")
  end

  collect_data(:default) do
    openstack Mash.new
    data =  collect_openstack_metadata('169.254.169.254', 'latest')
    openstack[:metadata] = Mash.new
    data.each do |k, v|
      openstack[:metadata][k] = v
    end
  end
end
