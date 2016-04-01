#
# Author:: Dylan Page (<dpage@digitalocean.com>)
# Author:: Stafford Brunk (<stafford.brunk@gmail.com>)
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

require 'ohai/mixin/do_metadata'
require 'yaml'

Ohai.plugin(:DigitalOcean) do
  include Ohai::Mixin::DOMetadata

  DO_CLOUD_INIT_FILE = "/etc/cloud/cloud.cfg" unless defined?(DO_CLOUD_INIT_FILE)

  provides "digital_ocean"

  depends "network/interfaces"

  def has_do_init?
    if File.exist?(DO_CLOUD_INIT_FILE)
      datasource = YAML.load_file(DO_CLOUD_INIT_FILE)
      if datasource['datasource_list'].include?("DigitalOcean")
        Ohai::Log.debug("digital_ocean plugin: has_do_init? == true")
        true
      end
    else
      Ohai::Log.debug("digital_ocean plugin: has_do_init? == false")
      false
    end
  end

  def looks_like_digital_ocean?
    return true if hint?("digital_ocean")

    if has_do_init?
     return true if can_metadata_connect?(Ohai::Mixin::DOMetadata::DO_METADATA_ADDR,80)
    end
  end

  collect_data do
    if looks_like_digital_ocean?
      Ohai::Log.debug("looks_like_digital_ocean? == true")
      digital_ocean Mash.new
      fetch_metadata.each do |k, v|
        digital_ocean[k] = v
      end
    else
      Ohai::Log.debug("digitalocean plugin: No hints present for and doesn't look like digitalocean")
      false
    end
  end
end
