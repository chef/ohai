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
    shell_out("sysctl -a").stdout.lines.each do |line|
      case line
      when /^hw.packages: (.*)$/
        cpu[:real] = Regexp.last_match[1].to_i
      when /^hw.physicalcpu: (.*)$/
        cpu[:cores] = Regexp.last_match[1].to_i
      when /^hw.logicalcpu: (.*)$/
        cpu[:total] = Regexp.last_match[1].to_i
      when /^hw.cpufrequency: (.*)$/
        cpu[:mhz] = Regexp.last_match[1].to_i / 1000000
      when /^machdep.cpu.vendor: (.*)$/
        cpu[:vendor_id] = Regexp.last_match[1].chomp
      when /^machdep.cpu.brand_string: (.*)$/
        cpu[:model_name] = Regexp.last_match[1].chomp
      when /^machdep.cpu.model: (.*)$/
        cpu[:model] = Regexp.last_match[1].to_i
      when /^machdep.cpu.family: (.*)$/
        cpu[:family] = Regexp.last_match[1].to_i
      when /^machdep.cpu.stepping: (.*)$/
        cpu[:stepping] = Regexp.last_match[1].to_i
      when /^machdep.cpu.features: (.*)$/
        cpu[:flags] = Regexp.last_match[1].downcase.split(" ")
      end
    end
  end
end
