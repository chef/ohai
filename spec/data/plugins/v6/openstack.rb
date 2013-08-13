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

provides "openstack"

require 'ohai/mixin/ec2_metadata'

extend Ohai::Mixin::Ec2Metadata

# does it matter that it's not hitting latest?
#Ec2Metadata::EC2_METADATA_URL = "/latest/meta-data"

# Adds openstack Mash
if hint?('openstack') || hint?('hp')
  Ohai::Log.debug("ohai openstack")
  openstack Mash.new
  #for now, use the metadata service
  if can_metadata_connect?(EC2_METADATA_ADDR,80)
    Ohai::Log.debug("connecting to the OpenStack metadata service")
    self.fetch_metadata.each {|k, v| openstack[k] = v }
    case
    when hint?('hp')
      openstack['provider'] = 'hp'
    else
      openstack['provider'] = 'openstack'
    end
  else
    Ohai::Log.debug("unable to connect to the OpenStack metadata service")
  end
else
  Ohai::Log.debug("NOT ohai openstack")
end
