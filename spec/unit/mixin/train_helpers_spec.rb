#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright (c) 2026 Tim Smith
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

require "spec_helper"
require "tmpdir"

describe Ohai::Mixin::TrainHelpers, "#dir_glob" do
  let(:plugin) { get_plugin("linux/livepatch") }

  around do |example|
    Dir.mktmpdir("ohai-dir-glob") do |dir|
      @dir = dir
      example.run
    end
  end

  it "returns the paths that match" do
    %w{a b}.each { |name| Dir.mkdir(File.join(@dir, name)) }
    expect(plugin.dir_glob("#{@dir}/*").sort).to eq(["#{@dir}/a", "#{@dir}/b"])
  end

  # /sys/kernel/livepatch exists but is empty on Linux unless a livepatch is loaded
  it "returns no paths when nothing matches" do
    expect(plugin.dir_glob("#{@dir}/*")).to eq([])
  end

  it "does not run a shell on the local system" do
    expect(plugin).not_to receive(:shell_out!)
    expect(plugin).not_to receive(:shell_out)
    plugin.dir_glob("#{@dir}/*")
  end
end
