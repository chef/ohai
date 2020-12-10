# frozen_string_literal: true
#
# Author:: Davide Cavalca <dcavalca@fb.com>
# Copyright:: Copyright (c) 2020 Facebook
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

Ohai.plugin(:Grub2) do
  provides "grub2/environment"
  optional true

  collect_data(:dragonflybsd, :freebsd, :linux, :netbsd) do
    editenv_path = which("grub2-editenv")
    if editenv_path
      editenv_out = shell_out("#{editenv_path} list")

      grub2 Mash.new unless grub2
      grub2[:environment] ||= Mash.new

      editenv_out.stdout.each_line do |line|
        key, val = line.split("=", 2)
        grub2[:environment][key] = val.strip
      end
    else
      logger.trace("Plugin Grub2: Could not find grub2-editenv. Skipping plugin.")
    end
  end
end
