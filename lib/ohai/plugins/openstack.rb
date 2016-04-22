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

require "ohai/mixin/ec2_metadata"

Ohai.plugin(:Openstack) do
  include Ohai::Mixin::Ec2Metadata

  provides "openstack"
  depends "dmi"

  # do we have the openstack dmi data
  def openstack_dmi?
    # detect a manufacturer of OpenStack Foundation
    if dmi[:system][:all_records][0][:Manufacturer] =~ /OpenStack/
      Ohai::Log.debug("Plugin Openstack: has_openstack_dmi? == true")
      true
    end
  rescue NoMethodError
    Ohai::Log.debug("Plugin Openstack: has_openstack_dmi? == false")
    false
  end

  # check for the ohai hint and log debug messaging
  def openstack_hint?
    if hint?("openstack")
      Ohai::Log.debug("Plugin Openstack: openstack hint present")
      return true
    else
      Ohai::Log.debug("Plugin Openstack: openstack hint not present")
      return false
    end
  end

  def collect_openstack_metadata(addr, api_version)
    require "net/http"
    require "json"

    Timeout.timeout(3) do
      path = "/openstack/#{api_version}/meta_data.json"
      uri = URI.parse("http://#{addr}/#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      if response.code.to_i == 404
        Ohai::Log.warn("Plugin Openstack: encountered 404 response retreiving OpenStack specific metadata path: #{path} ; continuing.")
        return nil
      elsif response.code.to_i != 200
        Ohai::Log.warn("Plugin Openstack: encountered error retrieving OpenStack specific metadata (#{path} returned #{response.code} response)")
        return nil
      else
        data = JSON(response.body)
        return data
      end
    end
  rescue Timeout::Error
    Ohai::Log.warn("Plugin Openstack: Timeout connecting to OpenStack metadata service.")
    nil
  rescue Errno::ECONNRESET, EOFError, Errno::EHOSTDOWN => e
    Ohai::Log.error("Plugin Openstack: Error retrieving node information from Openstack: #{e}")
    nil
  end

  collect_data(:default) do
    # Adds openstack Mash
    if openstack_hint? || openstack_dmi?
      openstack Mash.new
      openstack[:provider] = "openstack"
      if can_metadata_connect?("169.254.169.254", 80)
        data = collect_openstack_metadata("169.254.169.254", "latest")
        openstack[:metadata] = Mash.new
        data.each do |k, v|
          openstack[:metadata][k] = v
        end
      end
    end
  end
end
