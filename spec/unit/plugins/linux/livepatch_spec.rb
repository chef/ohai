#
#  Author:: Song Liu <song@kernel.org>
#  Copyright:: Copyright (c) 2021 Facebook, Inc.
#  License:: Apache License, Version 2.0
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

require "spec_helper"

describe Ohai::System, "Linux Livepatch Plugin" do
  PATCHES = {
    "hotfix1" => {
      "enabled" => "1",
      "transition" => "0",
    },
    "hotfix2" => {
      "enabled" => "0",
      "transition" => "1",
    },
  }.freeze

  def file_double(value)
    tmp_double = double
    expect(tmp_double).to receive(:read_nonblock).and_return(value)
    tmp_double
  end

  before do
    @plugin = get_plugin("linux/livepatch")
    allow(@plugin).to receive(:collect_os).and_return(:linux)
    allow(File).to receive(:exist?).with("/sys/kernel/livepatch").and_return(true)
    allow(@plugin).to receive(:dir_glob).with("/sys/kernel/livepatch/*") do
      PATCHES.collect { |patch, _files| "/sys/kernel/livepatch/#{patch}" }
    end

    PATCHES.each do |patch, checks|
      allow(File).to receive(:exist?).with("/sys/kernel/livepatch/#{patch}").and_return(true)
      checks.each do |check, value|
        allow(File).to receive(:exist?).with("/sys/kernel/livepatch/#{patch}/#{check}").and_return(true)
        allow(File).to receive(:open).with("/sys/kernel/livepatch/#{patch}/#{check}").and_yield(file_double(value))
      end
    end
  end

  it "collects all relevant data from livepatches" do
    @plugin.run
    PATCHES.each do |patch, checks|
      expect(@plugin[:livepatch][patch.to_sym]).to include(checks)
    end
  end
end
