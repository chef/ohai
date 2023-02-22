# frozen_string_literal: true
#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

Ohai.plugin(:BlockDevice) do
  provides "block_device"

  collect_data(:linux) do
    if file_exist?("/sys/block")
      block = Mash.new
      dir_glob("/sys/block/*").each do |block_device_dir|
        dir = File.basename(block_device_dir)
        block[dir] = Mash.new
        %w{size removable}.each do |check|
          if file_exist?("/sys/block/#{dir}/#{check}")
            file_open("/sys/block/#{dir}/#{check}") { |f| block[dir][check] = f.read_nonblock(1024).strip }
          end
        end
        %w{model rev state timeout vendor queue_depth firmware_rev}.each do |check|
          if file_exist?("/sys/block/#{dir}/device/#{check}")
            file_open("/sys/block/#{dir}/device/#{check}") { |f| block[dir][check] = f.read_nonblock(1024).strip }
          end
        end
        %w{rotational physical_block_size logical_block_size}.each do |check|
          if file_exist?("/sys/block/#{dir}/queue/#{check}")
            file_open("/sys/block/#{dir}/queue/#{check}") { |f| block[dir][check] = f.read_nonblock(1024).strip }
          end
        end
      end
      block_device block
    end
  end
end
