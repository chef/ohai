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

Ohai.plugin(:Ohai) do
  provides "chef_packages/ohai"

  collect_data do
    require "ohai"

    chef_packages Mash.new unless chef_packages
    chef_packages[:ohai] = Mash.new
    chef_packages[:ohai][:version] = Ohai::VERSION
    chef_packages[:ohai][:ohai_root] = Ohai::OHAI_ROOT
  end
end
