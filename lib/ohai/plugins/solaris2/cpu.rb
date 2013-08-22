#
# Author:: Lamont Granquist (<adam@opscode.com>)
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

Ohai.plugin do
  provides "cpu"

  collect_data do
    chip_ids = Hash.new
    core_ids = Hash.new

    chip_num = 0
    core_num = 0
    vcpu_num = 0

    popen4("kstat cpu_info") do |pid, stdin, stdout, stderr|
      stdin.close
      stdout.each do |line|
        case
        when line =~ /chip_id\s+(\S+)/
          chip_ids[$1] = true
        when line =~ /core_id\s+(\S+)/
          core_ids[$1] = true
        when line =~ /^module: cpu_info/
          vcpu_num += 1
        end
      end
    end

    cpu Mash.new

    # solaris vcpus are like hyperthreads in intel-land
    cpu[:total] = vcpu_num
    # cores are cores
    cpu[:real] = core_ids.keys.length
  end
end
