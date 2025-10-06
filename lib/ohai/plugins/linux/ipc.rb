# frozen_string_literal: true
#
# Contributed by: Jay Vana <jsvana@fb.com>
# Contributed by: Davide Cavalca <dcavalca@fb.com>
# Copyright © 2008-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

Ohai.plugin(:IPC) do
  provides "ipc"
  optional true

  collect_data(:linux) do
    ipcs_path = which("ipcs")
    if ipcs_path
      # NOTE: currently only supports shared memory
      cmd = "#{ipcs_path} -m"
      ipcs = shell_out(cmd)

      ipc Mash.new unless ipc
      ipc["shm"] = Mash.new unless ipc["shm"]

      ipcs.stdout.split("\n").each do |line|
        next unless line.start_with?("0x")

        parts = line.split
        segment = {
          "key" => parts[0],
          "owner" => parts[2],
          "perms" => parts[3],
          "bytes" => parts[4].to_i,
          "nattch" => parts[5].to_i,
          "status" => parts[6] || "",
        }

        ipc["shm"][parts[1].to_i] = segment
      end
    end
  end
end
