#
# Author:: Tollef Fog Heen <tfheen@err.no>
# Copyright:: Copyright (c) 2010 Tollef Fog Heen
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

Ohai.plugin(:Chef) do
  provides "chef_packages/chef"

  collect_data do
    begin
      require "chef/version"
    rescue Gem::LoadError
      # this catches when you've done a major version bump of ohai, but
      # your chef gem is incompatible, so we can't load it in the same VM
      # (affects mostly internal testing)
      next
    end

    chef_packages Mash.new unless chef_packages
    chef_packages[:chef] = Mash.new
    chef_packages[:chef][:version] = Chef::VERSION
    chef_packages[:chef][:chef_root] = Chef::CHEF_ROOT
  end
end
