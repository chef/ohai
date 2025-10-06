#
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

require "spec_helper"

describe Ohai::System, "Linux interrupts plugin" do
  let(:plugin) { get_plugin("linux/interrupts") }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
  end

  it "parses smp_affinity (partial mask, all)" do
    allow(plugin).to receive(:file_read).with("/affinity").and_return("f")
    expect(plugin.parse_smp_affinity("/affinity", 2)).to eq({
                                                              0 => true,
                                                              1 => true,
                                                            })
  end

  it "parses smp_affinity (partial mask, one)" do
    allow(plugin).to receive(:file_read).with("/affinity").and_return("e")
    expect(plugin.parse_smp_affinity("/affinity", 2)).to eq({
                                                              0 => false,
                                                              1 => true,
                                                            })
  end

  it "parses smp_affinity (full mask, all)" do
    allow(plugin).to receive(:file_read).with("/affinity").and_return("ff")
    expect(plugin.parse_smp_affinity("/affinity", 2)).to eq({
                                                              0 => true,
                                                              1 => true,
                                                            })
  end

  it "parses smp_affinity (full mask, one)" do
    allow(plugin).to receive(:file_read).with("/affinity").and_return("fe")
    expect(plugin.parse_smp_affinity("/affinity", 2)).to eq({
                                                              0 => false,
                                                              1 => true,
                                                            })
  end

  it "parses smp_affinity (full mask, two groups, all)" do
    cpus = {}
    (0..47).each do |i|
      cpus[i] = true
    end
    allow(plugin).to receive(:file_read).with("/affinity")
      .and_return("ffff,ffffffff")
    expect(plugin.parse_smp_affinity("/affinity", 48)).to eq(cpus)
  end

  it "parses smp_affinity (full mask, two groups, two)" do
    cpus = {}
    (0..47).each do |i|
      cpus[i] = true
    end
    cpus[12] = false
    cpus[32] = false
    allow(plugin).to receive(:file_read).with("/affinity")
      .and_return("fffe,ffffefff")
    expect(plugin.parse_smp_affinity("/affinity", 48)).to eq(cpus)
  end
end
