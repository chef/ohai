#
# Author:: Patrick Collins (<pat@burned.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Ohai::System, "Darwin Memory Plugin" do
  before do
    darwin_memsize = <<~DARWIN_MEMSIZE
      17179869184
    DARWIN_MEMSIZE
    darwin_vm_stat = <<~DARWIN_VM_STAT
      Mach Virtual Memory Statistics: (page size of 4096 bytes)
      Pages free:                        2155305.
      Pages active:                       924164.
      Pages inactive:                     189127.
      Pages speculative:                  531321.
      Pages wired down:                   391749.
      "Translation faults":             14107520.
      Pages copy-on-write:                810071.
      Pages zero filled:                 6981505.
      Pages reactivated:                    1397.
      Pageins:                            630064.
      Pageouts:                                0.
      Object cache: 12 hits of 139872 lookups (0% hit rate)
    DARWIN_VM_STAT

    @plugin = get_plugin("darwin/memory")
    allow(@plugin).to receive(:collect_os).and_return(:darwin)
    allow(@plugin).to receive(:shell_out).with("sysctl -n hw.memsize").and_return(mock_shell_out(0, darwin_memsize, ""))
    allow(@plugin).to receive(:shell_out).with("vm_stat").and_return(mock_shell_out(0, darwin_vm_stat, ""))
    @plugin.run
  end

  it "sets memory[:total] to 16384MB" do
    expect(@plugin[:memory][:total]).to eq("16384MB")
  end

  it "sets memory[:active] to 5140MB" do
    expect(@plugin[:memory][:active]).to eq("5140MB")
  end

  it "sets memory[:inactive] to 738MB" do
    expect(@plugin[:memory][:inactive]).to eq("738MB")
  end

  it "sets memory[:free] to 10504MB" do
    expect(@plugin[:memory][:free]).to eq("10504MB")
  end

  context "with memory held by the compressor" do
    before do
      vm_stat = <<~VM_STAT
        Mach Virtual Memory Statistics: (page size of 16384 bytes)
        Pages free:                                    38910.
        Pages active:                                 202491.
        Pages inactive:                               195750.
        Pages speculative:                              6708.
        Pages throttled:                                   0.
        Pages wired down:                              69245.
        Pages purgeable:                                4065.
        "Translation faults":                        3125636.
        Pages copy-on-write:                          162105.
        Pages zero filled:                           1079424.
        Pages reactivated:                             61041.
        Pages purged:                                   4225.
        File-backed pages:                            217973.
        Anonymous pages:                              186976.
        Pages stored in compressor:                    38162.
        Pages occupied by compressor:                  10349.
        Decompressions:                                 5818.
        Compressions:                                  50106.
        Pageins:                                      302923.
        Pageouts:                                       1873.
        Swapins:                                           0.
        Swapouts:                                          0.
      VM_STAT
      allow(@plugin).to receive(:shell_out).with("sysctl -n hw.memsize").and_return(mock_shell_out(0, "8589934592\n", ""))
      allow(@plugin).to receive(:shell_out).with("vm_stat").and_return(mock_shell_out(0, vm_stat, ""))
      @plugin[:memory] = nil
      @plugin.run
    end

    it "counts the compressor's pages as active, not free" do
      expect(@plugin[:memory]).to eq("total" => "8192MB", "active" => "4405MB", "inactive" => "3058MB", "free" => "725MB")
    end
  end
end
