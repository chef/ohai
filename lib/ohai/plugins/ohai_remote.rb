#
# Author:: Thomas Heinen <theinen@tecracer.de>
# Copyright:: Copyright (c) 2020 tecRacer Consulting.
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

Ohai.plugin(:OhaiRemote) do
  provides "ohai_remote"

  collect_data(:meta) do
    if remote_ohai?
      logger.trace("Plugin Ohai Remote: remote_ohai? == true")
      ohai_remote Mash.new

      ohai_remote['backend'] = connection.backend_type
      if connection.respond_to? :uri
        ohai_remote['backend'] = connection.uri.split(':').first
        ohai_remote['uri'] = connection.uri
      end
    else
      logger.trace("Plugin Ohai Remote: remote_ohai? == false")
    end
  end
end
