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

# Each fixture in spec/data/linux_replay holds every command, file and
# directory the Linux plugins read on a real VM of that distro, and the
# attributes Ohai reported there. The plugins run against those inputs and
# must report the same attributes.
#
# A change that alters a plugin's output on one of these distros fails here;
# if the new output is right, update that fixture's "expected" section.
describe "Linux plugins on recorded distributions" do
  # skip the packages hash itself: its fixture entry is a count and a sample
  ATTRIBUTES = %w{platform platform_version platform_family platform_build os os_version lsb kernel cpu memory network
                  counters filesystem block_device virtualization init_package packages shells}.freeze

  def packages_summary(packages, sample_names)
    { "count" => packages.size, "sample" => sample_names.to_h { |name| [name, packages[name]] } }
  end

  Dir.glob(File.join(LinuxReplay::FIXTURE_DIR, "*.json")).sort.each do |path|
    name = File.basename(path, ".json")

    it "reports the recorded attributes on #{name}" do
      fixture = LinuxReplay.fixture(name)
      expected = fixture["expected"]
      ohai = run_with_recorded_inputs(fixture, ATTRIBUTES)
      actual = JSON.parse(JSON.generate(ohai.data.to_hash))

      aggregate_failures do
        expected.each do |attribute, value|
          if attribute == "packages_summary"
            expect(packages_summary(actual["packages"] || {}, value["sample"].keys)).to eq(value), "packages differ"
          else
            expect(actual[attribute]).to eq(value), "#{attribute} differs"
          end
        end
      end
    end
  end
end
