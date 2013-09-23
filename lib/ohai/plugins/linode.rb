#
# Author:: Aaron Kalin (<akalin@martinisoftware.com>)
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

provides "linode"

require_plugin "kernel"
require_plugin "network"

# Checks for matching linode kernel name
#
# Returns true or false
def has_linode_kernel?
  kernel[:release].split('-').last =~ /linode/
end

# Identifies the linode cloud by preferring the hint, then
#
# Returns true or false
def looks_like_linode?
  hint?('linode') || has_linode_kernel?
end

# Names linode ip address
#
# name - symbol of ohai name (e.g. :public_ip)
# eth - Interface name (e.g. :eth0)
#
# Alters linode mash with new interface based on name parameter
def get_ip_address(name, eth)
  network[:interfaces][eth][:addresses].each do |key, info|
    linode[name] = key if info['family'] == 'inet'
  end
end

# Setup linode mash if it is a linode system
if looks_like_linode?
  linode Mash.new
  get_ip_address(:public_ip, :eth0)
  get_ip_address(:private_ip, "eth0:1")
end
