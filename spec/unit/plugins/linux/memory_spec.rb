#
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

describe Ohai::System, "Linux memory plugin" do
  before do
    @plugin = get_plugin("linux/memory")
    allow(@plugin).to receive(:collect_os).and_return(:linux)
    @double_file = double("/proc/meminfo")
    allow(@double_file).to receive(:each)
      .and_yield("MemTotal:     131932120 kB")
      .and_yield("MemFree:       2269032 kB")
      .and_yield("MemAvailable:  9208922 kB")
      .and_yield("Buffers:        646368 kB")
      .and_yield("Cached:       32346556 kB")
      .and_yield("SwapCached:        312 kB")
      .and_yield("Active:       98595796 kB")
      .and_yield("Inactive:     18477320 kB")
      .and_yield("HighTotal:           0 kB")
      .and_yield("HighFree:            0 kB")
      .and_yield("LowTotal:     131932120 kB")
      .and_yield("LowFree:       2269032 kB")
      .and_yield("SwapTotal:    16777208 kB")
      .and_yield("SwapFree:     14127356 kB")
      .and_yield("Dirty:            3212 kB")
      .and_yield("Writeback:           0 kB")
      .and_yield("AnonPages:    84082132 kB")
      .and_yield("Mapped:        3445224 kB")
      .and_yield("Slab:          9892096 kB")
      .and_yield("SReclaimable:     362636 kB")
      .and_yield("SUnreclaim:        18860 kB")
      .and_yield("PageTables:    1759332 kB")
      .and_yield("NFS_Unstable:        0 kB")
      .and_yield("Bounce:              0 kB")
      .and_yield("CommitLimit:  148709328 kB")
      .and_yield("Committed_AS: 333717060 kB")
      .and_yield("VmallocTotal: 34359738367 kB")
      .and_yield("VmallocUsed:    276796 kB")
      .and_yield("VmallocChunk: 34359461515 kB")
      .and_yield("HugePages_Total: 11542")
      .and_yield("HugePages_Free:  11235")
      .and_yield("HugePages_Rsvd:  11226")
      .and_yield("HugePages_Surp:      0")
      .and_yield("Hugepagesize:     2048 kB")
      .and_yield("Hugetlb:               0 kB")
      .and_yield("DirectMap4k:     3720736 kB")
      .and_yield("DirectMap2M:    12795904 kB")
      .and_yield("DirectMap1G:           0 kB")

    allow(File).to receive(:open).with("/proc/meminfo").and_return(@double_file)
  end

  it "gets total memory" do
    @plugin.run
    expect(@plugin[:memory][:total]).to eql("131932120kB")
  end

  it "gets free memory" do
    @plugin.run
    expect(@plugin[:memory][:free]).to eql("2269032kB")
  end

  it "gets available memory" do
    @plugin.run
    expect(@plugin[:memory][:available]).to eql("9208922kB")
  end

  it "gets memory used for file buffers" do
    @plugin.run
    expect(@plugin[:memory][:buffers]).to eql("646368kB")
  end

  it "gets cache memory" do
    @plugin.run
    expect(@plugin[:memory][:cached]).to eql("32346556kB")
  end

  it "gets active memory" do
    @plugin.run
    expect(@plugin[:memory][:active]).to eql("98595796kB")
  end

  it "gets inactive memory" do
    @plugin.run
    expect(@plugin[:memory][:inactive]).to eql("18477320kB")
  end

  it "gets high_total memory" do
    @plugin.run
    expect(@plugin[:memory][:high_total]).to eql("0kB")
  end

  it "gets high_free memory" do
    @plugin.run
    expect(@plugin[:memory][:high_free]).to eql("0kB")
  end

  it "gets low_total memory" do
    @plugin.run
    expect(@plugin[:memory][:low_total]).to eql("131932120kB")
  end

  it "gets low_free memory" do
    @plugin.run
    expect(@plugin[:memory][:low_free]).to eql("2269032kB")
  end

  it "gets dirty memory" do
    @plugin.run
    expect(@plugin[:memory][:dirty]).to eql("3212kB")
  end

  it "gets writeback memory" do
    @plugin.run
    expect(@plugin[:memory][:writeback]).to eql("0kB")
  end

  it "gets anon_pages memory" do
    @plugin.run
    expect(@plugin[:memory][:anon_pages]).to eql("84082132kB")
  end

  it "gets mapped memory" do
    @plugin.run
    expect(@plugin[:memory][:mapped]).to eql("3445224kB")
  end

  it "gets slab memory" do
    @plugin.run
    expect(@plugin[:memory][:slab]).to eql("9892096kB")
  end

  it "gets slab_reclaimable memory" do
    @plugin.run
    expect(@plugin[:memory][:slab_reclaimable]).to eql("362636kB")
  end

  it "gets slab_reclaimable memory" do
    @plugin.run
    expect(@plugin[:memory][:slab_unreclaim]).to eql("18860kB")
  end

  it "gets page_tables memory" do
    @plugin.run
    expect(@plugin[:memory][:page_tables]).to eql("1759332kB")
  end

  it "gets nfs_unstable memory" do
    @plugin.run
    expect(@plugin[:memory][:nfs_unstable]).to eql("0kB")
  end

  it "gets bounce memory" do
    @plugin.run
    expect(@plugin[:memory][:bounce]).to eql("0kB")
  end

  it "gets commit_limit memory" do
    @plugin.run
    expect(@plugin[:memory][:commit_limit]).to eql("148709328kB")
  end

  it "gets committed_as memory" do
    @plugin.run
    expect(@plugin[:memory][:committed_as]).to eql("333717060kB")
  end

  it "gets vmalloc_total memory" do
    @plugin.run
    expect(@plugin[:memory][:vmalloc_total]).to eql("34359738367kB")
  end

  it "gets vmalloc_used memory" do
    @plugin.run
    expect(@plugin[:memory][:vmalloc_used]).to eql("276796kB")
  end

  it "gets vmalloc_chunk memory" do
    @plugin.run
    expect(@plugin[:memory][:vmalloc_chunk]).to eql("34359461515kB")
  end

  it "gets total swap" do
    @plugin.run
    expect(@plugin[:memory][:swap][:total]).to eql("16777208kB")
  end

  it "gets cached swap" do
    @plugin.run
    expect(@plugin[:memory][:swap][:cached]).to eql("312kB")
  end

  it "gets free swap" do
    @plugin.run
    expect(@plugin[:memory][:swap][:free]).to eql("14127356kB")
  end

  it "gets total hugepages" do
    @plugin.run
    expect(@plugin[:memory][:hugepages][:total]).to eql("11542")
  end

  it "gets free hugepages" do
    @plugin.run
    expect(@plugin[:memory][:hugepages][:free]).to eql("11235")
  end

  it "gets reserved hugepages" do
    @plugin.run
    expect(@plugin[:memory][:hugepages][:reserved]).to eql("11226")
  end

  it "gets surplus hugepages" do
    @plugin.run
    expect(@plugin[:memory][:hugepages][:surplus]).to eql("0")
  end

  it "gets hugepage size" do
    @plugin.run
    expect(@plugin[:memory][:hugepage_size]).to eql("2048kB")
  end

  it "gets hugetlb memory" do
    @plugin.run
    expect(@plugin[:memory][:hugetlb]).to eql("0kB")
  end

  it "gets directmap 4k memory" do
    @plugin.run
    expect(@plugin[:memory][:directmap][:'4k']).to eql("3720736kB")
  end

  it "gets directmap 2M memory" do
    @plugin.run
    expect(@plugin[:memory][:directmap][:'2M']).to eql("12795904kB")
  end

  it "gets directmap 1G memory" do
    @plugin.run
    expect(@plugin[:memory][:directmap][:'1G']).to eql("0kB")
  end
end
