#
# Author:: Phil Dibowitz <phil@ipom.com>
# Copyright:: Copyright (c) 2018 Facebook, Inc.
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

Ohai.plugin(:Lsscsi) do
  depends "platform"
  provides "scsi"
  optional true

  require "mixlib/shellout" unless defined?(Mixlib::ShellOut::DEFAULT_READ_TIMEOUT)

  collect_data(:linux) do
    devices = Mash.new
    lsscsi = shell_out("lsscsi")

    lsscsi.stdout.each_line do |line|
      line_bits = line.split
      info = {}

      # The first three fields are consistent...
      info["scsi_addr"] = line_bits.shift[1..-2]
      info["type"] = line_bits.shift
      info["transport"] = line_bits.shift

      # After that the last two are consistent...
      info["device"] = line_bits.pop
      info["revision"] = line_bits.pop

      # What"s in the middle is the make and model...
      # which could have arbitrary spaces
      info["name"] = line_bits.join(" ")

      devices[info["scsi_addr"]] = info
    end

    scsi devices
  end
end
