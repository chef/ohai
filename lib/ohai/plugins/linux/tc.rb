#
# Author:: Matthew Massey <matthewmassey@fb.com>
# Copyright:: Copyright (c) 2021 Facebook
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

Ohai.plugin(:Tc) do
  provides "tc"
  optional true

  collect_data(:linux) do
    tc_path = which("tc")
    if tc_path
      cmd = "#{tc_path} qdisc show"
      tc_output = shell_out(cmd)

      tc_data = Mash.new
      tc_data[:qdisc] = Mash.new

      tc_output.stdout.split("\n").each do |line|
        line = line.strip
        if /dev (\w+)/ =~ line
          dev = $1
          tc_data[:qdisc][dev] ||= Mash.new
        else
          next
        end
        if /qdisc (\w+)/ =~ line
          qdisc = $1
          tc_data[:qdisc][dev][:qdiscs] ||= []
          tc_data[:qdisc][dev][:qdiscs] << Mash.new
          qdisc_idx = tc_data[:qdisc][dev][:qdiscs].length - 1
          tc_data[:qdisc][dev][:qdiscs][qdisc_idx] ||= Mash.new
          tc_data[:qdisc][dev][:qdiscs][qdisc_idx][:type] = qdisc
          tc_data[:qdisc][dev][:qdiscs][qdisc_idx][:parms] ||= Mash.new
        else
          next
        end
        if qdisc == "fq" && /buckets (\d+)/ =~ line
          buckets = $1.to_i
          tc_data[:qdisc][dev][:qdiscs][qdisc_idx][:parms][:buckets] = buckets
        end
      end
      tc tc_data
    else
      logger.trace("Plugin Tc: Could not find tc. Skipping plugin.")
    end
  end
end
