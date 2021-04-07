# frozen_string_literal: true
#
# Author:: Lance Albertson (lance@osuosl.org>)
# Copyright:: Copyright (c) 2021 Oregon State University
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

Ohai.plugin(:OsRelease) do
  provides "os_release"

  collect_data(:linux) do
    os_release Mash.new unless os_release

    # https://www.freedesktop.org/software/systemd/man/os-release.html
    if file_exist?("/etc/os-release")
      file_read("/etc/os-release").each_line do |line|
        key, value = line.split("=")
        if key == "ID_LIKE"
          os_release[key.downcase] = value.chomp.gsub(/\A"|"\Z/, "").split(" ") if value
        else
          os_release[key.downcase] = value.chomp.gsub(/\A"|"\Z/, "") if value
        end
      end
    end
  end
end
