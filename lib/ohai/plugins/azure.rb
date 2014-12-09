# Author:: Alexey Karpik <alexey.karpik@rightscale.com>
# Author:: Peter Schroeter <peter.schroeter@rightscale.com>
# Author:: Stas Turlo <stanislav.turlo@rightscale.com>
# Copyright:: Copyright (c) 2010-2014 RightScale Inc
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

require 'ohai/mixin/azure_metadata'

Ohai.plugin(:Azure) do
  provides "azure"

  include ::Ohai::Mixin::AzureMetadata


  # Identifies the azure cloud
  #
  # === Return
  # true:: If the azure cloud can be identified
  # false:: Otherwise
  def looks_like_azure?
    !!hint?('azure')
  end

  collect_data do
    if looks_like_azure?
      ::Ohai::Log.debug("looks_like_azure? == true")
      metadata = fetch_azure_metadata
      azure Mash.new
      if metadata
        metadata.each { |k,v| azure[k] = v }
      end
    end
  end
end
