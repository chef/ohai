#
# Author:: Nathan L Smith (<nlloyds@gmail.com>)
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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

Ohai.plugin(:CPU) do
  provides "cpu"

  collect_data(:darwin) do
    cpu Mash.new
    so = shell_out("sysctl -n hw.packages")
    cpu[:real] = so.stdout.to_i
    so = shell_out("sysctl -n hw.physicalcpu")
    cpu[:cores] = so.stdout.to_i
    so = shell_out("sysctl -n hw.logicalcpu")
    cpu[:total] = so.stdout.to_i
    so = shell_out("sysctl -n hw.cpufrequency")
    cpu[:mhz] = so.stdout.to_i / 1000000
    so = shell_out("sysctl -n machdep.cpu.vendor")
    cpu[:vendor_id] = so.stdout.chomp
    so = shell_out("sysctl -n machdep.cpu.brand_string")
    cpu[:model_name] = so.stdout.chomp
    so = shell_out("sysctl -n machdep.cpu.model")
    cpu[:model] = so.stdout.to_i
    so = shell_out("sysctl -n machdep.cpu.family")
    cpu[:family] = so.stdout.to_i
    so = shell_out("sysctl -n machdep.cpu.stepping")
    cpu[:stepping] = so.stdout.to_i
    so = shell_out("sysctl -n machdep.cpu.features")
    cpu[:flags] = so.stdout.downcase.split(" ")
  end
end
