#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

Ohai.plugin do
  provides "kernel"

  collect_data do
    so = shell_out("uname -o")
    kernel[:os] = so.stdout.split($/)[0]

    kext = Mash.new
    so = shell_out("env lsmod")
    so.stdout.lines do |line|
      if line =~ /([a-zA-Z0-9\_]+)\s+(\d+)\s+(\d+)/
        kext[$1] = { :size => $2, :refcount => $3 }
      end
    end

    kernel[:modules] = kext
  end
end
