#
# Author:: Olle Lundberg (<geek@nerd.sh>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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

require 'ohai/mixin/cloudstack_metadata'

Ohai.plugin(:Cloudstack) do
  provides "cloudstack"

  include Ohai::Mixin::CloudstackMetadata

  collect_data do
    # Adds cloudstack Mash
    if hint?('cloudstack')
      Ohai::Log.debug("found 'cloudstack' hint. Will try to connect to the metadata server")

      if can_metadata_connect?(Ohai::Mixin::CloudstackMetadata::CLOUDSTACK_METADATA_ADDR, 80)
        cloudstack Mash.new
        Ohai::Log.debug("connecting to the 'cloudstack' metadata service")
        fetch_metadata.each { |k, v| cloudstack[k] = v }
      else
        Ohai::Log.debug("unable to connect to the 'cloudstack' metadata service")
      end
    else
      Ohai::Log.debug("unable to find 'cloudstack' hint. Won't connect to the metadata server.")
    end
  end
end


