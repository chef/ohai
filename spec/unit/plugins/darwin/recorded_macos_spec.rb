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

# Each fixture in spec/data/darwin_replay holds every command, `which`
# lookup and file the darwin plugins read on a macOS VM of that release,
# and the attributes Ohai reported there. The plugins run against those
# inputs and must report the same attributes.
#
# A change that alters a plugin's output on one of these releases fails
# here; if the new output is right, update that fixture's "expected" section.
describe "darwin plugins on recorded macOS releases" do
  attributes = %w{platform platform_version platform_version_extra platform_build platform_family os os_version
                  kernel cpu memory network counters filesystem hardware virtualization shells}.freeze

  Dir.glob(File.join(DarwinReplay::FIXTURE_DIR, "*.json")).sort.each do |path|
    name = File.basename(path, ".json")

    it "reports the recorded attributes on #{name}" do
      fixture = DarwinReplay.fixture(name)
      ohai = run_with_recorded_darwin_inputs(fixture, attributes)
      actual = JSON.parse(JSON.generate(ohai.data.to_hash))

      aggregate_failures do
        attributes.each do |attribute|
          expect(actual[attribute]).to eq(fixture["expected"][attribute]), "#{attribute} differs"
        end
      end
    end
  end
end
