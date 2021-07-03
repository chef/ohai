# frozen_string_literal: true
#
# Author:: Song Liu <song@kernel.org>
# Copyright:: Copyright (c) 2021 Facebook, Inc.
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

Ohai.plugin(:Livepatch) do
  provides "livepatch"

  collect_data(:linux) do
    if file_exist?("/sys/kernel/livepatch")
      patches = Mash.new
      dir_glob("/sys/kernel/livepatch/*").each do |livepatch_dir|
        dir = File.basename(livepatch_dir)
        patches[dir] = Mash.new
        %w{enabled transition}.each do |check|
          if file_exist?("/sys/kernel/livepatch/#{dir}/#{check}")
            file_open("/sys/kernel/livepatch/#{dir}/#{check}") { |f| patches[dir][check] = f.read_nonblock(1024).strip }
          end
        end
        livepatch patches
      end
    end
  end
end
