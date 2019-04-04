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
    # welcome to a quick implementation that gets the job done.

    # Try and find chef. If it results in returning us chef its not on the path
    # So we want to look for it in the usual install locations.
    chef_client_bin = which('chef-client') 
    if chef_client_bin == 'chef-client'
      if file_exist?('/opt/chef/bin/chef-client')
        chef_client_bin = '/opt/chef/bin/chef-client'
      elsif file_exist?('/opt/chefdk/bin/chef-client')
        chef_client_bin = '/opt/chefdk/bin/chef-client'
      end
    end

    if chef_client_bin != 'chef-client'
      chef_app_name, version = shell_out("#{chef_client_bin} --version").stdout.chomp.split(' ')

      chef_packages Mash.new unless chef_packages
      chef_packages[:chef] = Mash.new
      chef_packages[:chef][:version] = version

      # There is an assumption that it exists somewhere within this directory.
      # There could multiple and I'm not sure which one would be prefered. I honestly would
      # just put them all into the value here in an array.
      chef_root = shell_out("find /opt -path '*/chef-#{version}/lib'").stdout.chomp.lines.first
      chef_packages[:chef][:chefroot] = chef_root
    end
  end
end
