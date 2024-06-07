# frozen_string_literal: true
#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

Ohai.plugin(:Platform) do
  provides "platform", "platform_version", "platform_family", "platform_backend"
  depends "os", "os_version"

  collect_data(:default) do
    platform os unless attribute?("platform")
    platform_version os_version unless attribute?("platform_version")
    platform_family platform unless attribute?("platform_family")

    platform_backend Mash.new
    platform_backend["type"] = "local"
    platform_backend["uri"] = "local://"

    if connection
      platform_backend["type"] = connection.backend_type
      if connection.respond_to?(:uri)
        platform_backend["type"] = connection.uri.split(":").first
        platform_backend["uri"] = connection.uri
      end
    end
  end
end
