# frozen_string_literal: true
#
# Author:: Davide Cavalca (<dcavalca@fb.com>)
# Copyright:: Copyright (c) 2016 Facebook
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

Ohai.plugin(:Machineid) do
  provides "machine_id"

  collect_data(:linux) do
    if file_exist?("/etc/machine-id")
      mid = file_read("/etc/machine-id").chomp
    elsif file_exist?("/var/lib/dbus/machine-id")
      mid = file_read("/var/lib/dbus/machine-id").chomp
    else
      mid = nil
    end

    if mid
      machine_id mid
    end
  end
end
