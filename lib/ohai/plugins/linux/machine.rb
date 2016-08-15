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

Ohai.plugin(:Machine) do
  provides "machine"

  collect_data(:linux) do
    machine Mash.new unless machine

    hostnamectl_path = which("hostnamectl")
    if hostnamectl_path
      hostnamectl = shell_out(hostnamectl_path)
      hostnamectl.stdout.split("\n").each do |line|
        key, val = line.split(":")
        machine[key.chomp.lstrip.tr(" ", "_").downcase] = val.chomp.lstrip
      end
    else
      if File.exists?("/etc/machine-id")
        machine["machine_id"] = File.read("/etc/machine-id").chomp
      elsif File.exists?("/var/lib/dbus/machine-id")
        machine["machine_id"] = File.read("/var/lib/dbus/machine-id").chomp
      end
      if File.exists?("/etc/machine-info")
        File.read("/etc/machine-info").split("\n").each do |line|
          key, val = line.split("=")
          machine[key.downcase] = val.chomp.delete("\"")
        end
      end
    end
  end
end
