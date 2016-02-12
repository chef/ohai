#
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

Ohai.plugin(:Memory) do
  provides "memory"

  collect_data(:solaris2) do
    memory Mash.new
    memory[:swap] = Mash.new
    meminfo = shell_out("prtconf | grep Memory").stdout
    memory[:total] = "#{meminfo.split[2].to_i * 1024}kB"

    tokens = shell_out("swap -s").stdout.strip.split
    used_swap = tokens[8][0..-1].to_i #strip k from end
    free_swap = tokens[10][0..-1].to_i #strip k from end
    memory[:swap][:total] = "#{used_swap + free_swap}kB"
    memory[:swap][:free] = "#{free_swap}kB"
  end
end
