#
# Author:: Matt Ray (<matt@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'ohai/mixin/ec2_metadata'

Ohai.plugin(:Openstack) do
  provides "openstack"

  include Ohai::Mixin::Ec2Metadata

  def collect_openstack_metadata(addr = Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR, api_version = '2013-04-04')
    path = "/openstack/#{api_version}/meta_data.json"
    uri = "http://#{addr}#{path}"
    begin
      response = http_client.get_response(URI.parse(uri),nil,nil)
      case response.code
      when '200'
        FFI_Yajl::Parser.parse(response.body)
      when '404'
        Ohai::Log.debug("Encountered 404 response retreiving OpenStack specific metadata path: #{path} ; continuing.")
        nil
      else
        raise "Encountered error retrieving OpenStack specific metadata (#{path} returned #{response.code} response)"
      end
    rescue => e
      Ohai::Log.debug("Encountered error retrieving OpenStack specific metadata (#{uri}), due to #{e.class}")
      nil
    end
  end

  collect_data do
    # Adds openstack Mash
    if hint?('openstack') || hint?('hp')
      Ohai::Log.debug("ohai openstack")

      if can_metadata_connect?(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR,80)
        openstack Mash.new
        Ohai::Log.debug("connecting to the OpenStack metadata service")
        fetch_metadata.each {|k, v| openstack[k] = v }

        if hint?('hp')
          openstack['provider'] = 'hp'
        else
          openstack['provider'] = 'openstack'
          Ohai::Log.debug("connecting to the OpenStack specific metadata service")
          openstack['metadata'] = collect_openstack_metadata
        end

      else
        Ohai::Log.debug("unable to connect to the OpenStack metadata service")
      end
    else
      Ohai::Log.debug("NOT ohai openstack")
    end
  end
end
