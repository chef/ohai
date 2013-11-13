# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

Ohai.plugin(:Azure) do
  provides "azure"

  collect_data do
    # The azure hints are populated by the knife plugin for Azure.
    # The project is located at https://github.com/opscode/knife-azure
    # Please see the lib/chef/knife/azure_server_create.rb file in that
    # project for details
    azure_metadata_from_hints = hint?('azure')
    if azure_metadata_from_hints
      Ohai::Log.debug("azure_metadata_from_hints is present.")
      azure Mash.new
      azure_metadata_from_hints.each {|k, v| azure[k] = v }
    else
      Ohai::Log.debug("No hints present for azure.")
      false
    end
  end
end
