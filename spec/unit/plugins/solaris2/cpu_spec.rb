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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "Solaris2.X cpu plugin" do
  before(:each) do
    @plugin = get_plugin("solaris2/cpu")
    allow(@plugin).to receive(:collect_os).and_return("solaris2")
  end

  describe "on x86 processors" do
    before(:each) do
      kstatinfo_output = <<-END
cpu_info:0:cpu_info0:brand      Crazy(r) Argon(r) CPU           Y5570  @ 1.93GHz
cpu_info:0:cpu_info0:cache_id   1
cpu_info:0:cpu_info0:chip_id    1
cpu_info:0:cpu_info0:class      misc
cpu_info:0:cpu_info0:clock_MHz  1933
cpu_info:0:cpu_info0:clog_id    0
cpu_info:0:cpu_info0:core_id    8
cpu_info:0:cpu_info0:cpu_type   i386
cpu_info:0:cpu_info0:crtime     300.455409162
cpu_info:0:cpu_info0:current_clock_Hz   2925945978
cpu_info:0:cpu_info0:current_cstate     0
cpu_info:0:cpu_info0:family     12
cpu_info:0:cpu_info0:fpu_type   i387 compatible
cpu_info:0:cpu_info0:implementation     x86 (chipid 0x1 GenuineIntel family 6 model 26 step 5 clock 2926 MHz)
cpu_info:0:cpu_info0:model      93
cpu_info:0:cpu_info0:ncore_per_chip     4
cpu_info:0:cpu_info0:ncpu_per_chip      8
cpu_info:0:cpu_info0:pg_id      1
cpu_info:0:cpu_info0:pkg_core_id        0
cpu_info:0:cpu_info0:snaptime   12444687.9690404
cpu_info:0:cpu_info0:state      off-line
cpu_info:0:cpu_info0:state_begin        1427142581
cpu_info:0:cpu_info0:stepping   9
cpu_info:0:cpu_info0:supported_frequencies_Hz   2925945978
cpu_info:0:cpu_info0:supported_max_cstates      1
cpu_info:0:cpu_info0:vendor_id  CrazyTown
cpu_info:1:cpu_info1:brand      Intel(r) Xeon(r) CPU           X5570  @ 2.93GHz
cpu_info:1:cpu_info1:cache_id   0
cpu_info:1:cpu_info1:chip_id    0
cpu_info:1:cpu_info1:class      misc
cpu_info:1:cpu_info1:clock_MHz  2926
cpu_info:1:cpu_info1:clog_id    0
cpu_info:1:cpu_info1:core_id    0
cpu_info:1:cpu_info1:cpu_type   i386
cpu_info:1:cpu_info1:crtime     308.198046165
cpu_info:1:cpu_info1:current_clock_Hz   2925945978
cpu_info:1:cpu_info1:current_cstate     1
cpu_info:1:cpu_info1:family     6
cpu_info:1:cpu_info1:fpu_type   i387 compatible
cpu_info:1:cpu_info1:implementation     x86 (chipid 0x0 GenuineIntel family 6 model 26 step 5 clock 2926 MHz)
cpu_info:1:cpu_info1:model      26
cpu_info:1:cpu_info1:ncore_per_chip     4
cpu_info:1:cpu_info1:ncpu_per_chip      8
cpu_info:1:cpu_info1:pg_id      4
cpu_info:1:cpu_info1:pkg_core_id        0
cpu_info:1:cpu_info1:snaptime   12444687.9693359
cpu_info:1:cpu_info1:state      on-line
cpu_info:1:cpu_info1:state_begin        1427142588
cpu_info:1:cpu_info1:stepping   5
cpu_info:1:cpu_info1:supported_frequencies_Hz   2925945978
cpu_info:1:cpu_info1:supported_max_cstates      1
cpu_info:1:cpu_info1:vendor_id  GenuineIntel
cpu_info:2:cpu_info2:brand      Crazy(r) Argon(r) CPU           Y5570  @ 1.93GHz
cpu_info:2:cpu_info2:cache_id   1
cpu_info:2:cpu_info2:chip_id    1
cpu_info:2:cpu_info2:class      misc
cpu_info:2:cpu_info2:clock_MHz  1933
cpu_info:2:cpu_info2:clog_id    2
cpu_info:2:cpu_info2:core_id    9
cpu_info:2:cpu_info2:cpu_type   i386
cpu_info:2:cpu_info2:crtime     308.280117986
cpu_info:2:cpu_info2:current_clock_Hz   2925945978
cpu_info:2:cpu_info2:current_cstate     0
cpu_info:2:cpu_info2:family     12
cpu_info:2:cpu_info2:fpu_type   i387 compatible
cpu_info:2:cpu_info2:implementation     x86 (chipid 0x1 GenuineIntel family 6 model 26 step 5 clock 2926 MHz)
cpu_info:2:cpu_info2:model     93
cpu_info:2:cpu_info2:ncore_per_chip     4
cpu_info:2:cpu_info2:ncpu_per_chip      8
cpu_info:2:cpu_info2:pg_id      7
cpu_info:2:cpu_info2:pkg_core_id        1
cpu_info:2:cpu_info2:snaptime   12444687.9695684
cpu_info:2:cpu_info2:state      off-line
cpu_info:2:cpu_info2:state_begin        1427142588
cpu_info:2:cpu_info2:stepping   9
cpu_info:2:cpu_info2:supported_frequencies_Hz   2925945978
cpu_info:2:cpu_info2:supported_max_cstates      1
cpu_info:2:cpu_info2:vendor_id  CrazyTown
cpu_info:3:cpu_info3:brand      Intel(r) Xeon(r) CPU           X5570  @ 2.93GHz
cpu_info:3:cpu_info3:cache_id   0
cpu_info:3:cpu_info3:chip_id    0
cpu_info:3:cpu_info3:class      misc
cpu_info:3:cpu_info3:clock_MHz  2926
cpu_info:3:cpu_info3:clog_id    2
cpu_info:3:cpu_info3:core_id    1
cpu_info:3:cpu_info3:cpu_type   i386
cpu_info:3:cpu_info3:crtime     308.310124315
cpu_info:3:cpu_info3:current_clock_Hz   2925945978
cpu_info:3:cpu_info3:current_cstate     1
cpu_info:3:cpu_info3:family     6
cpu_info:3:cpu_info3:fpu_type   i387 compatible
cpu_info:3:cpu_info3:implementation     x86 (chipid 0x0 GenuineIntel family 6 model 26 step 5 clock 2926 MHz)
cpu_info:3:cpu_info3:model      26
cpu_info:3:cpu_info3:ncore_per_chip     4
cpu_info:3:cpu_info3:ncpu_per_chip      8
cpu_info:3:cpu_info3:pg_id      8
cpu_info:3:cpu_info3:pkg_core_id        1
cpu_info:3:cpu_info3:snaptime   12444687.9698122
cpu_info:3:cpu_info3:state      on-line
cpu_info:3:cpu_info3:state_begin        1427142588
cpu_info:3:cpu_info3:stepping   5
cpu_info:3:cpu_info3:supported_frequencies_Hz   2925945978
cpu_info:3:cpu_info3:supported_max_cstates      1
cpu_info:3:cpu_info3:vendor_id  GenuineIntel
cpu_info:4:cpu_info4:brand      Crazy(r) Argon(r) CPU           Y5570  @ 1.93GHz
cpu_info:4:cpu_info4:cache_id   1
cpu_info:4:cpu_info4:chip_id    1
cpu_info:4:cpu_info4:class      misc
cpu_info:4:cpu_info4:clock_MHz  1933
cpu_info:4:cpu_info4:clog_id    4
cpu_info:4:cpu_info4:core_id    10
cpu_info:4:cpu_info4:cpu_type   i386
cpu_info:4:cpu_info4:crtime     308.340112555
cpu_info:4:cpu_info4:current_clock_Hz   2925945978
cpu_info:4:cpu_info4:current_cstate     0
cpu_info:4:cpu_info4:family     12
cpu_info:4:cpu_info4:fpu_type   i387 compatible
cpu_info:4:cpu_info4:implementation     x86 (chipid 0x1 GenuineIntel family 6 model 26 step 5 clock 2926 MHz)
cpu_info:4:cpu_info4:model      93
cpu_info:4:cpu_info4:ncore_per_chip     4
cpu_info:4:cpu_info4:ncpu_per_chip      8
cpu_info:4:cpu_info4:pg_id      9
cpu_info:4:cpu_info4:pkg_core_id        2
cpu_info:4:cpu_info4:snaptime   12444687.9700613
cpu_info:4:cpu_info4:state      off-line
cpu_info:4:cpu_info4:state_begin        1427142588
cpu_info:4:cpu_info4:stepping   9
cpu_info:4:cpu_info4:supported_frequencies_Hz   2925945978
cpu_info:4:cpu_info4:supported_max_cstates      1
cpu_info:4:cpu_info4:vendor_id  CrazyTown
cpu_info:5:cpu_info5:brand      Intel(r) Xeon(r) CPU           X5570  @ 2.93GHz
cpu_info:5:cpu_info5:cache_id   0
cpu_info:5:cpu_info5:chip_id    0
cpu_info:5:cpu_info5:class      misc
cpu_info:5:cpu_info5:clock_MHz  2926
cpu_info:5:cpu_info5:clog_id    4
cpu_info:5:cpu_info5:core_id    2
cpu_info:5:cpu_info5:cpu_type   i386
cpu_info:5:cpu_info5:crtime     308.370191347
cpu_info:5:cpu_info5:current_clock_Hz   2925945978
cpu_info:5:cpu_info5:current_cstate     1
cpu_info:5:cpu_info5:family     6
cpu_info:5:cpu_info5:fpu_type   i387 compatible
cpu_info:5:cpu_info5:implementation     x86 (chipid 0x0 GenuineIntel family 6 model 26 step 5 clock 2926 MHz)
cpu_info:5:cpu_info5:model      26
cpu_info:5:cpu_info5:ncore_per_chip     4
cpu_info:5:cpu_info5:ncpu_per_chip      8
cpu_info:5:cpu_info5:pg_id      10
cpu_info:5:cpu_info5:pkg_core_id        2
cpu_info:5:cpu_info5:snaptime   12444687.9702885
cpu_info:5:cpu_info5:state      on-line
cpu_info:5:cpu_info5:state_begin        1427142589
cpu_info:5:cpu_info5:stepping   5
cpu_info:5:cpu_info5:supported_frequencies_Hz   2925945978
cpu_info:5:cpu_info5:supported_max_cstates      1
cpu_info:5:cpu_info5:vendor_id  GenuineIntel
cpu_info:6:cpu_info6:brand      Crazy(r) Argon(r) CPU           Y5570  @ 1.93GHz
cpu_info:6:cpu_info6:cache_id   1
cpu_info:6:cpu_info6:chip_id    1
cpu_info:6:cpu_info6:class      misc
cpu_info:6:cpu_info6:clock_MHz  1933
cpu_info:6:cpu_info6:clog_id    6
cpu_info:6:cpu_info6:core_id    11
cpu_info:6:cpu_info6:cpu_type   i386
cpu_info:6:cpu_info6:crtime     308.400119134
cpu_info:6:cpu_info6:current_clock_Hz   2925945978
cpu_info:6:cpu_info6:current_cstate     1
cpu_info:6:cpu_info6:family     12
cpu_info:6:cpu_info6:fpu_type   i387 compatible
cpu_info:6:cpu_info6:implementation     x86 (chipid 0x1 GenuineIntel family 6 model 26 step 5 clock 2926 MHz)
cpu_info:6:cpu_info6:model      93
cpu_info:6:cpu_info6:ncore_per_chip     4
cpu_info:6:cpu_info6:ncpu_per_chip      8
cpu_info:6:cpu_info6:pg_id      11
cpu_info:6:cpu_info6:pkg_core_id        3
cpu_info:6:cpu_info6:snaptime   12444687.9705136
cpu_info:6:cpu_info6:state      off-line
cpu_info:6:cpu_info6:state_begin        1427142589
cpu_info:6:cpu_info6:stepping   9
cpu_info:6:cpu_info6:supported_frequencies_Hz   2925945978
cpu_info:6:cpu_info6:supported_max_cstates      1
cpu_info:6:cpu_info6:vendor_id  CrazyTown
cpu_info:7:cpu_info7:brand      Intel(r) Xeon(r) CPU           X5570  @ 2.93GHz
cpu_info:7:cpu_info7:cache_id   0
cpu_info:7:cpu_info7:chip_id    0
cpu_info:7:cpu_info7:class      misc
cpu_info:7:cpu_info7:clock_MHz  2926
cpu_info:7:cpu_info7:clog_id    6
cpu_info:7:cpu_info7:core_id    3
cpu_info:7:cpu_info7:cpu_type   i386
cpu_info:7:cpu_info7:crtime     308.430139185
cpu_info:7:cpu_info7:current_clock_Hz   2925945978
cpu_info:7:cpu_info7:current_cstate     1
cpu_info:7:cpu_info7:family     6
cpu_info:7:cpu_info7:fpu_type   i387 compatible
cpu_info:7:cpu_info7:implementation     x86 (chipid 0x0 GenuineIntel family 6 model 26 step 5 clock 2926 MHz)
cpu_info:7:cpu_info7:model      26
cpu_info:7:cpu_info7:ncore_per_chip     4
cpu_info:7:cpu_info7:ncpu_per_chip      8
cpu_info:7:cpu_info7:pg_id      12
cpu_info:7:cpu_info7:pkg_core_id        3
cpu_info:7:cpu_info7:snaptime   12444687.9707517
cpu_info:7:cpu_info7:state      on-line
cpu_info:7:cpu_info7:state_begin        1427142589
cpu_info:7:cpu_info7:stepping   5
cpu_info:7:cpu_info7:supported_frequencies_Hz   2925945978
cpu_info:7:cpu_info7:supported_max_cstates      1
cpu_info:7:cpu_info7:vendor_id  GenuineIntel
cpu_info:8:cpu_info8:brand      Crazy(r) Argon(r) CPU           Y5570  @ 1.93GHz
cpu_info:8:cpu_info8:cache_id   1
cpu_info:8:cpu_info8:chip_id    1
cpu_info:8:cpu_info8:class      misc
cpu_info:8:cpu_info8:clock_MHz  1933
cpu_info:8:cpu_info8:clog_id    1
cpu_info:8:cpu_info8:core_id    8
cpu_info:8:cpu_info8:cpu_type   i386
cpu_info:8:cpu_info8:crtime     308.460126522
cpu_info:8:cpu_info8:current_clock_Hz   2925945978
cpu_info:8:cpu_info8:current_cstate     1
cpu_info:8:cpu_info8:family     12
cpu_info:8:cpu_info8:fpu_type   i387 compatible
cpu_info:8:cpu_info8:implementation     x86 (chipid 0x1 GenuineIntel family 6 model 26 step 5 clock 2926 MHz)
cpu_info:8:cpu_info8:model     93
cpu_info:8:cpu_info8:ncore_per_chip     4
cpu_info:8:cpu_info8:ncpu_per_chip      8
cpu_info:8:cpu_info8:pg_id      1
cpu_info:8:cpu_info8:pkg_core_id        0
cpu_info:8:cpu_info8:snaptime   12444687.9709846
cpu_info:8:cpu_info8:state      off-line
cpu_info:8:cpu_info8:state_begin        1427142589
cpu_info:8:cpu_info8:stepping   9
cpu_info:8:cpu_info8:supported_frequencies_Hz   2925945978
cpu_info:8:cpu_info8:supported_max_cstates      1
cpu_info:8:cpu_info8:vendor_id  CrazyTown
cpu_info:9:cpu_info9:brand      Intel(r) Xeon(r) CPU           X5570  @ 2.93GHz
cpu_info:9:cpu_info9:cache_id   0
cpu_info:9:cpu_info9:chip_id    0
cpu_info:9:cpu_info9:class      misc
cpu_info:9:cpu_info9:clock_MHz  2926
cpu_info:9:cpu_info9:clog_id    1
cpu_info:9:cpu_info9:core_id    0
cpu_info:9:cpu_info9:cpu_type   i386
cpu_info:9:cpu_info9:crtime     308.490165484
cpu_info:9:cpu_info9:current_clock_Hz   2925945978
cpu_info:9:cpu_info9:current_cstate     1
cpu_info:9:cpu_info9:family     6
cpu_info:9:cpu_info9:fpu_type   i387 compatible
cpu_info:9:cpu_info9:implementation     x86 (chipid 0x0 GenuineIntel family 6 model 26 step 5 clock 2926 MHz)
cpu_info:9:cpu_info9:model      26
cpu_info:9:cpu_info9:ncore_per_chip     4
cpu_info:9:cpu_info9:ncpu_per_chip      8
cpu_info:9:cpu_info9:pg_id      4
cpu_info:9:cpu_info9:pkg_core_id        0
cpu_info:9:cpu_info9:snaptime   12444687.9712051
cpu_info:9:cpu_info9:state      on-line
cpu_info:9:cpu_info9:state_begin        1427142589
cpu_info:9:cpu_info9:stepping   5
cpu_info:9:cpu_info9:supported_frequencies_Hz   2925945978
cpu_info:9:cpu_info9:supported_max_cstates      1
cpu_info:9:cpu_info9:vendor_id  GenuineIntel
cpu_info:10:cpu_info10:brand      Crazy(r) Argon(r) CPU           Y5570  @ 1.93GHz
cpu_info:10:cpu_info10:cache_id 1
cpu_info:10:cpu_info10:chip_id  1
cpu_info:10:cpu_info10:class    misc
cpu_info:10:cpu_info10:clock_MHz        1933
cpu_info:10:cpu_info10:clog_id  3
cpu_info:10:cpu_info10:core_id  9
cpu_info:10:cpu_info10:cpu_type i386
cpu_info:10:cpu_info10:crtime   308.520151852
cpu_info:10:cpu_info10:current_clock_Hz 2925945978
cpu_info:10:cpu_info10:current_cstate   1
cpu_info:10:cpu_info10:family   12
cpu_info:10:cpu_info10:fpu_type i387 compatible
cpu_info:10:cpu_info10:implementation   x86 (chipid 0x1 GenuineIntel family 6 model 26 step 5 clock 2926 MHz)
cpu_info:10:cpu_info10:model    93
cpu_info:10:cpu_info10:ncore_per_chip   4
cpu_info:10:cpu_info10:ncpu_per_chip    8
cpu_info:10:cpu_info10:pg_id    7
cpu_info:10:cpu_info10:pkg_core_id      1
cpu_info:10:cpu_info10:snaptime 12444687.9714381
cpu_info:10:cpu_info10:state    off-line
cpu_info:10:cpu_info10:state_begin      1427142589
cpu_info:10:cpu_info10:stepping 9
cpu_info:10:cpu_info10:supported_frequencies_Hz 2925945978
cpu_info:10:cpu_info10:supported_max_cstates    1
cpu_info:10:cpu_info10:vendor_id        CrazyTown
cpu_info:11:cpu_info11:brand    Intel(r) Xeon(r) CPU           X5570  @ 2.93GHz
cpu_info:11:cpu_info11:cache_id 0
cpu_info:11:cpu_info11:chip_id  0
cpu_info:11:cpu_info11:class    misc
cpu_info:11:cpu_info11:clock_MHz        2926
cpu_info:11:cpu_info11:clog_id  3
cpu_info:11:cpu_info11:core_id  1
cpu_info:11:cpu_info11:cpu_type i386
cpu_info:11:cpu_info11:crtime   308.550150882
cpu_info:11:cpu_info11:current_clock_Hz 2925945978
cpu_info:11:cpu_info11:current_cstate   1
cpu_info:11:cpu_info11:family   6
cpu_info:11:cpu_info11:fpu_type i387 compatible
cpu_info:11:cpu_info11:implementation   x86 (chipid 0x0 GenuineIntel family 6 model 26 step 5 clock 2926 MHz)
cpu_info:11:cpu_info11:model    26
cpu_info:11:cpu_info11:ncore_per_chip   4
cpu_info:11:cpu_info11:ncpu_per_chip    8
cpu_info:11:cpu_info11:pg_id    8
cpu_info:11:cpu_info11:pkg_core_id      1
cpu_info:11:cpu_info11:snaptime 12444687.9716655
cpu_info:11:cpu_info11:state    on-line
cpu_info:11:cpu_info11:state_begin      1427142589
cpu_info:11:cpu_info11:stepping 5
cpu_info:11:cpu_info11:supported_frequencies_Hz 2925945978
cpu_info:11:cpu_info11:supported_max_cstates    1
cpu_info:11:cpu_info11:vendor_id        GenuineIntel
cpu_info:12:cpu_info12:brand      Crazy(r) Argon(r) CPU           Y5570  @ 1.93GHz
cpu_info:12:cpu_info12:cache_id 1
cpu_info:12:cpu_info12:chip_id  1
cpu_info:12:cpu_info12:class    misc
cpu_info:12:cpu_info12:clock_MHz        1933
cpu_info:12:cpu_info12:clog_id  5
cpu_info:12:cpu_info12:core_id  10
cpu_info:12:cpu_info12:cpu_type i386
cpu_info:12:cpu_info12:crtime   308.580146834
cpu_info:12:cpu_info12:current_clock_Hz 2925945978
cpu_info:12:cpu_info12:current_cstate   1
cpu_info:12:cpu_info12:family   12
cpu_info:12:cpu_info12:fpu_type i387 compatible
cpu_info:12:cpu_info12:implementation   x86 (chipid 0x1 GenuineIntel family 6 model 26 step 5 clock 2926 MHz)
cpu_info:12:cpu_info12:model    93
cpu_info:12:cpu_info12:ncore_per_chip   4
cpu_info:12:cpu_info12:ncpu_per_chip    8
cpu_info:12:cpu_info12:pg_id    9
cpu_info:12:cpu_info12:pkg_core_id      2
cpu_info:12:cpu_info12:snaptime 12444687.9718927
cpu_info:12:cpu_info12:state    off-line
cpu_info:12:cpu_info12:state_begin      1427142589
cpu_info:12:cpu_info12:stepping 9
cpu_info:12:cpu_info12:supported_frequencies_Hz 2925945978
cpu_info:12:cpu_info12:supported_max_cstates    1
cpu_info:12:cpu_info12:vendor_id        CrazyTown
cpu_info:13:cpu_info13:brand    Intel(r) Xeon(r) CPU           X5570  @ 2.93GHz
cpu_info:13:cpu_info13:cache_id 0
cpu_info:13:cpu_info13:chip_id  0
cpu_info:13:cpu_info13:class    misc
cpu_info:13:cpu_info13:clock_MHz        2926
cpu_info:13:cpu_info13:clog_id  5
cpu_info:13:cpu_info13:core_id  2
cpu_info:13:cpu_info13:cpu_type i386
cpu_info:13:cpu_info13:crtime   308.610149804
cpu_info:13:cpu_info13:current_clock_Hz 2925945978
cpu_info:13:cpu_info13:current_cstate   1
cpu_info:13:cpu_info13:family   6
cpu_info:13:cpu_info13:fpu_type i387 compatible
cpu_info:13:cpu_info13:implementation   x86 (chipid 0x0 GenuineIntel family 6 model 26 step 5 clock 2926 MHz)
cpu_info:13:cpu_info13:model    26
cpu_info:13:cpu_info13:ncore_per_chip   4
cpu_info:13:cpu_info13:ncpu_per_chip    8
cpu_info:13:cpu_info13:pg_id    10
cpu_info:13:cpu_info13:pkg_core_id      2
cpu_info:13:cpu_info13:snaptime 12444687.9721356
cpu_info:13:cpu_info13:state    on-line
cpu_info:13:cpu_info13:state_begin      1427142589
cpu_info:13:cpu_info13:stepping 5
cpu_info:13:cpu_info13:supported_frequencies_Hz 2925945978
cpu_info:13:cpu_info13:supported_max_cstates    1
cpu_info:13:cpu_info13:vendor_id        GenuineIntel
cpu_info:14:cpu_info14:brand      Crazy(r) Argon(r) CPU           Y5570  @ 1.93GHz
cpu_info:14:cpu_info14:cache_id 1
cpu_info:14:cpu_info14:chip_id  1
cpu_info:14:cpu_info14:class    misc
cpu_info:14:cpu_info14:clock_MHz        1933
cpu_info:14:cpu_info14:clog_id  7
cpu_info:14:cpu_info14:core_id  11
cpu_info:14:cpu_info14:cpu_type i386
cpu_info:14:cpu_info14:crtime   308.640144708
cpu_info:14:cpu_info14:current_clock_Hz 2925945978
cpu_info:14:cpu_info14:current_cstate   1
cpu_info:14:cpu_info14:family   12
cpu_info:14:cpu_info14:fpu_type i387 compatible
cpu_info:14:cpu_info14:implementation   x86 (chipid 0x1 GenuineIntel family 6 model 26 step 5 clock 2926 MHz)
cpu_info:14:cpu_info14:model    93
cpu_info:14:cpu_info14:ncore_per_chip   4
cpu_info:14:cpu_info14:ncpu_per_chip    8
cpu_info:14:cpu_info14:pg_id    11
cpu_info:14:cpu_info14:pkg_core_id      3
cpu_info:14:cpu_info14:snaptime 12444687.9723752
cpu_info:14:cpu_info14:state    off-line
cpu_info:14:cpu_info14:state_begin      1427142589
cpu_info:14:cpu_info14:stepping 9
cpu_info:14:cpu_info14:supported_frequencies_Hz 2925945978
cpu_info:14:cpu_info14:supported_max_cstates    1
cpu_info:14:cpu_info14:vendor_id        CrazyTown
cpu_info:15:cpu_info15:brand    Intel(r) Xeon(r) CPU           X5570  @ 2.93GHz
cpu_info:15:cpu_info15:cache_id 0
cpu_info:15:cpu_info15:chip_id  0
cpu_info:15:cpu_info15:class    misc
cpu_info:15:cpu_info15:clock_MHz        2926
cpu_info:15:cpu_info15:clog_id  7
cpu_info:15:cpu_info15:core_id  3
cpu_info:15:cpu_info15:cpu_type i386
cpu_info:15:cpu_info15:crtime   308.670163124
cpu_info:15:cpu_info15:current_clock_Hz 2925945978
cpu_info:15:cpu_info15:current_cstate   1
cpu_info:15:cpu_info15:family   6
cpu_info:15:cpu_info15:fpu_type i387 compatible
cpu_info:15:cpu_info15:implementation   x86 (chipid 0x0 GenuineIntel family 6 model 26 step 5 clock 2926 MHz)
cpu_info:15:cpu_info15:model    26
cpu_info:15:cpu_info15:ncore_per_chip   4
cpu_info:15:cpu_info15:ncpu_per_chip    8
cpu_info:15:cpu_info15:pg_id    12
cpu_info:15:cpu_info15:pkg_core_id      3
cpu_info:15:cpu_info15:snaptime 12444687.9726021
cpu_info:15:cpu_info15:state    on-line
cpu_info:15:cpu_info15:state_begin      1427142589
cpu_info:15:cpu_info15:stepping 5
cpu_info:15:cpu_info15:supported_frequencies_Hz 2925945978
cpu_info:15:cpu_info15:supported_max_cstates    1
cpu_info:15:cpu_info15:vendor_id        GenuineIntel
END
      allow(@plugin).to receive(:shell_out).with("kstat -p cpu_info").and_return(mock_shell_out(0, kstatinfo_output, ""))
      @plugin.run
    end

    it "should get the total virtual processor count" do
      expect(@plugin["cpu"]["total"]).to eql(16)
    end

    it "should get the total processor count" do
      expect(@plugin["cpu"]["real"]).to eql(2)
    end

    it "should get the number of threads per core" do
      expect(@plugin["cpu"]["corethreads"]).to eql (2)
    end

    it "should get the total number of online cores" do
      expect(@plugin["cpu"]["cpustates"]["on-line"]).to eql (8)
    end

    it "should get the total number of offline cores" do
      expect(@plugin["cpu"]["cpustates"]["off-line"]).to eql (8)
    end

    describe "per-cpu information" do
      it "should include processor vendor_ids" do
        # CPU Socket 0
        expect(@plugin["cpu"]["15"]["vendor_id"]).to eql("GenuineIntel")
        expect(@plugin["cpu"]["13"]["vendor_id"]).to eql("GenuineIntel")
        expect(@plugin["cpu"]["11"]["vendor_id"]).to eql("GenuineIntel")
        expect(@plugin["cpu"]["9"]["vendor_id"]).to eql("GenuineIntel")
        expect(@plugin["cpu"]["7"]["vendor_id"]).to eql("GenuineIntel")
        expect(@plugin["cpu"]["5"]["vendor_id"]).to eql("GenuineIntel")
        expect(@plugin["cpu"]["3"]["vendor_id"]).to eql("GenuineIntel")
        expect(@plugin["cpu"]["1"]["vendor_id"]).to eql("GenuineIntel")
        # CPU Socket 1
        expect(@plugin["cpu"]["14"]["vendor_id"]).to eql("CrazyTown")
        expect(@plugin["cpu"]["12"]["vendor_id"]).to eql("CrazyTown")
        expect(@plugin["cpu"]["10"]["vendor_id"]).to eql("CrazyTown")
        expect(@plugin["cpu"]["8"]["vendor_id"]).to eql("CrazyTown")
        expect(@plugin["cpu"]["6"]["vendor_id"]).to eql("CrazyTown")
        expect(@plugin["cpu"]["4"]["vendor_id"]).to eql("CrazyTown")
        expect(@plugin["cpu"]["2"]["vendor_id"]).to eql("CrazyTown")
        expect(@plugin["cpu"]["0"]["vendor_id"]).to eql("CrazyTown")
      end

      it "should include processor families" do
        expect(@plugin["cpu"]["15"]["family"]).to eql("6")
        expect(@plugin["cpu"]["13"]["family"]).to eql("6")
        expect(@plugin["cpu"]["11"]["family"]).to eql("6")
        expect(@plugin["cpu"]["9"]["family"]).to eql("6")
        expect(@plugin["cpu"]["7"]["family"]).to eql("6")
        expect(@plugin["cpu"]["5"]["family"]).to eql("6")
        expect(@plugin["cpu"]["3"]["family"]).to eql("6")
        expect(@plugin["cpu"]["1"]["family"]).to eql("6")

        expect(@plugin["cpu"]["14"]["family"]).to eql("12")
        expect(@plugin["cpu"]["12"]["family"]).to eql("12")
        expect(@plugin["cpu"]["10"]["family"]).to eql("12")
        expect(@plugin["cpu"]["8"]["family"]).to eql("12")
        expect(@plugin["cpu"]["6"]["family"]).to eql("12")
        expect(@plugin["cpu"]["4"]["family"]).to eql("12")
        expect(@plugin["cpu"]["2"]["family"]).to eql("12")
        expect(@plugin["cpu"]["0"]["family"]).to eql("12")
      end

      it "should include processor models" do
        expect(@plugin["cpu"]["15"]["model"]).to eql("26")
        expect(@plugin["cpu"]["13"]["model"]).to eql("26")
        expect(@plugin["cpu"]["11"]["model"]).to eql("26")
        expect(@plugin["cpu"]["9"]["model"]).to eql("26")
        expect(@plugin["cpu"]["7"]["model"]).to eql("26")
        expect(@plugin["cpu"]["5"]["model"]).to eql("26")
        expect(@plugin["cpu"]["3"]["model"]).to eql("26")
        expect(@plugin["cpu"]["1"]["model"]).to eql("26")

        expect(@plugin["cpu"]["14"]["model"]).to eql("93")
        expect(@plugin["cpu"]["12"]["model"]).to eql("93")
        expect(@plugin["cpu"]["10"]["model"]).to eql("93")
        expect(@plugin["cpu"]["8"]["model"]).to eql("93")
        expect(@plugin["cpu"]["6"]["model"]).to eql("93")
        expect(@plugin["cpu"]["4"]["model"]).to eql("93")
        expect(@plugin["cpu"]["2"]["model"]).to eql("93")
        expect(@plugin["cpu"]["0"]["model"]).to eql("93")
      end

      it "should includ processor architecture" do
        expect(@plugin["cpu"]["15"]["arch"]).to eql("i386")
        expect(@plugin["cpu"]["13"]["arch"]).to eql("i386")
        expect(@plugin["cpu"]["11"]["arch"]).to eql("i386")
        expect(@plugin["cpu"]["9"]["arch"]).to eql("i386")
        expect(@plugin["cpu"]["7"]["arch"]).to eql("i386")
        expect(@plugin["cpu"]["5"]["arch"]).to eql("i386")
        expect(@plugin["cpu"]["3"]["arch"]).to eql("i386")
        expect(@plugin["cpu"]["1"]["arch"]).to eql("i386")

        expect(@plugin["cpu"]["14"]["arch"]).to eql("i386")
        expect(@plugin["cpu"]["12"]["arch"]).to eql("i386")
        expect(@plugin["cpu"]["10"]["arch"]).to eql("i386")
        expect(@plugin["cpu"]["8"]["arch"]).to eql("i386")
        expect(@plugin["cpu"]["6"]["arch"]).to eql("i386")
        expect(@plugin["cpu"]["4"]["arch"]).to eql("i386")
        expect(@plugin["cpu"]["2"]["arch"]).to eql("i386")
        expect(@plugin["cpu"]["0"]["arch"]).to eql("i386")
      end

      it "should include processor stepping" do
        expect(@plugin["cpu"]["15"]["stepping"]).to eql("5")
        expect(@plugin["cpu"]["13"]["stepping"]).to eql("5")
        expect(@plugin["cpu"]["11"]["stepping"]).to eql("5")
        expect(@plugin["cpu"]["9"]["stepping"]).to eql("5")
        expect(@plugin["cpu"]["7"]["stepping"]).to eql("5")
        expect(@plugin["cpu"]["5"]["stepping"]).to eql("5")
        expect(@plugin["cpu"]["3"]["stepping"]).to eql("5")
        expect(@plugin["cpu"]["1"]["stepping"]).to eql("5")

        expect(@plugin["cpu"]["14"]["stepping"]).to eql("9")
        expect(@plugin["cpu"]["12"]["stepping"]).to eql("9")
        expect(@plugin["cpu"]["10"]["stepping"]).to eql("9")
        expect(@plugin["cpu"]["8"]["stepping"]).to eql("9")
        expect(@plugin["cpu"]["6"]["stepping"]).to eql("9")
        expect(@plugin["cpu"]["4"]["stepping"]).to eql("9")
        expect(@plugin["cpu"]["2"]["stepping"]).to eql("9")
        expect(@plugin["cpu"]["0"]["stepping"]).to eql("9")

      end

      it "should include processor model names" do
        expect(@plugin["cpu"]["15"]["model_name"]).to eql("Intel(r) Xeon(r) CPU X5570 @ 2.93GHz")
        expect(@plugin["cpu"]["13"]["model_name"]).to eql("Intel(r) Xeon(r) CPU X5570 @ 2.93GHz")
        expect(@plugin["cpu"]["11"]["model_name"]).to eql("Intel(r) Xeon(r) CPU X5570 @ 2.93GHz")
        expect(@plugin["cpu"]["9"]["model_name"]).to eql("Intel(r) Xeon(r) CPU X5570 @ 2.93GHz")
        expect(@plugin["cpu"]["7"]["model_name"]).to eql("Intel(r) Xeon(r) CPU X5570 @ 2.93GHz")
        expect(@plugin["cpu"]["5"]["model_name"]).to eql("Intel(r) Xeon(r) CPU X5570 @ 2.93GHz")
        expect(@plugin["cpu"]["3"]["model_name"]).to eql("Intel(r) Xeon(r) CPU X5570 @ 2.93GHz")
        expect(@plugin["cpu"]["1"]["model_name"]).to eql("Intel(r) Xeon(r) CPU X5570 @ 2.93GHz")
        expect(@plugin["cpu"]["14"]["model_name"]).to eql("Crazy(r) Argon(r) CPU Y5570 @ 1.93GHz")
        expect(@plugin["cpu"]["12"]["model_name"]).to eql("Crazy(r) Argon(r) CPU Y5570 @ 1.93GHz")
        expect(@plugin["cpu"]["10"]["model_name"]).to eql("Crazy(r) Argon(r) CPU Y5570 @ 1.93GHz")
        expect(@plugin["cpu"]["8"]["model_name"]).to eql("Crazy(r) Argon(r) CPU Y5570 @ 1.93GHz")
        expect(@plugin["cpu"]["6"]["model_name"]).to eql("Crazy(r) Argon(r) CPU Y5570 @ 1.93GHz")
        expect(@plugin["cpu"]["4"]["model_name"]).to eql("Crazy(r) Argon(r) CPU Y5570 @ 1.93GHz")
        expect(@plugin["cpu"]["2"]["model_name"]).to eql("Crazy(r) Argon(r) CPU Y5570 @ 1.93GHz")
        expect(@plugin["cpu"]["0"]["model_name"]).to eql("Crazy(r) Argon(r) CPU Y5570 @ 1.93GHz")
      end

      it "should include processor speed in MHz" do
        expect(@plugin["cpu"]["15"]["mhz"]).to eql("2926")
        expect(@plugin["cpu"]["13"]["mhz"]).to eql("2926")
        expect(@plugin["cpu"]["11"]["mhz"]).to eql("2926")
        expect(@plugin["cpu"]["9"]["mhz"]).to eql("2926")
        expect(@plugin["cpu"]["7"]["mhz"]).to eql("2926")
        expect(@plugin["cpu"]["5"]["mhz"]).to eql("2926")
        expect(@plugin["cpu"]["3"]["mhz"]).to eql("2926")
        expect(@plugin["cpu"]["1"]["mhz"]).to eql("2926")
        expect(@plugin["cpu"]["14"]["mhz"]).to eql("1933")
        expect(@plugin["cpu"]["12"]["mhz"]).to eql("1933")
        expect(@plugin["cpu"]["10"]["mhz"]).to eql("1933")
        expect(@plugin["cpu"]["8"]["mhz"]).to eql("1933")
        expect(@plugin["cpu"]["6"]["mhz"]).to eql("1933")
        expect(@plugin["cpu"]["4"]["mhz"]).to eql("1933")
        expect(@plugin["cpu"]["2"]["mhz"]).to eql("1933")
        expect(@plugin["cpu"]["0"]["mhz"]).to eql("1933")
      end

      it "should include processor state" do
        expect(@plugin["cpu"]["15"]["state"]).to eql("on-line")
        expect(@plugin["cpu"]["13"]["state"]).to eql("on-line")
        expect(@plugin["cpu"]["11"]["state"]).to eql("on-line")
        expect(@plugin["cpu"]["9"]["state"]).to eql("on-line")
        expect(@plugin["cpu"]["7"]["state"]).to eql("on-line")
        expect(@plugin["cpu"]["5"]["state"]).to eql("on-line")
        expect(@plugin["cpu"]["3"]["state"]).to eql("on-line")
        expect(@plugin["cpu"]["1"]["state"]).to eql("on-line")
        expect(@plugin["cpu"]["14"]["state"]).to eql("off-line")
        expect(@plugin["cpu"]["12"]["state"]).to eql("off-line")
        expect(@plugin["cpu"]["10"]["state"]).to eql("off-line")
        expect(@plugin["cpu"]["8"]["state"]).to eql("off-line")
        expect(@plugin["cpu"]["6"]["state"]).to eql("off-line")
        expect(@plugin["cpu"]["4"]["state"]).to eql("off-line")
        expect(@plugin["cpu"]["2"]["state"]).to eql("off-line")
        expect(@plugin["cpu"]["0"]["state"]).to eql("off-line")
      end
    end
  end

  describe "on sparc processors" do
    before(:each) do
      kstatinfo_output = <<-END
cpu_info:0:cpu_info0:brand	SPARC-T3
cpu_info:0:cpu_info0:chip_id	0
cpu_info:0:cpu_info0:class	misc
cpu_info:0:cpu_info0:clock_MHz	1649
cpu_info:0:cpu_info0:core_id	1026
cpu_info:0:cpu_info0:cpu_fru	hc:///component=
cpu_info:0:cpu_info0:cpu_type	sparcv9
cpu_info:0:cpu_info0:crtime	182.755017565
cpu_info:0:cpu_info0:current_clock_Hz	1648762500
cpu_info:0:cpu_info0:device_ID	0
cpu_info:0:cpu_info0:fpu_type	sparcv9
cpu_info:0:cpu_info0:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:0:cpu_info0:pg_id	1
cpu_info:0:cpu_info0:snaptime	9305222.45903973
cpu_info:0:cpu_info0:state	on-line
cpu_info:0:cpu_info0:state_begin	1430258900
cpu_info:0:cpu_info0:supported_frequencies_Hz	1648762500
cpu_info:1:cpu_info1:brand	SPARC-T3
cpu_info:1:cpu_info1:chip_id	0
cpu_info:1:cpu_info1:class	misc
cpu_info:1:cpu_info1:clock_MHz	1649
cpu_info:1:cpu_info1:core_id	1026
cpu_info:1:cpu_info1:cpu_fru	hc:///component=
cpu_info:1:cpu_info1:cpu_type	sparcv9
cpu_info:1:cpu_info1:crtime	185.891012056
cpu_info:1:cpu_info1:current_clock_Hz	1648762500
cpu_info:1:cpu_info1:device_ID	1
cpu_info:1:cpu_info1:fpu_type	sparcv9
cpu_info:1:cpu_info1:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:1:cpu_info1:pg_id	1
cpu_info:1:cpu_info1:snaptime	9305222.46043854
cpu_info:1:cpu_info1:state	on-line
cpu_info:1:cpu_info1:state_begin	1430258903
cpu_info:1:cpu_info1:supported_frequencies_Hz	1648762500
cpu_info:2:cpu_info2:brand	SPARC-T3
cpu_info:2:cpu_info2:chip_id	0
cpu_info:2:cpu_info2:class	misc
cpu_info:2:cpu_info2:clock_MHz	1649
cpu_info:2:cpu_info2:core_id	1026
cpu_info:2:cpu_info2:cpu_fru	hc:///component=
cpu_info:2:cpu_info2:cpu_type	sparcv9
cpu_info:2:cpu_info2:crtime	185.89327726
cpu_info:2:cpu_info2:current_clock_Hz	1648762500
cpu_info:2:cpu_info2:device_ID	2
cpu_info:2:cpu_info2:fpu_type	sparcv9
cpu_info:2:cpu_info2:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:2:cpu_info2:pg_id	1
cpu_info:2:cpu_info2:snaptime	9305222.46159979
cpu_info:2:cpu_info2:state	on-line
cpu_info:2:cpu_info2:state_begin	1430258903
cpu_info:2:cpu_info2:supported_frequencies_Hz	1648762500
cpu_info:3:cpu_info3:brand	SPARC-T3
cpu_info:3:cpu_info3:chip_id	0
cpu_info:3:cpu_info3:class	misc
cpu_info:3:cpu_info3:clock_MHz	1649
cpu_info:3:cpu_info3:core_id	1026
cpu_info:3:cpu_info3:cpu_fru	hc:///component=
cpu_info:3:cpu_info3:cpu_type	sparcv9
cpu_info:3:cpu_info3:crtime	185.895286738
cpu_info:3:cpu_info3:current_clock_Hz	1648762500
cpu_info:3:cpu_info3:device_ID	3
cpu_info:3:cpu_info3:fpu_type	sparcv9
cpu_info:3:cpu_info3:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:3:cpu_info3:pg_id	1
cpu_info:3:cpu_info3:snaptime	9305222.46276104
cpu_info:3:cpu_info3:state	on-line
cpu_info:3:cpu_info3:state_begin	1430258903
cpu_info:3:cpu_info3:supported_frequencies_Hz	1648762500
cpu_info:4:cpu_info4:brand	SPARC-T3
cpu_info:4:cpu_info4:chip_id	0
cpu_info:4:cpu_info4:class	misc
cpu_info:4:cpu_info4:clock_MHz	1649
cpu_info:4:cpu_info4:core_id	1026
cpu_info:4:cpu_info4:cpu_fru	hc:///component=
cpu_info:4:cpu_info4:cpu_type	sparcv9
cpu_info:4:cpu_info4:crtime	185.897635787
cpu_info:4:cpu_info4:current_clock_Hz	1648762500
cpu_info:4:cpu_info4:device_ID	4
cpu_info:4:cpu_info4:fpu_type	sparcv9
cpu_info:4:cpu_info4:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:4:cpu_info4:pg_id	4
cpu_info:4:cpu_info4:snaptime	9305222.46392368
cpu_info:4:cpu_info4:state	on-line
cpu_info:4:cpu_info4:state_begin	1430258903
cpu_info:4:cpu_info4:supported_frequencies_Hz	1648762500
cpu_info:5:cpu_info5:brand	SPARC-T3
cpu_info:5:cpu_info5:chip_id	0
cpu_info:5:cpu_info5:class	misc
cpu_info:5:cpu_info5:clock_MHz	1649
cpu_info:5:cpu_info5:core_id	1026
cpu_info:5:cpu_info5:cpu_fru	hc:///component=
cpu_info:5:cpu_info5:cpu_type	sparcv9
cpu_info:5:cpu_info5:crtime	185.899706751
cpu_info:5:cpu_info5:current_clock_Hz	1648762500
cpu_info:5:cpu_info5:device_ID	5
cpu_info:5:cpu_info5:fpu_type	sparcv9
cpu_info:5:cpu_info5:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:5:cpu_info5:pg_id	4
cpu_info:5:cpu_info5:snaptime	9305222.4651017
cpu_info:5:cpu_info5:state	on-line
cpu_info:5:cpu_info5:state_begin	1430258903
cpu_info:5:cpu_info5:supported_frequencies_Hz	1648762500
cpu_info:6:cpu_info6:brand	SPARC-T3
cpu_info:6:cpu_info6:chip_id	0
cpu_info:6:cpu_info6:class	misc
cpu_info:6:cpu_info6:clock_MHz	1649
cpu_info:6:cpu_info6:core_id	1026
cpu_info:6:cpu_info6:cpu_fru	hc:///component=
cpu_info:6:cpu_info6:cpu_type	sparcv9
cpu_info:6:cpu_info6:crtime	185.901703653
cpu_info:6:cpu_info6:current_clock_Hz	1648762500
cpu_info:6:cpu_info6:device_ID	6
cpu_info:6:cpu_info6:fpu_type	sparcv9
cpu_info:6:cpu_info6:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:6:cpu_info6:pg_id	4
cpu_info:6:cpu_info6:snaptime	9305222.46627134
cpu_info:6:cpu_info6:state	on-line
cpu_info:6:cpu_info6:state_begin	1430258903
cpu_info:6:cpu_info6:supported_frequencies_Hz	1648762500
cpu_info:7:cpu_info7:brand	SPARC-T3
cpu_info:7:cpu_info7:chip_id	0
cpu_info:7:cpu_info7:class	misc
cpu_info:7:cpu_info7:clock_MHz	1649
cpu_info:7:cpu_info7:core_id	1026
cpu_info:7:cpu_info7:cpu_fru	hc:///component=
cpu_info:7:cpu_info7:cpu_type	sparcv9
cpu_info:7:cpu_info7:crtime	185.903769027
cpu_info:7:cpu_info7:current_clock_Hz	1648762500
cpu_info:7:cpu_info7:device_ID	7
cpu_info:7:cpu_info7:fpu_type	sparcv9
cpu_info:7:cpu_info7:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:7:cpu_info7:pg_id	4
cpu_info:7:cpu_info7:snaptime	9305222.46743538
cpu_info:7:cpu_info7:state	on-line
cpu_info:7:cpu_info7:state_begin	1430258903
cpu_info:7:cpu_info7:supported_frequencies_Hz	1648762500
cpu_info:8:cpu_info8:brand	SPARC-T3
cpu_info:8:cpu_info8:chip_id	0
cpu_info:8:cpu_info8:class	misc
cpu_info:8:cpu_info8:clock_MHz	1649
cpu_info:8:cpu_info8:core_id	1033
cpu_info:8:cpu_info8:cpu_fru	hc:///component=
cpu_info:8:cpu_info8:cpu_type	sparcv9
cpu_info:8:cpu_info8:crtime	185.905770121
cpu_info:8:cpu_info8:current_clock_Hz	1648762500
cpu_info:8:cpu_info8:device_ID	8
cpu_info:8:cpu_info8:fpu_type	sparcv9
cpu_info:8:cpu_info8:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:8:cpu_info8:pg_id	5
cpu_info:8:cpu_info8:snaptime	9305222.46859244
cpu_info:8:cpu_info8:state	on-line
cpu_info:8:cpu_info8:state_begin	1430258903
cpu_info:8:cpu_info8:supported_frequencies_Hz	1648762500
cpu_info:9:cpu_info9:brand	SPARC-T3
cpu_info:9:cpu_info9:chip_id	0
cpu_info:9:cpu_info9:class	misc
cpu_info:9:cpu_info9:clock_MHz	1649
cpu_info:9:cpu_info9:core_id	1033
cpu_info:9:cpu_info9:cpu_fru	hc:///component=
cpu_info:9:cpu_info9:cpu_type	sparcv9
cpu_info:9:cpu_info9:crtime	185.907807547
cpu_info:9:cpu_info9:current_clock_Hz	1648762500
cpu_info:9:cpu_info9:device_ID	9
cpu_info:9:cpu_info9:fpu_type	sparcv9
cpu_info:9:cpu_info9:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:9:cpu_info9:pg_id	5
cpu_info:9:cpu_info9:snaptime	9305222.46975928
cpu_info:9:cpu_info9:state	on-line
cpu_info:9:cpu_info9:state_begin	1430258903
cpu_info:9:cpu_info9:supported_frequencies_Hz	1648762500
cpu_info:10:cpu_info10:brand	SPARC-T3
cpu_info:10:cpu_info10:chip_id	0
cpu_info:10:cpu_info10:class	misc
cpu_info:10:cpu_info10:clock_MHz	1649
cpu_info:10:cpu_info10:core_id	1033
cpu_info:10:cpu_info10:cpu_fru	hc:///component=
cpu_info:10:cpu_info10:cpu_type	sparcv9
cpu_info:10:cpu_info10:crtime	185.909912049
cpu_info:10:cpu_info10:current_clock_Hz	1648762500
cpu_info:10:cpu_info10:device_ID	10
cpu_info:10:cpu_info10:fpu_type	sparcv9
cpu_info:10:cpu_info10:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:10:cpu_info10:pg_id	5
cpu_info:10:cpu_info10:snaptime	9305222.47092053
cpu_info:10:cpu_info10:state	on-line
cpu_info:10:cpu_info10:state_begin	1430258903
cpu_info:10:cpu_info10:supported_frequencies_Hz	1648762500
cpu_info:11:cpu_info11:brand	SPARC-T3
cpu_info:11:cpu_info11:chip_id	0
cpu_info:11:cpu_info11:class	misc
cpu_info:11:cpu_info11:clock_MHz	1649
cpu_info:11:cpu_info11:core_id	1033
cpu_info:11:cpu_info11:cpu_fru	hc:///component=
cpu_info:11:cpu_info11:cpu_type	sparcv9
cpu_info:11:cpu_info11:crtime	185.912115767
cpu_info:11:cpu_info11:current_clock_Hz	1648762500
cpu_info:11:cpu_info11:device_ID	11
cpu_info:11:cpu_info11:fpu_type	sparcv9
cpu_info:11:cpu_info11:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:11:cpu_info11:pg_id	5
cpu_info:11:cpu_info11:snaptime	9305222.47210972
cpu_info:11:cpu_info11:state	on-line
cpu_info:11:cpu_info11:state_begin	1430258903
cpu_info:11:cpu_info11:supported_frequencies_Hz	1648762500
cpu_info:12:cpu_info12:brand	SPARC-T3
cpu_info:12:cpu_info12:chip_id	0
cpu_info:12:cpu_info12:class	misc
cpu_info:12:cpu_info12:clock_MHz	1649
cpu_info:12:cpu_info12:core_id	1033
cpu_info:12:cpu_info12:cpu_fru	hc:///component=
cpu_info:12:cpu_info12:cpu_type	sparcv9
cpu_info:12:cpu_info12:crtime	185.914137822
cpu_info:12:cpu_info12:current_clock_Hz	1648762500
cpu_info:12:cpu_info12:device_ID	12
cpu_info:12:cpu_info12:fpu_type	sparcv9
cpu_info:12:cpu_info12:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:12:cpu_info12:pg_id	7
cpu_info:12:cpu_info12:snaptime	9305222.47335901
cpu_info:12:cpu_info12:state	on-line
cpu_info:12:cpu_info12:state_begin	1430258903
cpu_info:12:cpu_info12:supported_frequencies_Hz	1648762500
cpu_info:13:cpu_info13:brand	SPARC-T3
cpu_info:13:cpu_info13:chip_id	0
cpu_info:13:cpu_info13:class	misc
cpu_info:13:cpu_info13:clock_MHz	1649
cpu_info:13:cpu_info13:core_id	1033
cpu_info:13:cpu_info13:cpu_fru	hc:///component=
cpu_info:13:cpu_info13:cpu_type	sparcv9
cpu_info:13:cpu_info13:crtime	185.916718841
cpu_info:13:cpu_info13:current_clock_Hz	1648762500
cpu_info:13:cpu_info13:device_ID	13
cpu_info:13:cpu_info13:fpu_type	sparcv9
cpu_info:13:cpu_info13:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:13:cpu_info13:pg_id	7
cpu_info:13:cpu_info13:snaptime	9305222.47452166
cpu_info:13:cpu_info13:state	on-line
cpu_info:13:cpu_info13:state_begin	1430258903
cpu_info:13:cpu_info13:supported_frequencies_Hz	1648762500
cpu_info:14:cpu_info14:brand	SPARC-T3
cpu_info:14:cpu_info14:chip_id	0
cpu_info:14:cpu_info14:class	misc
cpu_info:14:cpu_info14:clock_MHz	1649
cpu_info:14:cpu_info14:core_id	1033
cpu_info:14:cpu_info14:cpu_fru	hc:///component=
cpu_info:14:cpu_info14:cpu_type	sparcv9
cpu_info:14:cpu_info14:crtime	185.918743691
cpu_info:14:cpu_info14:current_clock_Hz	1648762500
cpu_info:14:cpu_info14:device_ID	14
cpu_info:14:cpu_info14:fpu_type	sparcv9
cpu_info:14:cpu_info14:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:14:cpu_info14:pg_id	7
cpu_info:14:cpu_info14:snaptime	9305222.4756871
cpu_info:14:cpu_info14:state	on-line
cpu_info:14:cpu_info14:state_begin	1430258903
cpu_info:14:cpu_info14:supported_frequencies_Hz	1648762500
cpu_info:15:cpu_info15:brand	SPARC-T3
cpu_info:15:cpu_info15:chip_id	0
cpu_info:15:cpu_info15:class	misc
cpu_info:15:cpu_info15:clock_MHz	1649
cpu_info:15:cpu_info15:core_id	1033
cpu_info:15:cpu_info15:cpu_fru	hc:///component=
cpu_info:15:cpu_info15:cpu_type	sparcv9
cpu_info:15:cpu_info15:crtime	185.920867756
cpu_info:15:cpu_info15:current_clock_Hz	1648762500
cpu_info:15:cpu_info15:device_ID	15
cpu_info:15:cpu_info15:fpu_type	sparcv9
cpu_info:15:cpu_info15:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:15:cpu_info15:pg_id	7
cpu_info:15:cpu_info15:snaptime	9305222.47686092
cpu_info:15:cpu_info15:state	on-line
cpu_info:15:cpu_info15:state_begin	1430258903
cpu_info:15:cpu_info15:supported_frequencies_Hz	1648762500
cpu_info:16:cpu_info16:brand	SPARC-T3
cpu_info:16:cpu_info16:chip_id	0
cpu_info:16:cpu_info16:class	misc
cpu_info:16:cpu_info16:clock_MHz	1649
cpu_info:16:cpu_info16:core_id	1040
cpu_info:16:cpu_info16:cpu_fru	hc:///component=
cpu_info:16:cpu_info16:cpu_type	sparcv9
cpu_info:16:cpu_info16:crtime	185.923040731
cpu_info:16:cpu_info16:current_clock_Hz	1648762500
cpu_info:16:cpu_info16:device_ID	16
cpu_info:16:cpu_info16:fpu_type	sparcv9
cpu_info:16:cpu_info16:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:16:cpu_info16:pg_id	8
cpu_info:16:cpu_info16:snaptime	9305222.47804034
cpu_info:16:cpu_info16:state	on-line
cpu_info:16:cpu_info16:state_begin	1430258903
cpu_info:16:cpu_info16:supported_frequencies_Hz	1648762500
cpu_info:17:cpu_info17:brand	SPARC-T3
cpu_info:17:cpu_info17:chip_id	0
cpu_info:17:cpu_info17:class	misc
cpu_info:17:cpu_info17:clock_MHz	1649
cpu_info:17:cpu_info17:core_id	1040
cpu_info:17:cpu_info17:cpu_fru	hc:///component=
cpu_info:17:cpu_info17:cpu_type	sparcv9
cpu_info:17:cpu_info17:crtime	185.925129862
cpu_info:17:cpu_info17:current_clock_Hz	1648762500
cpu_info:17:cpu_info17:device_ID	17
cpu_info:17:cpu_info17:fpu_type	sparcv9
cpu_info:17:cpu_info17:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:17:cpu_info17:pg_id	8
cpu_info:17:cpu_info17:snaptime	9305222.4791974
cpu_info:17:cpu_info17:state	on-line
cpu_info:17:cpu_info17:state_begin	1430258903
cpu_info:17:cpu_info17:supported_frequencies_Hz	1648762500
cpu_info:18:cpu_info18:brand	SPARC-T3
cpu_info:18:cpu_info18:chip_id	0
cpu_info:18:cpu_info18:class	misc
cpu_info:18:cpu_info18:clock_MHz	1649
cpu_info:18:cpu_info18:core_id	1040
cpu_info:18:cpu_info18:cpu_fru	hc:///component=
cpu_info:18:cpu_info18:cpu_type	sparcv9
cpu_info:18:cpu_info18:crtime	185.927358733
cpu_info:18:cpu_info18:current_clock_Hz	1648762500
cpu_info:18:cpu_info18:device_ID	18
cpu_info:18:cpu_info18:fpu_type	sparcv9
cpu_info:18:cpu_info18:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:18:cpu_info18:pg_id	8
cpu_info:18:cpu_info18:snaptime	9305222.48035585
cpu_info:18:cpu_info18:state	on-line
cpu_info:18:cpu_info18:state_begin	1430258903
cpu_info:18:cpu_info18:supported_frequencies_Hz	1648762500
cpu_info:19:cpu_info19:brand	SPARC-T3
cpu_info:19:cpu_info19:chip_id	0
cpu_info:19:cpu_info19:class	misc
cpu_info:19:cpu_info19:clock_MHz	1649
cpu_info:19:cpu_info19:core_id	1040
cpu_info:19:cpu_info19:cpu_fru	hc:///component=
cpu_info:19:cpu_info19:cpu_type	sparcv9
cpu_info:19:cpu_info19:crtime	185.929506555
cpu_info:19:cpu_info19:current_clock_Hz	1648762500
cpu_info:19:cpu_info19:device_ID	19
cpu_info:19:cpu_info19:fpu_type	sparcv9
cpu_info:19:cpu_info19:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:19:cpu_info19:pg_id	8
cpu_info:19:cpu_info19:snaptime	9305222.4815143
cpu_info:19:cpu_info19:state	on-line
cpu_info:19:cpu_info19:state_begin	1430258903
cpu_info:19:cpu_info19:supported_frequencies_Hz	1648762500
cpu_info:20:cpu_info20:brand	SPARC-T3
cpu_info:20:cpu_info20:chip_id	0
cpu_info:20:cpu_info20:class	misc
cpu_info:20:cpu_info20:clock_MHz	1649
cpu_info:20:cpu_info20:core_id	1040
cpu_info:20:cpu_info20:cpu_fru	hc:///component=
cpu_info:20:cpu_info20:cpu_type	sparcv9
cpu_info:20:cpu_info20:crtime	185.931632019
cpu_info:20:cpu_info20:current_clock_Hz	1648762500
cpu_info:20:cpu_info20:device_ID	20
cpu_info:20:cpu_info20:fpu_type	sparcv9
cpu_info:20:cpu_info20:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:20:cpu_info20:pg_id	10
cpu_info:20:cpu_info20:snaptime	9305222.48268953
cpu_info:20:cpu_info20:state	on-line
cpu_info:20:cpu_info20:state_begin	1430258903
cpu_info:20:cpu_info20:supported_frequencies_Hz	1648762500
cpu_info:21:cpu_info21:brand	SPARC-T3
cpu_info:21:cpu_info21:chip_id	0
cpu_info:21:cpu_info21:class	misc
cpu_info:21:cpu_info21:clock_MHz	1649
cpu_info:21:cpu_info21:core_id	1040
cpu_info:21:cpu_info21:cpu_fru	hc:///component=
cpu_info:21:cpu_info21:cpu_type	sparcv9
cpu_info:21:cpu_info21:crtime	185.933775649
cpu_info:21:cpu_info21:current_clock_Hz	1648762500
cpu_info:21:cpu_info21:device_ID	21
cpu_info:21:cpu_info21:fpu_type	sparcv9
cpu_info:21:cpu_info21:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:21:cpu_info21:pg_id	10
cpu_info:21:cpu_info21:snaptime	9305222.48385497
cpu_info:21:cpu_info21:state	on-line
cpu_info:21:cpu_info21:state_begin	1430258903
cpu_info:21:cpu_info21:supported_frequencies_Hz	1648762500
cpu_info:22:cpu_info22:brand	SPARC-T3
cpu_info:22:cpu_info22:chip_id	0
cpu_info:22:cpu_info22:class	misc
cpu_info:22:cpu_info22:clock_MHz	1649
cpu_info:22:cpu_info22:core_id	1040
cpu_info:22:cpu_info22:cpu_fru	hc:///component=
cpu_info:22:cpu_info22:cpu_type	sparcv9
cpu_info:22:cpu_info22:crtime	185.935894125
cpu_info:22:cpu_info22:current_clock_Hz	1648762500
cpu_info:22:cpu_info22:device_ID	22
cpu_info:22:cpu_info22:fpu_type	sparcv9
cpu_info:22:cpu_info22:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:22:cpu_info22:pg_id	10
cpu_info:22:cpu_info22:snaptime	9305222.48501202
cpu_info:22:cpu_info22:state	on-line
cpu_info:22:cpu_info22:state_begin	1430258903
cpu_info:22:cpu_info22:supported_frequencies_Hz	1648762500
cpu_info:23:cpu_info23:brand	SPARC-T3
cpu_info:23:cpu_info23:chip_id	0
cpu_info:23:cpu_info23:class	misc
cpu_info:23:cpu_info23:clock_MHz	1649
cpu_info:23:cpu_info23:core_id	1040
cpu_info:23:cpu_info23:cpu_fru	hc:///component=
cpu_info:23:cpu_info23:cpu_type	sparcv9
cpu_info:23:cpu_info23:crtime	185.938371736
cpu_info:23:cpu_info23:current_clock_Hz	1648762500
cpu_info:23:cpu_info23:device_ID	23
cpu_info:23:cpu_info23:fpu_type	sparcv9
cpu_info:23:cpu_info23:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:23:cpu_info23:pg_id	10
cpu_info:23:cpu_info23:snaptime	9305222.4862152
cpu_info:23:cpu_info23:state	on-line
cpu_info:23:cpu_info23:state_begin	1430258903
cpu_info:23:cpu_info23:supported_frequencies_Hz	1648762500
cpu_info:24:cpu_info24:brand	SPARC-T3
cpu_info:24:cpu_info24:chip_id	0
cpu_info:24:cpu_info24:class	misc
cpu_info:24:cpu_info24:clock_MHz	1649
cpu_info:24:cpu_info24:core_id	1047
cpu_info:24:cpu_info24:cpu_fru	hc:///component=
cpu_info:24:cpu_info24:cpu_type	sparcv9
cpu_info:24:cpu_info24:crtime	185.94063135
cpu_info:24:cpu_info24:current_clock_Hz	1648762500
cpu_info:24:cpu_info24:device_ID	24
cpu_info:24:cpu_info24:fpu_type	sparcv9
cpu_info:24:cpu_info24:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:24:cpu_info24:pg_id	11
cpu_info:24:cpu_info24:snaptime	9305222.48737505
cpu_info:24:cpu_info24:state	on-line
cpu_info:24:cpu_info24:state_begin	1430258903
cpu_info:24:cpu_info24:supported_frequencies_Hz	1648762500
cpu_info:25:cpu_info25:brand	SPARC-T3
cpu_info:25:cpu_info25:chip_id	0
cpu_info:25:cpu_info25:class	misc
cpu_info:25:cpu_info25:clock_MHz	1649
cpu_info:25:cpu_info25:core_id	1047
cpu_info:25:cpu_info25:cpu_fru	hc:///component=
cpu_info:25:cpu_info25:cpu_type	sparcv9
cpu_info:25:cpu_info25:crtime	185.942830876
cpu_info:25:cpu_info25:current_clock_Hz	1648762500
cpu_info:25:cpu_info25:device_ID	25
cpu_info:25:cpu_info25:fpu_type	sparcv9
cpu_info:25:cpu_info25:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:25:cpu_info25:pg_id	11
cpu_info:25:cpu_info25:snaptime	9305222.48852791
cpu_info:25:cpu_info25:state	on-line
cpu_info:25:cpu_info25:state_begin	1430258903
cpu_info:25:cpu_info25:supported_frequencies_Hz	1648762500
cpu_info:26:cpu_info26:brand	SPARC-T3
cpu_info:26:cpu_info26:chip_id	0
cpu_info:26:cpu_info26:class	misc
cpu_info:26:cpu_info26:clock_MHz	1649
cpu_info:26:cpu_info26:core_id	1047
cpu_info:26:cpu_info26:cpu_fru	hc:///component=
cpu_info:26:cpu_info26:cpu_type	sparcv9
cpu_info:26:cpu_info26:crtime	185.945192502
cpu_info:26:cpu_info26:current_clock_Hz	1648762500
cpu_info:26:cpu_info26:device_ID	26
cpu_info:26:cpu_info26:fpu_type	sparcv9
cpu_info:26:cpu_info26:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:26:cpu_info26:pg_id	11
cpu_info:26:cpu_info26:snaptime	9305222.48970872
cpu_info:26:cpu_info26:state	on-line
cpu_info:26:cpu_info26:state_begin	1430258903
cpu_info:26:cpu_info26:supported_frequencies_Hz	1648762500
cpu_info:27:cpu_info27:brand	SPARC-T3
cpu_info:27:cpu_info27:chip_id	0
cpu_info:27:cpu_info27:class	misc
cpu_info:27:cpu_info27:clock_MHz	1649
cpu_info:27:cpu_info27:core_id	1047
cpu_info:27:cpu_info27:cpu_fru	hc:///component=
cpu_info:27:cpu_info27:cpu_type	sparcv9
cpu_info:27:cpu_info27:crtime	185.947281633
cpu_info:27:cpu_info27:current_clock_Hz	1648762500
cpu_info:27:cpu_info27:device_ID	27
cpu_info:27:cpu_info27:fpu_type	sparcv9
cpu_info:27:cpu_info27:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:27:cpu_info27:pg_id	11
cpu_info:27:cpu_info27:snaptime	9305222.49087556
cpu_info:27:cpu_info27:state	on-line
cpu_info:27:cpu_info27:state_begin	1430258903
cpu_info:27:cpu_info27:supported_frequencies_Hz	1648762500
cpu_info:28:cpu_info28:brand	SPARC-T3
cpu_info:28:cpu_info28:chip_id	0
cpu_info:28:cpu_info28:class	misc
cpu_info:28:cpu_info28:clock_MHz	1649
cpu_info:28:cpu_info28:core_id	1047
cpu_info:28:cpu_info28:cpu_fru	hc:///component=
cpu_info:28:cpu_info28:cpu_type	sparcv9
cpu_info:28:cpu_info28:crtime	185.949373558
cpu_info:28:cpu_info28:current_clock_Hz	1648762500
cpu_info:28:cpu_info28:device_ID	28
cpu_info:28:cpu_info28:fpu_type	sparcv9
cpu_info:28:cpu_info28:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:28:cpu_info28:pg_id	13
cpu_info:28:cpu_info28:snaptime	9305222.49203402
cpu_info:28:cpu_info28:state	on-line
cpu_info:28:cpu_info28:state_begin	1430258903
cpu_info:28:cpu_info28:supported_frequencies_Hz	1648762500
cpu_info:29:cpu_info29:brand	SPARC-T3
cpu_info:29:cpu_info29:chip_id	0
cpu_info:29:cpu_info29:class	misc
cpu_info:29:cpu_info29:clock_MHz	1649
cpu_info:29:cpu_info29:core_id	1047
cpu_info:29:cpu_info29:cpu_fru	hc:///component=
cpu_info:29:cpu_info29:cpu_type	sparcv9
cpu_info:29:cpu_info29:crtime	185.951693261
cpu_info:29:cpu_info29:current_clock_Hz	1648762500
cpu_info:29:cpu_info29:device_ID	29
cpu_info:29:cpu_info29:fpu_type	sparcv9
cpu_info:29:cpu_info29:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:29:cpu_info29:pg_id	13
cpu_info:29:cpu_info29:snaptime	9305222.49319247
cpu_info:29:cpu_info29:state	on-line
cpu_info:29:cpu_info29:state_begin	1430258903
cpu_info:29:cpu_info29:supported_frequencies_Hz	1648762500
cpu_info:30:cpu_info30:brand	SPARC-T3
cpu_info:30:cpu_info30:chip_id	0
cpu_info:30:cpu_info30:class	misc
cpu_info:30:cpu_info30:clock_MHz	1649
cpu_info:30:cpu_info30:core_id	1047
cpu_info:30:cpu_info30:cpu_fru	hc:///component=
cpu_info:30:cpu_info30:cpu_type	sparcv9
cpu_info:30:cpu_info30:crtime	185.956749097
cpu_info:30:cpu_info30:current_clock_Hz	1648762500
cpu_info:30:cpu_info30:device_ID	30
cpu_info:30:cpu_info30:fpu_type	sparcv9
cpu_info:30:cpu_info30:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:30:cpu_info30:pg_id	13
cpu_info:30:cpu_info30:snaptime	9305222.49447669
cpu_info:30:cpu_info30:state	on-line
cpu_info:30:cpu_info30:state_begin	1430258903
cpu_info:30:cpu_info30:supported_frequencies_Hz	1648762500
cpu_info:31:cpu_info31:brand	SPARC-T3
cpu_info:31:cpu_info31:chip_id	0
cpu_info:31:cpu_info31:class	misc
cpu_info:31:cpu_info31:clock_MHz	1649
cpu_info:31:cpu_info31:core_id	1047
cpu_info:31:cpu_info31:cpu_fru	hc:///component=
cpu_info:31:cpu_info31:cpu_type	sparcv9
cpu_info:31:cpu_info31:crtime	185.958863381
cpu_info:31:cpu_info31:current_clock_Hz	1648762500
cpu_info:31:cpu_info31:device_ID	31
cpu_info:31:cpu_info31:fpu_type	sparcv9
cpu_info:31:cpu_info31:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:31:cpu_info31:pg_id	13
cpu_info:31:cpu_info31:snaptime	9305222.49563934
cpu_info:31:cpu_info31:state	on-line
cpu_info:31:cpu_info31:state_begin	1430258903
cpu_info:31:cpu_info31:supported_frequencies_Hz	1648762500
cpu_info:32:cpu_info32:brand	SPARC-T3
cpu_info:32:cpu_info32:chip_id	0
cpu_info:32:cpu_info32:class	misc
cpu_info:32:cpu_info32:clock_MHz	1649
cpu_info:32:cpu_info32:core_id	1054
cpu_info:32:cpu_info32:cpu_fru	hc:///component=
cpu_info:32:cpu_info32:cpu_type	sparcv9
cpu_info:32:cpu_info32:crtime	185.961092252
cpu_info:32:cpu_info32:current_clock_Hz	1648762500
cpu_info:32:cpu_info32:device_ID	32
cpu_info:32:cpu_info32:fpu_type	sparcv9
cpu_info:32:cpu_info32:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:32:cpu_info32:pg_id	14
cpu_info:32:cpu_info32:snaptime	9305222.4967978
cpu_info:32:cpu_info32:state	on-line
cpu_info:32:cpu_info32:state_begin	1430258903
cpu_info:32:cpu_info32:supported_frequencies_Hz	1648762500
cpu_info:33:cpu_info33:brand	SPARC-T3
cpu_info:33:cpu_info33:chip_id	0
cpu_info:33:cpu_info33:class	misc
cpu_info:33:cpu_info33:clock_MHz	1649
cpu_info:33:cpu_info33:core_id	1054
cpu_info:33:cpu_info33:cpu_fru	hc:///component=
cpu_info:33:cpu_info33:cpu_type	sparcv9
cpu_info:33:cpu_info33:crtime	185.96330156
cpu_info:33:cpu_info33:current_clock_Hz	1648762500
cpu_info:33:cpu_info33:device_ID	33
cpu_info:33:cpu_info33:fpu_type	sparcv9
cpu_info:33:cpu_info33:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:33:cpu_info33:pg_id	14
cpu_info:33:cpu_info33:snaptime	9305222.49796044
cpu_info:33:cpu_info33:state	on-line
cpu_info:33:cpu_info33:state_begin	1430258903
cpu_info:33:cpu_info33:supported_frequencies_Hz	1648762500
cpu_info:34:cpu_info34:brand	SPARC-T3
cpu_info:34:cpu_info34:chip_id	0
cpu_info:34:cpu_info34:class	misc
cpu_info:34:cpu_info34:clock_MHz	1649
cpu_info:34:cpu_info34:core_id	1054
cpu_info:34:cpu_info34:cpu_fru	hc:///component=
cpu_info:34:cpu_info34:cpu_type	sparcv9
cpu_info:34:cpu_info34:crtime	185.965719082
cpu_info:34:cpu_info34:current_clock_Hz	1648762500
cpu_info:34:cpu_info34:device_ID	34
cpu_info:34:cpu_info34:fpu_type	sparcv9
cpu_info:34:cpu_info34:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:34:cpu_info34:pg_id	14
cpu_info:34:cpu_info34:snaptime	9305222.49915942
cpu_info:34:cpu_info34:state	on-line
cpu_info:34:cpu_info34:state_begin	1430258903
cpu_info:34:cpu_info34:supported_frequencies_Hz	1648762500
cpu_info:35:cpu_info35:brand	SPARC-T3
cpu_info:35:cpu_info35:chip_id	0
cpu_info:35:cpu_info35:class	misc
cpu_info:35:cpu_info35:clock_MHz	1649
cpu_info:35:cpu_info35:core_id	1054
cpu_info:35:cpu_info35:cpu_fru	hc:///component=
cpu_info:35:cpu_info35:cpu_type	sparcv9
cpu_info:35:cpu_info35:crtime	185.967967518
cpu_info:35:cpu_info35:current_clock_Hz	1648762500
cpu_info:35:cpu_info35:device_ID	35
cpu_info:35:cpu_info35:fpu_type	sparcv9
cpu_info:35:cpu_info35:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:35:cpu_info35:pg_id	14
cpu_info:35:cpu_info35:snaptime	9305222.50033744
cpu_info:35:cpu_info35:state	on-line
cpu_info:35:cpu_info35:state_begin	1430258903
cpu_info:35:cpu_info35:supported_frequencies_Hz	1648762500
cpu_info:36:cpu_info36:brand	SPARC-T3
cpu_info:36:cpu_info36:chip_id	0
cpu_info:36:cpu_info36:class	misc
cpu_info:36:cpu_info36:clock_MHz	1649
cpu_info:36:cpu_info36:core_id	1054
cpu_info:36:cpu_info36:cpu_fru	hc:///component=
cpu_info:36:cpu_info36:cpu_type	sparcv9
cpu_info:36:cpu_info36:crtime	185.970185211
cpu_info:36:cpu_info36:current_clock_Hz	1648762500
cpu_info:36:cpu_info36:device_ID	36
cpu_info:36:cpu_info36:fpu_type	sparcv9
cpu_info:36:cpu_info36:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:36:cpu_info36:pg_id	16
cpu_info:36:cpu_info36:snaptime	9305222.5014931
cpu_info:36:cpu_info36:state	on-line
cpu_info:36:cpu_info36:state_begin	1430258903
cpu_info:36:cpu_info36:supported_frequencies_Hz	1648762500
cpu_info:37:cpu_info37:brand	SPARC-T3
cpu_info:37:cpu_info37:chip_id	0
cpu_info:37:cpu_info37:class	misc
cpu_info:37:cpu_info37:clock_MHz	1649
cpu_info:37:cpu_info37:core_id	1054
cpu_info:37:cpu_info37:cpu_fru	hc:///component=
cpu_info:37:cpu_info37:cpu_type	sparcv9
cpu_info:37:cpu_info37:crtime	185.972471376
cpu_info:37:cpu_info37:current_clock_Hz	1648762500
cpu_info:37:cpu_info37:device_ID	37
cpu_info:37:cpu_info37:fpu_type	sparcv9
cpu_info:37:cpu_info37:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:37:cpu_info37:pg_id	16
cpu_info:37:cpu_info37:snaptime	9305222.50265574
cpu_info:37:cpu_info37:state	on-line
cpu_info:37:cpu_info37:state_begin	1430258903
cpu_info:37:cpu_info37:supported_frequencies_Hz	1648762500
cpu_info:38:cpu_info38:brand	SPARC-T3
cpu_info:38:cpu_info38:chip_id	0
cpu_info:38:cpu_info38:class	misc
cpu_info:38:cpu_info38:clock_MHz	1649
cpu_info:38:cpu_info38:core_id	1054
cpu_info:38:cpu_info38:cpu_fru	hc:///component=
cpu_info:38:cpu_info38:cpu_type	sparcv9
cpu_info:38:cpu_info38:crtime	185.974700248
cpu_info:38:cpu_info38:current_clock_Hz	1648762500
cpu_info:38:cpu_info38:device_ID	38
cpu_info:38:cpu_info38:fpu_type	sparcv9
cpu_info:38:cpu_info38:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:38:cpu_info38:pg_id	16
cpu_info:38:cpu_info38:snaptime	9305222.50383516
cpu_info:38:cpu_info38:state	on-line
cpu_info:38:cpu_info38:state_begin	1430258903
cpu_info:38:cpu_info38:supported_frequencies_Hz	1648762500
cpu_info:39:cpu_info39:brand	SPARC-T3
cpu_info:39:cpu_info39:chip_id	0
cpu_info:39:cpu_info39:class	misc
cpu_info:39:cpu_info39:clock_MHz	1649
cpu_info:39:cpu_info39:core_id	1054
cpu_info:39:cpu_info39:cpu_fru	hc:///component=
cpu_info:39:cpu_info39:cpu_type	sparcv9
cpu_info:39:cpu_info39:crtime	185.976951478
cpu_info:39:cpu_info39:current_clock_Hz	1648762500
cpu_info:39:cpu_info39:device_ID	39
cpu_info:39:cpu_info39:fpu_type	sparcv9
cpu_info:39:cpu_info39:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:39:cpu_info39:pg_id	16
cpu_info:39:cpu_info39:snaptime	9305222.50499082
cpu_info:39:cpu_info39:state	on-line
cpu_info:39:cpu_info39:state_begin	1430258903
cpu_info:39:cpu_info39:supported_frequencies_Hz	1648762500
cpu_info:40:cpu_info40:brand	SPARC-T3
cpu_info:40:cpu_info40:chip_id	0
cpu_info:40:cpu_info40:class	misc
cpu_info:40:cpu_info40:clock_MHz	1649
cpu_info:40:cpu_info40:core_id	1061
cpu_info:40:cpu_info40:cpu_fru	hc:///component=
cpu_info:40:cpu_info40:cpu_type	sparcv9
cpu_info:40:cpu_info40:crtime	185.979307514
cpu_info:40:cpu_info40:current_clock_Hz	1648762500
cpu_info:40:cpu_info40:device_ID	40
cpu_info:40:cpu_info40:fpu_type	sparcv9
cpu_info:40:cpu_info40:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:40:cpu_info40:pg_id	17
cpu_info:40:cpu_info40:snaptime	9305222.50614788
cpu_info:40:cpu_info40:state	on-line
cpu_info:40:cpu_info40:state_begin	1430258903
cpu_info:40:cpu_info40:supported_frequencies_Hz	1648762500
cpu_info:41:cpu_info41:brand	SPARC-T3
cpu_info:41:cpu_info41:chip_id	0
cpu_info:41:cpu_info41:class	misc
cpu_info:41:cpu_info41:clock_MHz	1649
cpu_info:41:cpu_info41:core_id	1061
cpu_info:41:cpu_info41:cpu_fru	hc:///component=
cpu_info:41:cpu_info41:cpu_type	sparcv9
cpu_info:41:cpu_info41:crtime	185.981589487
cpu_info:41:cpu_info41:current_clock_Hz	1648762500
cpu_info:41:cpu_info41:device_ID	41
cpu_info:41:cpu_info41:fpu_type	sparcv9
cpu_info:41:cpu_info41:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:41:cpu_info41:pg_id	17
cpu_info:41:cpu_info41:snaptime	9305222.50731052
cpu_info:41:cpu_info41:state	on-line
cpu_info:41:cpu_info41:state_begin	1430258903
cpu_info:41:cpu_info41:supported_frequencies_Hz	1648762500
cpu_info:42:cpu_info42:brand	SPARC-T3
cpu_info:42:cpu_info42:chip_id	0
cpu_info:42:cpu_info42:class	misc
cpu_info:42:cpu_info42:clock_MHz	1649
cpu_info:42:cpu_info42:core_id	1061
cpu_info:42:cpu_info42:cpu_fru	hc:///component=
cpu_info:42:cpu_info42:cpu_type	sparcv9
cpu_info:42:cpu_info42:crtime	185.983932946
cpu_info:42:cpu_info42:current_clock_Hz	1648762500
cpu_info:42:cpu_info42:device_ID	42
cpu_info:42:cpu_info42:fpu_type	sparcv9
cpu_info:42:cpu_info42:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:42:cpu_info42:pg_id	17
cpu_info:42:cpu_info42:snaptime	9305222.50847177
cpu_info:42:cpu_info42:state	on-line
cpu_info:42:cpu_info42:state_begin	1430258903
cpu_info:42:cpu_info42:supported_frequencies_Hz	1648762500
cpu_info:43:cpu_info43:brand	SPARC-T3
cpu_info:43:cpu_info43:chip_id	0
cpu_info:43:cpu_info43:class	misc
cpu_info:43:cpu_info43:clock_MHz	1649
cpu_info:43:cpu_info43:core_id	1061
cpu_info:43:cpu_info43:cpu_fru	hc:///component=
cpu_info:43:cpu_info43:cpu_type	sparcv9
cpu_info:43:cpu_info43:crtime	185.986174395
cpu_info:43:cpu_info43:current_clock_Hz	1648762500
cpu_info:43:cpu_info43:device_ID	43
cpu_info:43:cpu_info43:fpu_type	sparcv9
cpu_info:43:cpu_info43:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:43:cpu_info43:pg_id	17
cpu_info:43:cpu_info43:snaptime	9305222.50965119
cpu_info:43:cpu_info43:state	on-line
cpu_info:43:cpu_info43:state_begin	1430258903
cpu_info:43:cpu_info43:supported_frequencies_Hz	1648762500
cpu_info:44:cpu_info44:brand	SPARC-T3
cpu_info:44:cpu_info44:chip_id	0
cpu_info:44:cpu_info44:class	misc
cpu_info:44:cpu_info44:clock_MHz	1649
cpu_info:44:cpu_info44:core_id	1061
cpu_info:44:cpu_info44:cpu_fru	hc:///component=
cpu_info:44:cpu_info44:cpu_type	sparcv9
cpu_info:44:cpu_info44:crtime	185.988461958
cpu_info:44:cpu_info44:current_clock_Hz	1648762500
cpu_info:44:cpu_info44:device_ID	44
cpu_info:44:cpu_info44:fpu_type	sparcv9
cpu_info:44:cpu_info44:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:44:cpu_info44:pg_id	19
cpu_info:44:cpu_info44:snaptime	9305222.51080685
cpu_info:44:cpu_info44:state	on-line
cpu_info:44:cpu_info44:state_begin	1430258903
cpu_info:44:cpu_info44:supported_frequencies_Hz	1648762500
cpu_info:45:cpu_info45:brand	SPARC-T3
cpu_info:45:cpu_info45:chip_id	0
cpu_info:45:cpu_info45:class	misc
cpu_info:45:cpu_info45:clock_MHz	1649
cpu_info:45:cpu_info45:core_id	1061
cpu_info:45:cpu_info45:cpu_fru	hc:///component=
cpu_info:45:cpu_info45:cpu_type	sparcv9
cpu_info:45:cpu_info45:crtime	185.990886467
cpu_info:45:cpu_info45:current_clock_Hz	1648762500
cpu_info:45:cpu_info45:device_ID	45
cpu_info:45:cpu_info45:fpu_type	sparcv9
cpu_info:45:cpu_info45:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:45:cpu_info45:pg_id	19
cpu_info:45:cpu_info45:snaptime	9305222.5119667
cpu_info:45:cpu_info45:state	on-line
cpu_info:45:cpu_info45:state_begin	1430258903
cpu_info:45:cpu_info45:supported_frequencies_Hz	1648762500
cpu_info:46:cpu_info46:brand	SPARC-T3
cpu_info:46:cpu_info46:chip_id	0
cpu_info:46:cpu_info46:class	misc
cpu_info:46:cpu_info46:clock_MHz	1649
cpu_info:46:cpu_info46:core_id	1061
cpu_info:46:cpu_info46:cpu_fru	hc:///component=
cpu_info:46:cpu_info46:cpu_type	sparcv9
cpu_info:46:cpu_info46:crtime	185.993407398
cpu_info:46:cpu_info46:current_clock_Hz	1648762500
cpu_info:46:cpu_info46:device_ID	46
cpu_info:46:cpu_info46:fpu_type	sparcv9
cpu_info:46:cpu_info46:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:46:cpu_info46:pg_id	19
cpu_info:46:cpu_info46:snaptime	9305222.51316568
cpu_info:46:cpu_info46:state	on-line
cpu_info:46:cpu_info46:state_begin	1430258903
cpu_info:46:cpu_info46:supported_frequencies_Hz	1648762500
cpu_info:47:cpu_info47:brand	SPARC-T3
cpu_info:47:cpu_info47:chip_id	0
cpu_info:47:cpu_info47:class	misc
cpu_info:47:cpu_info47:clock_MHz	1649
cpu_info:47:cpu_info47:core_id	1061
cpu_info:47:cpu_info47:cpu_fru	hc:///component=
cpu_info:47:cpu_info47:cpu_type	sparcv9
cpu_info:47:cpu_info47:crtime	185.995799767
cpu_info:47:cpu_info47:current_clock_Hz	1648762500
cpu_info:47:cpu_info47:device_ID	47
cpu_info:47:cpu_info47:fpu_type	sparcv9
cpu_info:47:cpu_info47:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:47:cpu_info47:pg_id	19
cpu_info:47:cpu_info47:snaptime	9305222.51431994
cpu_info:47:cpu_info47:state	on-line
cpu_info:47:cpu_info47:state_begin	1430258903
cpu_info:47:cpu_info47:supported_frequencies_Hz	1648762500
cpu_info:48:cpu_info48:brand	SPARC-T3
cpu_info:48:cpu_info48:chip_id	0
cpu_info:48:cpu_info48:class	misc
cpu_info:48:cpu_info48:clock_MHz	1649
cpu_info:48:cpu_info48:core_id	1068
cpu_info:48:cpu_info48:cpu_fru	hc:///component=
cpu_info:48:cpu_info48:cpu_type	sparcv9
cpu_info:48:cpu_info48:crtime	185.998159995
cpu_info:48:cpu_info48:current_clock_Hz	1648762500
cpu_info:48:cpu_info48:device_ID	48
cpu_info:48:cpu_info48:fpu_type	sparcv9
cpu_info:48:cpu_info48:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:48:cpu_info48:pg_id	20
cpu_info:48:cpu_info48:snaptime	9305222.51549656
cpu_info:48:cpu_info48:state	on-line
cpu_info:48:cpu_info48:state_begin	1430258903
cpu_info:48:cpu_info48:supported_frequencies_Hz	1648762500
cpu_info:49:cpu_info49:brand	SPARC-T3
cpu_info:49:cpu_info49:chip_id	0
cpu_info:49:cpu_info49:class	misc
cpu_info:49:cpu_info49:clock_MHz	1649
cpu_info:49:cpu_info49:core_id	1068
cpu_info:49:cpu_info49:cpu_fru	hc:///component=
cpu_info:49:cpu_info49:cpu_type	sparcv9
cpu_info:49:cpu_info49:crtime	186.000578915
cpu_info:49:cpu_info49:current_clock_Hz	1648762500
cpu_info:49:cpu_info49:device_ID	49
cpu_info:49:cpu_info49:fpu_type	sparcv9
cpu_info:49:cpu_info49:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:49:cpu_info49:pg_id	20
cpu_info:49:cpu_info49:snaptime	9305222.51664943
cpu_info:49:cpu_info49:state	on-line
cpu_info:49:cpu_info49:state_begin	1430258903
cpu_info:49:cpu_info49:supported_frequencies_Hz	1648762500
cpu_info:50:cpu_info50:brand	SPARC-T3
cpu_info:50:cpu_info50:chip_id	0
cpu_info:50:cpu_info50:class	misc
cpu_info:50:cpu_info50:clock_MHz	1649
cpu_info:50:cpu_info50:core_id	1068
cpu_info:50:cpu_info50:cpu_fru	hc:///component=
cpu_info:50:cpu_info50:cpu_type	sparcv9
cpu_info:50:cpu_info50:crtime	186.002997835
cpu_info:50:cpu_info50:current_clock_Hz	1648762500
cpu_info:50:cpu_info50:device_ID	50
cpu_info:50:cpu_info50:fpu_type	sparcv9
cpu_info:50:cpu_info50:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:50:cpu_info50:pg_id	20
cpu_info:50:cpu_info50:snaptime	9305222.51780229
cpu_info:50:cpu_info50:state	on-line
cpu_info:50:cpu_info50:state_begin	1430258903
cpu_info:50:cpu_info50:supported_frequencies_Hz	1648762500
cpu_info:51:cpu_info51:brand	SPARC-T3
cpu_info:51:cpu_info51:chip_id	0
cpu_info:51:cpu_info51:class	misc
cpu_info:51:cpu_info51:clock_MHz	1649
cpu_info:51:cpu_info51:core_id	1068
cpu_info:51:cpu_info51:cpu_fru	hc:///component=
cpu_info:51:cpu_info51:cpu_type	sparcv9
cpu_info:51:cpu_info51:crtime	186.005381819
cpu_info:51:cpu_info51:current_clock_Hz	1648762500
cpu_info:51:cpu_info51:device_ID	51
cpu_info:51:cpu_info51:fpu_type	sparcv9
cpu_info:51:cpu_info51:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:51:cpu_info51:pg_id	20
cpu_info:51:cpu_info51:snaptime	9305222.51896214
cpu_info:51:cpu_info51:state	on-line
cpu_info:51:cpu_info51:state_begin	1430258903
cpu_info:51:cpu_info51:supported_frequencies_Hz	1648762500
cpu_info:52:cpu_info52:brand	SPARC-T3
cpu_info:52:cpu_info52:chip_id	0
cpu_info:52:cpu_info52:class	misc
cpu_info:52:cpu_info52:clock_MHz	1649
cpu_info:52:cpu_info52:core_id	1068
cpu_info:52:cpu_info52:cpu_fru	hc:///component=
cpu_info:52:cpu_info52:cpu_type	sparcv9
cpu_info:52:cpu_info52:crtime	186.007718292
cpu_info:52:cpu_info52:current_clock_Hz	1648762500
cpu_info:52:cpu_info52:device_ID	52
cpu_info:52:cpu_info52:fpu_type	sparcv9
cpu_info:52:cpu_info52:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:52:cpu_info52:pg_id	22
cpu_info:52:cpu_info52:snaptime	9305222.5201206
cpu_info:52:cpu_info52:state	on-line
cpu_info:52:cpu_info52:state_begin	1430258903
cpu_info:52:cpu_info52:supported_frequencies_Hz	1648762500
cpu_info:53:cpu_info53:brand	SPARC-T3
cpu_info:53:cpu_info53:chip_id	0
cpu_info:53:cpu_info53:class	misc
cpu_info:53:cpu_info53:clock_MHz	1649
cpu_info:53:cpu_info53:core_id	1068
cpu_info:53:cpu_info53:cpu_fru	hc:///component=
cpu_info:53:cpu_info53:cpu_type	sparcv9
cpu_info:53:cpu_info53:crtime	186.010135814
cpu_info:53:cpu_info53:current_clock_Hz	1648762500
cpu_info:53:cpu_info53:device_ID	53
cpu_info:53:cpu_info53:fpu_type	sparcv9
cpu_info:53:cpu_info53:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:53:cpu_info53:pg_id	22
cpu_info:53:cpu_info53:snaptime	9305222.52128464
cpu_info:53:cpu_info53:state	on-line
cpu_info:53:cpu_info53:state_begin	1430258903
cpu_info:53:cpu_info53:supported_frequencies_Hz	1648762500
cpu_info:54:cpu_info54:brand	SPARC-T3
cpu_info:54:cpu_info54:chip_id	0
cpu_info:54:cpu_info54:class	misc
cpu_info:54:cpu_info54:clock_MHz	1649
cpu_info:54:cpu_info54:core_id	1068
cpu_info:54:cpu_info54:cpu_fru	hc:///component=
cpu_info:54:cpu_info54:cpu_type	sparcv9
cpu_info:54:cpu_info54:crtime	186.012468094
cpu_info:54:cpu_info54:current_clock_Hz	1648762500
cpu_info:54:cpu_info54:device_ID	54
cpu_info:54:cpu_info54:fpu_type	sparcv9
cpu_info:54:cpu_info54:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:54:cpu_info54:pg_id	22
cpu_info:54:cpu_info54:snaptime	9305222.52246266
cpu_info:54:cpu_info54:state	on-line
cpu_info:54:cpu_info54:state_begin	1430258903
cpu_info:54:cpu_info54:supported_frequencies_Hz	1648762500
cpu_info:55:cpu_info55:brand	SPARC-T3
cpu_info:55:cpu_info55:chip_id	0
cpu_info:55:cpu_info55:class	misc
cpu_info:55:cpu_info55:clock_MHz	1649
cpu_info:55:cpu_info55:core_id	1068
cpu_info:55:cpu_info55:cpu_fru	hc:///component=
cpu_info:55:cpu_info55:cpu_type	sparcv9
cpu_info:55:cpu_info55:crtime	186.015075664
cpu_info:55:cpu_info55:current_clock_Hz	1648762500
cpu_info:55:cpu_info55:device_ID	55
cpu_info:55:cpu_info55:fpu_type	sparcv9
cpu_info:55:cpu_info55:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:55:cpu_info55:pg_id	22
cpu_info:55:cpu_info55:snaptime	9305222.52361692
cpu_info:55:cpu_info55:state	on-line
cpu_info:55:cpu_info55:state_begin	1430258903
cpu_info:55:cpu_info55:supported_frequencies_Hz	1648762500
cpu_info:56:cpu_info56:brand	SPARC-T3
cpu_info:56:cpu_info56:chip_id	0
cpu_info:56:cpu_info56:class	misc
cpu_info:56:cpu_info56:clock_MHz	1649
cpu_info:56:cpu_info56:core_id	1075
cpu_info:56:cpu_info56:cpu_fru	hc:///component=
cpu_info:56:cpu_info56:cpu_type	sparcv9
cpu_info:56:cpu_info56:crtime	186.01747502
cpu_info:56:cpu_info56:current_clock_Hz	1648762500
cpu_info:56:cpu_info56:device_ID	56
cpu_info:56:cpu_info56:fpu_type	sparcv9
cpu_info:56:cpu_info56:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:56:cpu_info56:pg_id	23
cpu_info:56:cpu_info56:snaptime	9305222.52477957
cpu_info:56:cpu_info56:state	on-line
cpu_info:56:cpu_info56:state_begin	1430258903
cpu_info:56:cpu_info56:supported_frequencies_Hz	1648762500
cpu_info:57:cpu_info57:brand	SPARC-T3
cpu_info:57:cpu_info57:chip_id	0
cpu_info:57:cpu_info57:class	misc
cpu_info:57:cpu_info57:clock_MHz	1649
cpu_info:57:cpu_info57:core_id	1075
cpu_info:57:cpu_info57:cpu_fru	hc:///component=
cpu_info:57:cpu_info57:cpu_type	sparcv9
cpu_info:57:cpu_info57:crtime	186.019972195
cpu_info:57:cpu_info57:current_clock_Hz	1648762500
cpu_info:57:cpu_info57:device_ID	57
cpu_info:57:cpu_info57:fpu_type	sparcv9
cpu_info:57:cpu_info57:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:57:cpu_info57:pg_id	23
cpu_info:57:cpu_info57:snaptime	9305222.52599671
cpu_info:57:cpu_info57:state	on-line
cpu_info:57:cpu_info57:state_begin	1430258903
cpu_info:57:cpu_info57:supported_frequencies_Hz	1648762500
cpu_info:58:cpu_info58:brand	SPARC-T3
cpu_info:58:cpu_info58:chip_id	0
cpu_info:58:cpu_info58:class	misc
cpu_info:58:cpu_info58:clock_MHz	1649
cpu_info:58:cpu_info58:core_id	1075
cpu_info:58:cpu_info58:cpu_fru	hc:///component=
cpu_info:58:cpu_info58:cpu_type	sparcv9
cpu_info:58:cpu_info58:crtime	186.022502907
cpu_info:58:cpu_info58:current_clock_Hz	1648762500
cpu_info:58:cpu_info58:device_ID	58
cpu_info:58:cpu_info58:fpu_type	sparcv9
cpu_info:58:cpu_info58:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:58:cpu_info58:pg_id	23
cpu_info:58:cpu_info58:snaptime	9305222.52714958
cpu_info:58:cpu_info58:state	on-line
cpu_info:58:cpu_info58:state_begin	1430258903
cpu_info:58:cpu_info58:supported_frequencies_Hz	1648762500
cpu_info:59:cpu_info59:brand	SPARC-T3
cpu_info:59:cpu_info59:chip_id	0
cpu_info:59:cpu_info59:class	misc
cpu_info:59:cpu_info59:clock_MHz	1649
cpu_info:59:cpu_info59:core_id	1075
cpu_info:59:cpu_info59:cpu_fru	hc:///component=
cpu_info:59:cpu_info59:cpu_type	sparcv9
cpu_info:59:cpu_info59:crtime	186.024843572
cpu_info:59:cpu_info59:current_clock_Hz	1648762500
cpu_info:59:cpu_info59:device_ID	59
cpu_info:59:cpu_info59:fpu_type	sparcv9
cpu_info:59:cpu_info59:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:59:cpu_info59:pg_id	23
cpu_info:59:cpu_info59:snaptime	9305222.52831362
cpu_info:59:cpu_info59:state	on-line
cpu_info:59:cpu_info59:state_begin	1430258903
cpu_info:59:cpu_info59:supported_frequencies_Hz	1648762500
cpu_info:60:cpu_info60:brand	SPARC-T3
cpu_info:60:cpu_info60:chip_id	0
cpu_info:60:cpu_info60:class	misc
cpu_info:60:cpu_info60:clock_MHz	1649
cpu_info:60:cpu_info60:core_id	1075
cpu_info:60:cpu_info60:cpu_fru	hc:///component=
cpu_info:60:cpu_info60:cpu_type	sparcv9
cpu_info:60:cpu_info60:crtime	186.027181442
cpu_info:60:cpu_info60:current_clock_Hz	1648762500
cpu_info:60:cpu_info60:device_ID	60
cpu_info:60:cpu_info60:fpu_type	sparcv9
cpu_info:60:cpu_info60:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:60:cpu_info60:pg_id	25
cpu_info:60:cpu_info60:snaptime	9305222.52947487
cpu_info:60:cpu_info60:state	on-line
cpu_info:60:cpu_info60:state_begin	1430258903
cpu_info:60:cpu_info60:supported_frequencies_Hz	1648762500
cpu_info:61:cpu_info61:brand	SPARC-T3
cpu_info:61:cpu_info61:chip_id	0
cpu_info:61:cpu_info61:class	misc
cpu_info:61:cpu_info61:clock_MHz	1649
cpu_info:61:cpu_info61:core_id	1075
cpu_info:61:cpu_info61:cpu_fru	hc:///component=
cpu_info:61:cpu_info61:cpu_type	sparcv9
cpu_info:61:cpu_info61:crtime	186.029607348
cpu_info:61:cpu_info61:current_clock_Hz	1648762500
cpu_info:61:cpu_info61:device_ID	61
cpu_info:61:cpu_info61:fpu_type	sparcv9
cpu_info:61:cpu_info61:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:61:cpu_info61:pg_id	25
cpu_info:61:cpu_info61:snaptime	9305222.53065289
cpu_info:61:cpu_info61:state	on-line
cpu_info:61:cpu_info61:state_begin	1430258903
cpu_info:61:cpu_info61:supported_frequencies_Hz	1648762500
cpu_info:62:cpu_info62:brand	SPARC-T3
cpu_info:62:cpu_info62:chip_id	0
cpu_info:62:cpu_info62:class	misc
cpu_info:62:cpu_info62:clock_MHz	1649
cpu_info:62:cpu_info62:core_id	1075
cpu_info:62:cpu_info62:cpu_fru	hc:///component=
cpu_info:62:cpu_info62:cpu_type	sparcv9
cpu_info:62:cpu_info62:crtime	186.032326712
cpu_info:62:cpu_info62:current_clock_Hz	1648762500
cpu_info:62:cpu_info62:device_ID	62
cpu_info:62:cpu_info62:fpu_type	sparcv9
cpu_info:62:cpu_info62:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:62:cpu_info62:pg_id	25
cpu_info:62:cpu_info62:snaptime	9305222.53182811
cpu_info:62:cpu_info62:state	on-line
cpu_info:62:cpu_info62:state_begin	1430258903
cpu_info:62:cpu_info62:supported_frequencies_Hz	1648762500
cpu_info:63:cpu_info63:brand	SPARC-T3
cpu_info:63:cpu_info63:chip_id	0
cpu_info:63:cpu_info63:class	misc
cpu_info:63:cpu_info63:clock_MHz	1649
cpu_info:63:cpu_info63:core_id	1075
cpu_info:63:cpu_info63:cpu_fru	hc:///component=
cpu_info:63:cpu_info63:cpu_type	sparcv9
cpu_info:63:cpu_info63:crtime	186.034794541
cpu_info:63:cpu_info63:current_clock_Hz	1648762500
cpu_info:63:cpu_info63:device_ID	63
cpu_info:63:cpu_info63:fpu_type	sparcv9
cpu_info:63:cpu_info63:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:63:cpu_info63:pg_id	25
cpu_info:63:cpu_info63:snaptime	9305222.53301871
cpu_info:63:cpu_info63:state	on-line
cpu_info:63:cpu_info63:state_begin	1430258903
cpu_info:63:cpu_info63:supported_frequencies_Hz	1648762500
cpu_info:64:cpu_info64:brand	SPARC-T3
cpu_info:64:cpu_info64:chip_id	0
cpu_info:64:cpu_info64:class	misc
cpu_info:64:cpu_info64:clock_MHz	1649
cpu_info:64:cpu_info64:core_id	1082
cpu_info:64:cpu_info64:cpu_fru	hc:///component=
cpu_info:64:cpu_info64:cpu_type	sparcv9
cpu_info:64:cpu_info64:crtime	186.037253985
cpu_info:64:cpu_info64:current_clock_Hz	1648762500
cpu_info:64:cpu_info64:device_ID	64
cpu_info:64:cpu_info64:fpu_type	sparcv9
cpu_info:64:cpu_info64:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:64:cpu_info64:pg_id	26
cpu_info:64:cpu_info64:snaptime	9305222.53418415
cpu_info:64:cpu_info64:state	on-line
cpu_info:64:cpu_info64:state_begin	1430258903
cpu_info:64:cpu_info64:supported_frequencies_Hz	1648762500
cpu_info:65:cpu_info65:brand	SPARC-T3
cpu_info:65:cpu_info65:chip_id	0
cpu_info:65:cpu_info65:class	misc
cpu_info:65:cpu_info65:clock_MHz	1649
cpu_info:65:cpu_info65:core_id	1082
cpu_info:65:cpu_info65:cpu_fru	hc:///component=
cpu_info:65:cpu_info65:cpu_type	sparcv9
cpu_info:65:cpu_info65:crtime	186.039909068
cpu_info:65:cpu_info65:current_clock_Hz	1648762500
cpu_info:65:cpu_info65:device_ID	65
cpu_info:65:cpu_info65:fpu_type	sparcv9
cpu_info:65:cpu_info65:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:65:cpu_info65:pg_id	26
cpu_info:65:cpu_info65:snaptime	9305222.53533841
cpu_info:65:cpu_info65:state	on-line
cpu_info:65:cpu_info65:state_begin	1430258903
cpu_info:65:cpu_info65:supported_frequencies_Hz	1648762500
cpu_info:66:cpu_info66:brand	SPARC-T3
cpu_info:66:cpu_info66:chip_id	0
cpu_info:66:cpu_info66:class	misc
cpu_info:66:cpu_info66:clock_MHz	1649
cpu_info:66:cpu_info66:core_id	1082
cpu_info:66:cpu_info66:cpu_fru	hc:///component=
cpu_info:66:cpu_info66:cpu_type	sparcv9
cpu_info:66:cpu_info66:crtime	186.042333577
cpu_info:66:cpu_info66:current_clock_Hz	1648762500
cpu_info:66:cpu_info66:device_ID	66
cpu_info:66:cpu_info66:fpu_type	sparcv9
cpu_info:66:cpu_info66:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:66:cpu_info66:pg_id	26
cpu_info:66:cpu_info66:snaptime	9305222.53649127
cpu_info:66:cpu_info66:state	on-line
cpu_info:66:cpu_info66:state_begin	1430258903
cpu_info:66:cpu_info66:supported_frequencies_Hz	1648762500
cpu_info:67:cpu_info67:brand	SPARC-T3
cpu_info:67:cpu_info67:chip_id	0
cpu_info:67:cpu_info67:class	misc
cpu_info:67:cpu_info67:clock_MHz	1649
cpu_info:67:cpu_info67:core_id	1082
cpu_info:67:cpu_info67:cpu_fru	hc:///component=
cpu_info:67:cpu_info67:cpu_type	sparcv9
cpu_info:67:cpu_info67:crtime	186.044874071
cpu_info:67:cpu_info67:current_clock_Hz	1648762500
cpu_info:67:cpu_info67:device_ID	67
cpu_info:67:cpu_info67:fpu_type	sparcv9
cpu_info:67:cpu_info67:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:67:cpu_info67:pg_id	26
cpu_info:67:cpu_info67:snaptime	9305222.53778388
cpu_info:67:cpu_info67:state	on-line
cpu_info:67:cpu_info67:state_begin	1430258903
cpu_info:67:cpu_info67:supported_frequencies_Hz	1648762500
cpu_info:68:cpu_info68:brand	SPARC-T3
cpu_info:68:cpu_info68:chip_id	0
cpu_info:68:cpu_info68:class	misc
cpu_info:68:cpu_info68:clock_MHz	1649
cpu_info:68:cpu_info68:core_id	1082
cpu_info:68:cpu_info68:cpu_fru	hc:///component=
cpu_info:68:cpu_info68:cpu_type	sparcv9
cpu_info:68:cpu_info68:crtime	186.047410374
cpu_info:68:cpu_info68:current_clock_Hz	1648762500
cpu_info:68:cpu_info68:device_ID	68
cpu_info:68:cpu_info68:fpu_type	sparcv9
cpu_info:68:cpu_info68:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:68:cpu_info68:pg_id	28
cpu_info:68:cpu_info68:snaptime	9305222.53897727
cpu_info:68:cpu_info68:state	on-line
cpu_info:68:cpu_info68:state_begin	1430258903
cpu_info:68:cpu_info68:supported_frequencies_Hz	1648762500
cpu_info:69:cpu_info69:brand	SPARC-T3
cpu_info:69:cpu_info69:chip_id	0
cpu_info:69:cpu_info69:class	misc
cpu_info:69:cpu_info69:clock_MHz	1649
cpu_info:69:cpu_info69:core_id	1082
cpu_info:69:cpu_info69:cpu_fru	hc:///component=
cpu_info:69:cpu_info69:cpu_type	sparcv9
cpu_info:69:cpu_info69:crtime	186.049833485
cpu_info:69:cpu_info69:current_clock_Hz	1648762500
cpu_info:69:cpu_info69:device_ID	69
cpu_info:69:cpu_info69:fpu_type	sparcv9
cpu_info:69:cpu_info69:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:69:cpu_info69:pg_id	28
cpu_info:69:cpu_info69:snaptime	9305222.54013852
cpu_info:69:cpu_info69:state	on-line
cpu_info:69:cpu_info69:state_begin	1430258903
cpu_info:69:cpu_info69:supported_frequencies_Hz	1648762500
cpu_info:70:cpu_info70:brand	SPARC-T3
cpu_info:70:cpu_info70:chip_id	0
cpu_info:70:cpu_info70:class	misc
cpu_info:70:cpu_info70:clock_MHz	1649
cpu_info:70:cpu_info70:core_id	1082
cpu_info:70:cpu_info70:cpu_fru	hc:///component=
cpu_info:70:cpu_info70:cpu_type	sparcv9
cpu_info:70:cpu_info70:crtime	186.052309698
cpu_info:70:cpu_info70:current_clock_Hz	1648762500
cpu_info:70:cpu_info70:device_ID	70
cpu_info:70:cpu_info70:fpu_type	sparcv9
cpu_info:70:cpu_info70:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:70:cpu_info70:pg_id	28
cpu_info:70:cpu_info70:snaptime	9305222.54131234
cpu_info:70:cpu_info70:state	on-line
cpu_info:70:cpu_info70:state_begin	1430258903
cpu_info:70:cpu_info70:supported_frequencies_Hz	1648762500
cpu_info:71:cpu_info71:brand	SPARC-T3
cpu_info:71:cpu_info71:chip_id	0
cpu_info:71:cpu_info71:class	misc
cpu_info:71:cpu_info71:clock_MHz	1649
cpu_info:71:cpu_info71:core_id	1082
cpu_info:71:cpu_info71:cpu_fru	hc:///component=
cpu_info:71:cpu_info71:cpu_type	sparcv9
cpu_info:71:cpu_info71:crtime	186.054795694
cpu_info:71:cpu_info71:current_clock_Hz	1648762500
cpu_info:71:cpu_info71:device_ID	71
cpu_info:71:cpu_info71:fpu_type	sparcv9
cpu_info:71:cpu_info71:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:71:cpu_info71:pg_id	28
cpu_info:71:cpu_info71:snaptime	9305222.54247779
cpu_info:71:cpu_info71:state	on-line
cpu_info:71:cpu_info71:state_begin	1430258903
cpu_info:71:cpu_info71:supported_frequencies_Hz	1648762500
cpu_info:72:cpu_info72:brand	SPARC-T3
cpu_info:72:cpu_info72:chip_id	0
cpu_info:72:cpu_info72:class	misc
cpu_info:72:cpu_info72:clock_MHz	1649
cpu_info:72:cpu_info72:core_id	1089
cpu_info:72:cpu_info72:cpu_fru	hc:///component=
cpu_info:72:cpu_info72:cpu_type	sparcv9
cpu_info:72:cpu_info72:crtime	186.059253437
cpu_info:72:cpu_info72:current_clock_Hz	1648762500
cpu_info:72:cpu_info72:device_ID	72
cpu_info:72:cpu_info72:fpu_type	sparcv9
cpu_info:72:cpu_info72:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:72:cpu_info72:pg_id	29
cpu_info:72:cpu_info72:snaptime	9305222.54363624
cpu_info:72:cpu_info72:state	on-line
cpu_info:72:cpu_info72:state_begin	1430258903
cpu_info:72:cpu_info72:supported_frequencies_Hz	1648762500
cpu_info:73:cpu_info73:brand	SPARC-T3
cpu_info:73:cpu_info73:chip_id	0
cpu_info:73:cpu_info73:class	misc
cpu_info:73:cpu_info73:clock_MHz	1649
cpu_info:73:cpu_info73:core_id	1089
cpu_info:73:cpu_info73:cpu_fru	hc:///component=
cpu_info:73:cpu_info73:cpu_type	sparcv9
cpu_info:73:cpu_info73:crtime	186.062956578
cpu_info:73:cpu_info73:current_clock_Hz	1648762500
cpu_info:73:cpu_info73:device_ID	73
cpu_info:73:cpu_info73:fpu_type	sparcv9
cpu_info:73:cpu_info73:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:73:cpu_info73:pg_id	29
cpu_info:73:cpu_info73:snaptime	9305222.54479609
cpu_info:73:cpu_info73:state	on-line
cpu_info:73:cpu_info73:state_begin	1430258903
cpu_info:73:cpu_info73:supported_frequencies_Hz	1648762500
cpu_info:74:cpu_info74:brand	SPARC-T3
cpu_info:74:cpu_info74:chip_id	0
cpu_info:74:cpu_info74:class	misc
cpu_info:74:cpu_info74:clock_MHz	1649
cpu_info:74:cpu_info74:core_id	1089
cpu_info:74:cpu_info74:cpu_fru	hc:///component=
cpu_info:74:cpu_info74:cpu_type	sparcv9
cpu_info:74:cpu_info74:crtime	186.066589848
cpu_info:74:cpu_info74:current_clock_Hz	1648762500
cpu_info:74:cpu_info74:device_ID	74
cpu_info:74:cpu_info74:fpu_type	sparcv9
cpu_info:74:cpu_info74:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:74:cpu_info74:pg_id	29
cpu_info:74:cpu_info74:snaptime	9305222.54595315
cpu_info:74:cpu_info74:state	on-line
cpu_info:74:cpu_info74:state_begin	1430258903
cpu_info:74:cpu_info74:supported_frequencies_Hz	1648762500
cpu_info:75:cpu_info75:brand	SPARC-T3
cpu_info:75:cpu_info75:chip_id	0
cpu_info:75:cpu_info75:class	misc
cpu_info:75:cpu_info75:clock_MHz	1649
cpu_info:75:cpu_info75:core_id	1089
cpu_info:75:cpu_info75:cpu_fru	hc:///component=
cpu_info:75:cpu_info75:cpu_type	sparcv9
cpu_info:75:cpu_info75:crtime	186.070164428
cpu_info:75:cpu_info75:current_clock_Hz	1648762500
cpu_info:75:cpu_info75:device_ID	75
cpu_info:75:cpu_info75:fpu_type	sparcv9
cpu_info:75:cpu_info75:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:75:cpu_info75:pg_id	29
cpu_info:75:cpu_info75:snaptime	9305222.54710601
cpu_info:75:cpu_info75:state	on-line
cpu_info:75:cpu_info75:state_begin	1430258903
cpu_info:75:cpu_info75:supported_frequencies_Hz	1648762500
cpu_info:76:cpu_info76:brand	SPARC-T3
cpu_info:76:cpu_info76:chip_id	0
cpu_info:76:cpu_info76:class	misc
cpu_info:76:cpu_info76:clock_MHz	1649
cpu_info:76:cpu_info76:core_id	1089
cpu_info:76:cpu_info76:cpu_fru	hc:///component=
cpu_info:76:cpu_info76:cpu_type	sparcv9
cpu_info:76:cpu_info76:crtime	186.074604005
cpu_info:76:cpu_info76:current_clock_Hz	1648762500
cpu_info:76:cpu_info76:device_ID	76
cpu_info:76:cpu_info76:fpu_type	sparcv9
cpu_info:76:cpu_info76:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:76:cpu_info76:pg_id	31
cpu_info:76:cpu_info76:snaptime	9305222.54828683
cpu_info:76:cpu_info76:state	on-line
cpu_info:76:cpu_info76:state_begin	1430258903
cpu_info:76:cpu_info76:supported_frequencies_Hz	1648762500
cpu_info:77:cpu_info77:brand	SPARC-T3
cpu_info:77:cpu_info77:chip_id	0
cpu_info:77:cpu_info77:class	misc
cpu_info:77:cpu_info77:clock_MHz	1649
cpu_info:77:cpu_info77:core_id	1089
cpu_info:77:cpu_info77:cpu_fru	hc:///component=
cpu_info:77:cpu_info77:cpu_type	sparcv9
cpu_info:77:cpu_info77:crtime	186.078156225
cpu_info:77:cpu_info77:current_clock_Hz	1648762500
cpu_info:77:cpu_info77:device_ID	77
cpu_info:77:cpu_info77:fpu_type	sparcv9
cpu_info:77:cpu_info77:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:77:cpu_info77:pg_id	31
cpu_info:77:cpu_info77:snaptime	9305222.54944528
cpu_info:77:cpu_info77:state	on-line
cpu_info:77:cpu_info77:state_begin	1430258903
cpu_info:77:cpu_info77:supported_frequencies_Hz	1648762500
cpu_info:78:cpu_info78:brand	SPARC-T3
cpu_info:78:cpu_info78:chip_id	0
cpu_info:78:cpu_info78:class	misc
cpu_info:78:cpu_info78:clock_MHz	1649
cpu_info:78:cpu_info78:core_id	1089
cpu_info:78:cpu_info78:cpu_fru	hc:///component=
cpu_info:78:cpu_info78:cpu_type	sparcv9
cpu_info:78:cpu_info78:crtime	186.081686087
cpu_info:78:cpu_info78:current_clock_Hz	1648762500
cpu_info:78:cpu_info78:device_ID	78
cpu_info:78:cpu_info78:fpu_type	sparcv9
cpu_info:78:cpu_info78:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:78:cpu_info78:pg_id	31
cpu_info:78:cpu_info78:snaptime	9305222.55061491
cpu_info:78:cpu_info78:state	on-line
cpu_info:78:cpu_info78:state_begin	1430258903
cpu_info:78:cpu_info78:supported_frequencies_Hz	1648762500
cpu_info:79:cpu_info79:brand	SPARC-T3
cpu_info:79:cpu_info79:chip_id	0
cpu_info:79:cpu_info79:class	misc
cpu_info:79:cpu_info79:clock_MHz	1649
cpu_info:79:cpu_info79:core_id	1089
cpu_info:79:cpu_info79:cpu_fru	hc:///component=
cpu_info:79:cpu_info79:cpu_type	sparcv9
cpu_info:79:cpu_info79:crtime	186.08618715
cpu_info:79:cpu_info79:current_clock_Hz	1648762500
cpu_info:79:cpu_info79:device_ID	79
cpu_info:79:cpu_info79:fpu_type	sparcv9
cpu_info:79:cpu_info79:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:79:cpu_info79:pg_id	31
cpu_info:79:cpu_info79:snaptime	9305222.55181809
cpu_info:79:cpu_info79:state	on-line
cpu_info:79:cpu_info79:state_begin	1430258903
cpu_info:79:cpu_info79:supported_frequencies_Hz	1648762500
cpu_info:80:cpu_info80:brand	SPARC-T3
cpu_info:80:cpu_info80:chip_id	0
cpu_info:80:cpu_info80:class	misc
cpu_info:80:cpu_info80:clock_MHz	1649
cpu_info:80:cpu_info80:core_id	1096
cpu_info:80:cpu_info80:cpu_fru	hc:///component=
cpu_info:80:cpu_info80:cpu_type	sparcv9
cpu_info:80:cpu_info80:crtime	186.089729589
cpu_info:80:cpu_info80:current_clock_Hz	1648762500
cpu_info:80:cpu_info80:device_ID	80
cpu_info:80:cpu_info80:fpu_type	sparcv9
cpu_info:80:cpu_info80:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:80:cpu_info80:pg_id	32
cpu_info:80:cpu_info80:snaptime	9305222.5529989
cpu_info:80:cpu_info80:state	on-line
cpu_info:80:cpu_info80:state_begin	1430258903
cpu_info:80:cpu_info80:supported_frequencies_Hz	1648762500
cpu_info:81:cpu_info81:brand	SPARC-T3
cpu_info:81:cpu_info81:chip_id	0
cpu_info:81:cpu_info81:class	misc
cpu_info:81:cpu_info81:clock_MHz	1649
cpu_info:81:cpu_info81:core_id	1096
cpu_info:81:cpu_info81:cpu_fru	hc:///component=
cpu_info:81:cpu_info81:cpu_type	sparcv9
cpu_info:81:cpu_info81:crtime	186.093385218
cpu_info:81:cpu_info81:current_clock_Hz	1648762500
cpu_info:81:cpu_info81:device_ID	81
cpu_info:81:cpu_info81:fpu_type	sparcv9
cpu_info:81:cpu_info81:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:81:cpu_info81:pg_id	32
cpu_info:81:cpu_info81:snaptime	9305222.55415735
cpu_info:81:cpu_info81:state	on-line
cpu_info:81:cpu_info81:state_begin	1430258903
cpu_info:81:cpu_info81:supported_frequencies_Hz	1648762500
cpu_info:82:cpu_info82:brand	SPARC-T3
cpu_info:82:cpu_info82:chip_id	0
cpu_info:82:cpu_info82:class	misc
cpu_info:82:cpu_info82:clock_MHz	1649
cpu_info:82:cpu_info82:core_id	1096
cpu_info:82:cpu_info82:cpu_fru	hc:///component=
cpu_info:82:cpu_info82:cpu_type	sparcv9
cpu_info:82:cpu_info82:crtime	186.096857787
cpu_info:82:cpu_info82:current_clock_Hz	1648762500
cpu_info:82:cpu_info82:device_ID	82
cpu_info:82:cpu_info82:fpu_type	sparcv9
cpu_info:82:cpu_info82:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:82:cpu_info82:pg_id	32
cpu_info:82:cpu_info82:snaptime	9305222.55531301
cpu_info:82:cpu_info82:state	on-line
cpu_info:82:cpu_info82:state_begin	1430258903
cpu_info:82:cpu_info82:supported_frequencies_Hz	1648762500
cpu_info:83:cpu_info83:brand	SPARC-T3
cpu_info:83:cpu_info83:chip_id	0
cpu_info:83:cpu_info83:class	misc
cpu_info:83:cpu_info83:clock_MHz	1649
cpu_info:83:cpu_info83:core_id	1096
cpu_info:83:cpu_info83:cpu_fru	hc:///component=
cpu_info:83:cpu_info83:cpu_type	sparcv9
cpu_info:83:cpu_info83:crtime	186.10044075
cpu_info:83:cpu_info83:current_clock_Hz	1648762500
cpu_info:83:cpu_info83:device_ID	83
cpu_info:83:cpu_info83:fpu_type	sparcv9
cpu_info:83:cpu_info83:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:83:cpu_info83:pg_id	32
cpu_info:83:cpu_info83:snaptime	9305222.55646867
cpu_info:83:cpu_info83:state	on-line
cpu_info:83:cpu_info83:state_begin	1430258903
cpu_info:83:cpu_info83:supported_frequencies_Hz	1648762500
cpu_info:84:cpu_info84:brand	SPARC-T3
cpu_info:84:cpu_info84:chip_id	0
cpu_info:84:cpu_info84:class	misc
cpu_info:84:cpu_info84:clock_MHz	1649
cpu_info:84:cpu_info84:core_id	1096
cpu_info:84:cpu_info84:cpu_fru	hc:///component=
cpu_info:84:cpu_info84:cpu_type	sparcv9
cpu_info:84:cpu_info84:crtime	186.103991574
cpu_info:84:cpu_info84:current_clock_Hz	1648762500
cpu_info:84:cpu_info84:device_ID	84
cpu_info:84:cpu_info84:fpu_type	sparcv9
cpu_info:84:cpu_info84:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:84:cpu_info84:pg_id	34
cpu_info:84:cpu_info84:snaptime	9305222.55762992
cpu_info:84:cpu_info84:state	on-line
cpu_info:84:cpu_info84:state_begin	1430258903
cpu_info:84:cpu_info84:supported_frequencies_Hz	1648762500
cpu_info:85:cpu_info85:brand	SPARC-T3
cpu_info:85:cpu_info85:chip_id	0
cpu_info:85:cpu_info85:class	misc
cpu_info:85:cpu_info85:clock_MHz	1649
cpu_info:85:cpu_info85:core_id	1096
cpu_info:85:cpu_info85:cpu_fru	hc:///component=
cpu_info:85:cpu_info85:cpu_type	sparcv9
cpu_info:85:cpu_info85:crtime	186.107497679
cpu_info:85:cpu_info85:current_clock_Hz	1648762500
cpu_info:85:cpu_info85:device_ID	85
cpu_info:85:cpu_info85:fpu_type	sparcv9
cpu_info:85:cpu_info85:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:85:cpu_info85:pg_id	34
cpu_info:85:cpu_info85:snaptime	9305222.55880235
cpu_info:85:cpu_info85:state	on-line
cpu_info:85:cpu_info85:state_begin	1430258903
cpu_info:85:cpu_info85:supported_frequencies_Hz	1648762500
cpu_info:86:cpu_info86:brand	SPARC-T3
cpu_info:86:cpu_info86:chip_id	0
cpu_info:86:cpu_info86:class	misc
cpu_info:86:cpu_info86:clock_MHz	1649
cpu_info:86:cpu_info86:core_id	1096
cpu_info:86:cpu_info86:cpu_fru	hc:///component=
cpu_info:86:cpu_info86:cpu_type	sparcv9
cpu_info:86:cpu_info86:crtime	186.112561899
cpu_info:86:cpu_info86:current_clock_Hz	1648762500
cpu_info:86:cpu_info86:device_ID	86
cpu_info:86:cpu_info86:fpu_type	sparcv9
cpu_info:86:cpu_info86:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:86:cpu_info86:pg_id	34
cpu_info:86:cpu_info86:snaptime	9305222.55995382
cpu_info:86:cpu_info86:state	on-line
cpu_info:86:cpu_info86:state_begin	1430258903
cpu_info:86:cpu_info86:supported_frequencies_Hz	1648762500
cpu_info:87:cpu_info87:brand	SPARC-T3
cpu_info:87:cpu_info87:chip_id	0
cpu_info:87:cpu_info87:class	misc
cpu_info:87:cpu_info87:clock_MHz	1649
cpu_info:87:cpu_info87:core_id	1096
cpu_info:87:cpu_info87:cpu_fru	hc:///component=
cpu_info:87:cpu_info87:cpu_type	sparcv9
cpu_info:87:cpu_info87:crtime	186.116544523
cpu_info:87:cpu_info87:current_clock_Hz	1648762500
cpu_info:87:cpu_info87:device_ID	87
cpu_info:87:cpu_info87:fpu_type	sparcv9
cpu_info:87:cpu_info87:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:87:cpu_info87:pg_id	34
cpu_info:87:cpu_info87:snaptime	9305222.56116537
cpu_info:87:cpu_info87:state	on-line
cpu_info:87:cpu_info87:state_begin	1430258903
cpu_info:87:cpu_info87:supported_frequencies_Hz	1648762500
cpu_info:88:cpu_info88:brand	SPARC-T3
cpu_info:88:cpu_info88:chip_id	0
cpu_info:88:cpu_info88:class	misc
cpu_info:88:cpu_info88:clock_MHz	1649
cpu_info:88:cpu_info88:core_id	1103
cpu_info:88:cpu_info88:cpu_fru	hc:///component=
cpu_info:88:cpu_info88:cpu_type	sparcv9
cpu_info:88:cpu_info88:crtime	186.120367841
cpu_info:88:cpu_info88:current_clock_Hz	1648762500
cpu_info:88:cpu_info88:device_ID	88
cpu_info:88:cpu_info88:fpu_type	sparcv9
cpu_info:88:cpu_info88:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:88:cpu_info88:pg_id	35
cpu_info:88:cpu_info88:snaptime	9305222.56231964
cpu_info:88:cpu_info88:state	on-line
cpu_info:88:cpu_info88:state_begin	1430258903
cpu_info:88:cpu_info88:supported_frequencies_Hz	1648762500
cpu_info:89:cpu_info89:brand	SPARC-T3
cpu_info:89:cpu_info89:chip_id	0
cpu_info:89:cpu_info89:class	misc
cpu_info:89:cpu_info89:clock_MHz	1649
cpu_info:89:cpu_info89:core_id	1103
cpu_info:89:cpu_info89:cpu_fru	hc:///component=
cpu_info:89:cpu_info89:cpu_type	sparcv9
cpu_info:89:cpu_info89:crtime	186.124051418
cpu_info:89:cpu_info89:current_clock_Hz	1648762500
cpu_info:89:cpu_info89:device_ID	89
cpu_info:89:cpu_info89:fpu_type	sparcv9
cpu_info:89:cpu_info89:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:89:cpu_info89:pg_id	35
cpu_info:89:cpu_info89:snaptime	9305222.56348368
cpu_info:89:cpu_info89:state	on-line
cpu_info:89:cpu_info89:state_begin	1430258903
cpu_info:89:cpu_info89:supported_frequencies_Hz	1648762500
cpu_info:90:cpu_info90:brand	SPARC-T3
cpu_info:90:cpu_info90:chip_id	0
cpu_info:90:cpu_info90:class	misc
cpu_info:90:cpu_info90:clock_MHz	1649
cpu_info:90:cpu_info90:core_id	1103
cpu_info:90:cpu_info90:cpu_fru	hc:///component=
cpu_info:90:cpu_info90:cpu_type	sparcv9
cpu_info:90:cpu_info90:crtime	186.127595254
cpu_info:90:cpu_info90:current_clock_Hz	1648762500
cpu_info:90:cpu_info90:device_ID	90
cpu_info:90:cpu_info90:fpu_type	sparcv9
cpu_info:90:cpu_info90:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:90:cpu_info90:pg_id	35
cpu_info:90:cpu_info90:snaptime	9305222.56470222
cpu_info:90:cpu_info90:state	on-line
cpu_info:90:cpu_info90:state_begin	1430258903
cpu_info:90:cpu_info90:supported_frequencies_Hz	1648762500
cpu_info:91:cpu_info91:brand	SPARC-T3
cpu_info:91:cpu_info91:chip_id	0
cpu_info:91:cpu_info91:class	misc
cpu_info:91:cpu_info91:clock_MHz	1649
cpu_info:91:cpu_info91:core_id	1103
cpu_info:91:cpu_info91:cpu_fru	hc:///component=
cpu_info:91:cpu_info91:cpu_type	sparcv9
cpu_info:91:cpu_info91:crtime	186.131172628
cpu_info:91:cpu_info91:current_clock_Hz	1648762500
cpu_info:91:cpu_info91:device_ID	91
cpu_info:91:cpu_info91:fpu_type	sparcv9
cpu_info:91:cpu_info91:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:91:cpu_info91:pg_id	35
cpu_info:91:cpu_info91:snaptime	9305222.56585928
cpu_info:91:cpu_info91:state	on-line
cpu_info:91:cpu_info91:state_begin	1430258903
cpu_info:91:cpu_info91:supported_frequencies_Hz	1648762500
cpu_info:92:cpu_info92:brand	SPARC-T3
cpu_info:92:cpu_info92:chip_id	0
cpu_info:92:cpu_info92:class	misc
cpu_info:92:cpu_info92:clock_MHz	1649
cpu_info:92:cpu_info92:core_id	1103
cpu_info:92:cpu_info92:cpu_fru	hc:///component=
cpu_info:92:cpu_info92:cpu_type	sparcv9
cpu_info:92:cpu_info92:crtime	186.135181802
cpu_info:92:cpu_info92:current_clock_Hz	1648762500
cpu_info:92:cpu_info92:device_ID	92
cpu_info:92:cpu_info92:fpu_type	sparcv9
cpu_info:92:cpu_info92:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:92:cpu_info92:pg_id	37
cpu_info:92:cpu_info92:snaptime	9305222.56701773
cpu_info:92:cpu_info92:state	on-line
cpu_info:92:cpu_info92:state_begin	1430258903
cpu_info:92:cpu_info92:supported_frequencies_Hz	1648762500
cpu_info:93:cpu_info93:brand	SPARC-T3
cpu_info:93:cpu_info93:chip_id	0
cpu_info:93:cpu_info93:class	misc
cpu_info:93:cpu_info93:clock_MHz	1649
cpu_info:93:cpu_info93:core_id	1103
cpu_info:93:cpu_info93:cpu_fru	hc:///component=
cpu_info:93:cpu_info93:cpu_type	sparcv9
cpu_info:93:cpu_info93:crtime	186.146467299
cpu_info:93:cpu_info93:current_clock_Hz	1648762500
cpu_info:93:cpu_info93:device_ID	93
cpu_info:93:cpu_info93:fpu_type	sparcv9
cpu_info:93:cpu_info93:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:93:cpu_info93:pg_id	37
cpu_info:93:cpu_info93:snaptime	9305222.568172
cpu_info:93:cpu_info93:state	on-line
cpu_info:93:cpu_info93:state_begin	1430258903
cpu_info:93:cpu_info93:supported_frequencies_Hz	1648762500
cpu_info:94:cpu_info94:brand	SPARC-T3
cpu_info:94:cpu_info94:chip_id	0
cpu_info:94:cpu_info94:class	misc
cpu_info:94:cpu_info94:clock_MHz	1649
cpu_info:94:cpu_info94:core_id	1103
cpu_info:94:cpu_info94:cpu_fru	hc:///component=
cpu_info:94:cpu_info94:cpu_type	sparcv9
cpu_info:94:cpu_info94:crtime	186.150243105
cpu_info:94:cpu_info94:current_clock_Hz	1648762500
cpu_info:94:cpu_info94:device_ID	94
cpu_info:94:cpu_info94:fpu_type	sparcv9
cpu_info:94:cpu_info94:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:94:cpu_info94:pg_id	37
cpu_info:94:cpu_info94:snaptime	9305222.56933883
cpu_info:94:cpu_info94:state	on-line
cpu_info:94:cpu_info94:state_begin	1430258903
cpu_info:94:cpu_info94:supported_frequencies_Hz	1648762500
cpu_info:95:cpu_info95:brand	SPARC-T3
cpu_info:95:cpu_info95:chip_id	0
cpu_info:95:cpu_info95:class	misc
cpu_info:95:cpu_info95:clock_MHz	1649
cpu_info:95:cpu_info95:core_id	1103
cpu_info:95:cpu_info95:cpu_fru	hc:///component=
cpu_info:95:cpu_info95:cpu_type	sparcv9
cpu_info:95:cpu_info95:crtime	186.154034283
cpu_info:95:cpu_info95:current_clock_Hz	1648762500
cpu_info:95:cpu_info95:device_ID	95
cpu_info:95:cpu_info95:fpu_type	sparcv9
cpu_info:95:cpu_info95:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:95:cpu_info95:pg_id	37
cpu_info:95:cpu_info95:snaptime	9305222.5705462
cpu_info:95:cpu_info95:state	on-line
cpu_info:95:cpu_info95:state_begin	1430258903
cpu_info:95:cpu_info95:supported_frequencies_Hz	1648762500
cpu_info:96:cpu_info96:brand	SPARC-T3
cpu_info:96:cpu_info96:chip_id	0
cpu_info:96:cpu_info96:class	misc
cpu_info:96:cpu_info96:clock_MHz	1649
cpu_info:96:cpu_info96:core_id	1110
cpu_info:96:cpu_info96:cpu_fru	hc:///component=
cpu_info:96:cpu_info96:cpu_type	sparcv9
cpu_info:96:cpu_info96:crtime	186.157794718
cpu_info:96:cpu_info96:current_clock_Hz	1648762500
cpu_info:96:cpu_info96:device_ID	96
cpu_info:96:cpu_info96:fpu_type	sparcv9
cpu_info:96:cpu_info96:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:96:cpu_info96:pg_id	38
cpu_info:96:cpu_info96:snaptime	9305222.57170186
cpu_info:96:cpu_info96:state	on-line
cpu_info:96:cpu_info96:state_begin	1430258903
cpu_info:96:cpu_info96:supported_frequencies_Hz	1648762500
cpu_info:97:cpu_info97:brand	SPARC-T3
cpu_info:97:cpu_info97:chip_id	0
cpu_info:97:cpu_info97:class	misc
cpu_info:97:cpu_info97:clock_MHz	1649
cpu_info:97:cpu_info97:core_id	1110
cpu_info:97:cpu_info97:cpu_fru	hc:///component=
cpu_info:97:cpu_info97:cpu_type	sparcv9
cpu_info:97:cpu_info97:crtime	186.162034466
cpu_info:97:cpu_info97:current_clock_Hz	1648762500
cpu_info:97:cpu_info97:device_ID	97
cpu_info:97:cpu_info97:fpu_type	sparcv9
cpu_info:97:cpu_info97:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:97:cpu_info97:pg_id	38
cpu_info:97:cpu_info97:snaptime	9305222.57285752
cpu_info:97:cpu_info97:state	on-line
cpu_info:97:cpu_info97:state_begin	1430258903
cpu_info:97:cpu_info97:supported_frequencies_Hz	1648762500
cpu_info:98:cpu_info98:brand	SPARC-T3
cpu_info:98:cpu_info98:chip_id	0
cpu_info:98:cpu_info98:class	misc
cpu_info:98:cpu_info98:clock_MHz	1649
cpu_info:98:cpu_info98:core_id	1110
cpu_info:98:cpu_info98:cpu_fru	hc:///component=
cpu_info:98:cpu_info98:cpu_type	sparcv9
cpu_info:98:cpu_info98:crtime	186.165764158
cpu_info:98:cpu_info98:current_clock_Hz	1648762500
cpu_info:98:cpu_info98:device_ID	98
cpu_info:98:cpu_info98:fpu_type	sparcv9
cpu_info:98:cpu_info98:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:98:cpu_info98:pg_id	38
cpu_info:98:cpu_info98:snaptime	9305222.57402436
cpu_info:98:cpu_info98:state	on-line
cpu_info:98:cpu_info98:state_begin	1430258903
cpu_info:98:cpu_info98:supported_frequencies_Hz	1648762500
cpu_info:99:cpu_info99:brand	SPARC-T3
cpu_info:99:cpu_info99:chip_id	0
cpu_info:99:cpu_info99:class	misc
cpu_info:99:cpu_info99:clock_MHz	1649
cpu_info:99:cpu_info99:core_id	1110
cpu_info:99:cpu_info99:cpu_fru	hc:///component=
cpu_info:99:cpu_info99:cpu_type	sparcv9
cpu_info:99:cpu_info99:crtime	186.169446338
cpu_info:99:cpu_info99:current_clock_Hz	1648762500
cpu_info:99:cpu_info99:device_ID	99
cpu_info:99:cpu_info99:fpu_type	sparcv9
cpu_info:99:cpu_info99:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:99:cpu_info99:pg_id	38
cpu_info:99:cpu_info99:snaptime	9305222.5751856
cpu_info:99:cpu_info99:state	on-line
cpu_info:99:cpu_info99:state_begin	1430258903
cpu_info:99:cpu_info99:supported_frequencies_Hz	1648762500
cpu_info:100:cpu_info100:brand	SPARC-T3
cpu_info:100:cpu_info100:chip_id	0
cpu_info:100:cpu_info100:class	misc
cpu_info:100:cpu_info100:clock_MHz	1649
cpu_info:100:cpu_info100:core_id	1110
cpu_info:100:cpu_info100:cpu_fru	hc:///component=
cpu_info:100:cpu_info100:cpu_type	sparcv9
cpu_info:100:cpu_info100:crtime	186.17328363
cpu_info:100:cpu_info100:current_clock_Hz	1648762500
cpu_info:100:cpu_info100:device_ID	100
cpu_info:100:cpu_info100:fpu_type	sparcv9
cpu_info:100:cpu_info100:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:100:cpu_info100:pg_id	40
cpu_info:100:cpu_info100:snaptime	9305222.57636642
cpu_info:100:cpu_info100:state	on-line
cpu_info:100:cpu_info100:state_begin	1430258903
cpu_info:100:cpu_info100:supported_frequencies_Hz	1648762500
cpu_info:101:cpu_info101:brand	SPARC-T3
cpu_info:101:cpu_info101:chip_id	0
cpu_info:101:cpu_info101:class	misc
cpu_info:101:cpu_info101:clock_MHz	1649
cpu_info:101:cpu_info101:core_id	1110
cpu_info:101:cpu_info101:cpu_fru	hc:///component=
cpu_info:101:cpu_info101:cpu_type	sparcv9
cpu_info:101:cpu_info101:crtime	186.17700913
cpu_info:101:cpu_info101:current_clock_Hz	1648762500
cpu_info:101:cpu_info101:device_ID	101
cpu_info:101:cpu_info101:fpu_type	sparcv9
cpu_info:101:cpu_info101:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:101:cpu_info101:pg_id	40
cpu_info:101:cpu_info101:snaptime	9305222.57756819
cpu_info:101:cpu_info101:state	on-line
cpu_info:101:cpu_info101:state_begin	1430258903
cpu_info:101:cpu_info101:supported_frequencies_Hz	1648762500
cpu_info:102:cpu_info102:brand	SPARC-T3
cpu_info:102:cpu_info102:chip_id	0
cpu_info:102:cpu_info102:class	misc
cpu_info:102:cpu_info102:clock_MHz	1649
cpu_info:102:cpu_info102:core_id	1110
cpu_info:102:cpu_info102:cpu_fru	hc:///component=
cpu_info:102:cpu_info102:cpu_type	sparcv9
cpu_info:102:cpu_info102:crtime	186.181111931
cpu_info:102:cpu_info102:current_clock_Hz	1648762500
cpu_info:102:cpu_info102:device_ID	102
cpu_info:102:cpu_info102:fpu_type	sparcv9
cpu_info:102:cpu_info102:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:102:cpu_info102:pg_id	40
cpu_info:102:cpu_info102:snaptime	9305222.57872385
cpu_info:102:cpu_info102:state	on-line
cpu_info:102:cpu_info102:state_begin	1430258903
cpu_info:102:cpu_info102:supported_frequencies_Hz	1648762500
cpu_info:103:cpu_info103:brand	SPARC-T3
cpu_info:103:cpu_info103:chip_id	0
cpu_info:103:cpu_info103:class	misc
cpu_info:103:cpu_info103:clock_MHz	1649
cpu_info:103:cpu_info103:core_id	1110
cpu_info:103:cpu_info103:cpu_fru	hc:///component=
cpu_info:103:cpu_info103:cpu_type	sparcv9
cpu_info:103:cpu_info103:crtime	186.184992543
cpu_info:103:cpu_info103:current_clock_Hz	1648762500
cpu_info:103:cpu_info103:device_ID	103
cpu_info:103:cpu_info103:fpu_type	sparcv9
cpu_info:103:cpu_info103:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:103:cpu_info103:pg_id	40
cpu_info:103:cpu_info103:snaptime	9305222.57987811
cpu_info:103:cpu_info103:state	on-line
cpu_info:103:cpu_info103:state_begin	1430258903
cpu_info:103:cpu_info103:supported_frequencies_Hz	1648762500
cpu_info:104:cpu_info104:brand	SPARC-T3
cpu_info:104:cpu_info104:chip_id	0
cpu_info:104:cpu_info104:class	misc
cpu_info:104:cpu_info104:clock_MHz	1649
cpu_info:104:cpu_info104:core_id	1117
cpu_info:104:cpu_info104:cpu_fru	hc:///component=
cpu_info:104:cpu_info104:cpu_type	sparcv9
cpu_info:104:cpu_info104:crtime	186.188854989
cpu_info:104:cpu_info104:current_clock_Hz	1648762500
cpu_info:104:cpu_info104:device_ID	104
cpu_info:104:cpu_info104:fpu_type	sparcv9
cpu_info:104:cpu_info104:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:104:cpu_info104:pg_id	41
cpu_info:104:cpu_info104:snaptime	9305222.58126295
cpu_info:104:cpu_info104:state	on-line
cpu_info:104:cpu_info104:state_begin	1430258903
cpu_info:104:cpu_info104:supported_frequencies_Hz	1648762500
cpu_info:105:cpu_info105:brand	SPARC-T3
cpu_info:105:cpu_info105:chip_id	0
cpu_info:105:cpu_info105:class	misc
cpu_info:105:cpu_info105:clock_MHz	1649
cpu_info:105:cpu_info105:core_id	1117
cpu_info:105:cpu_info105:cpu_fru	hc:///component=
cpu_info:105:cpu_info105:cpu_type	sparcv9
cpu_info:105:cpu_info105:crtime	186.192766344
cpu_info:105:cpu_info105:current_clock_Hz	1648762500
cpu_info:105:cpu_info105:device_ID	105
cpu_info:105:cpu_info105:fpu_type	sparcv9
cpu_info:105:cpu_info105:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:105:cpu_info105:pg_id	41
cpu_info:105:cpu_info105:snaptime	9305222.5824228
cpu_info:105:cpu_info105:state	on-line
cpu_info:105:cpu_info105:state_begin	1430258903
cpu_info:105:cpu_info105:supported_frequencies_Hz	1648762500
cpu_info:106:cpu_info106:brand	SPARC-T3
cpu_info:106:cpu_info106:chip_id	0
cpu_info:106:cpu_info106:class	misc
cpu_info:106:cpu_info106:clock_MHz	1649
cpu_info:106:cpu_info106:core_id	1117
cpu_info:106:cpu_info106:cpu_fru	hc:///component=
cpu_info:106:cpu_info106:cpu_type	sparcv9
cpu_info:106:cpu_info106:crtime	186.197053603
cpu_info:106:cpu_info106:current_clock_Hz	1648762500
cpu_info:106:cpu_info106:device_ID	106
cpu_info:106:cpu_info106:fpu_type	sparcv9
cpu_info:106:cpu_info106:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:106:cpu_info106:pg_id	41
cpu_info:106:cpu_info106:snaptime	9305222.58358125
cpu_info:106:cpu_info106:state	on-line
cpu_info:106:cpu_info106:state_begin	1430258903
cpu_info:106:cpu_info106:supported_frequencies_Hz	1648762500
cpu_info:107:cpu_info107:brand	SPARC-T3
cpu_info:107:cpu_info107:chip_id	0
cpu_info:107:cpu_info107:class	misc
cpu_info:107:cpu_info107:clock_MHz	1649
cpu_info:107:cpu_info107:core_id	1117
cpu_info:107:cpu_info107:cpu_fru	hc:///component=
cpu_info:107:cpu_info107:cpu_type	sparcv9
cpu_info:107:cpu_info107:crtime	186.200927229
cpu_info:107:cpu_info107:current_clock_Hz	1648762500
cpu_info:107:cpu_info107:device_ID	107
cpu_info:107:cpu_info107:fpu_type	sparcv9
cpu_info:107:cpu_info107:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:107:cpu_info107:pg_id	41
cpu_info:107:cpu_info107:snaptime	9305222.5847467
cpu_info:107:cpu_info107:state	on-line
cpu_info:107:cpu_info107:state_begin	1430258903
cpu_info:107:cpu_info107:supported_frequencies_Hz	1648762500
cpu_info:108:cpu_info108:brand	SPARC-T3
cpu_info:108:cpu_info108:chip_id	0
cpu_info:108:cpu_info108:class	misc
cpu_info:108:cpu_info108:clock_MHz	1649
cpu_info:108:cpu_info108:core_id	1117
cpu_info:108:cpu_info108:cpu_fru	hc:///component=
cpu_info:108:cpu_info108:cpu_type	sparcv9
cpu_info:108:cpu_info108:crtime	186.204772906
cpu_info:108:cpu_info108:current_clock_Hz	1648762500
cpu_info:108:cpu_info108:device_ID	108
cpu_info:108:cpu_info108:fpu_type	sparcv9
cpu_info:108:cpu_info108:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:108:cpu_info108:pg_id	43
cpu_info:108:cpu_info108:snaptime	9305222.58591214
cpu_info:108:cpu_info108:state	on-line
cpu_info:108:cpu_info108:state_begin	1430258903
cpu_info:108:cpu_info108:supported_frequencies_Hz	1648762500
cpu_info:109:cpu_info109:brand	SPARC-T3
cpu_info:109:cpu_info109:chip_id	0
cpu_info:109:cpu_info109:class	misc
cpu_info:109:cpu_info109:clock_MHz	1649
cpu_info:109:cpu_info109:core_id	1117
cpu_info:109:cpu_info109:cpu_fru	hc:///component=
cpu_info:109:cpu_info109:cpu_type	sparcv9
cpu_info:109:cpu_info109:crtime	186.208800246
cpu_info:109:cpu_info109:current_clock_Hz	1648762500
cpu_info:109:cpu_info109:device_ID	109
cpu_info:109:cpu_info109:fpu_type	sparcv9
cpu_info:109:cpu_info109:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:109:cpu_info109:pg_id	43
cpu_info:109:cpu_info109:snaptime	9305222.58709854
cpu_info:109:cpu_info109:state	on-line
cpu_info:109:cpu_info109:state_begin	1430258903
cpu_info:109:cpu_info109:supported_frequencies_Hz	1648762500
cpu_info:110:cpu_info110:brand	SPARC-T3
cpu_info:110:cpu_info110:chip_id	0
cpu_info:110:cpu_info110:class	misc
cpu_info:110:cpu_info110:clock_MHz	1649
cpu_info:110:cpu_info110:core_id	1117
cpu_info:110:cpu_info110:cpu_fru	hc:///component=
cpu_info:110:cpu_info110:cpu_type	sparcv9
cpu_info:110:cpu_info110:crtime	186.21284715
cpu_info:110:cpu_info110:current_clock_Hz	1648762500
cpu_info:110:cpu_info110:device_ID	110
cpu_info:110:cpu_info110:fpu_type	sparcv9
cpu_info:110:cpu_info110:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:110:cpu_info110:pg_id	43
cpu_info:110:cpu_info110:snaptime	9305222.5882556
cpu_info:110:cpu_info110:state	on-line
cpu_info:110:cpu_info110:state_begin	1430258903
cpu_info:110:cpu_info110:supported_frequencies_Hz	1648762500
cpu_info:111:cpu_info111:brand	SPARC-T3
cpu_info:111:cpu_info111:chip_id	0
cpu_info:111:cpu_info111:class	misc
cpu_info:111:cpu_info111:clock_MHz	1649
cpu_info:111:cpu_info111:core_id	1117
cpu_info:111:cpu_info111:cpu_fru	hc:///component=
cpu_info:111:cpu_info111:cpu_type	sparcv9
cpu_info:111:cpu_info111:crtime	186.216681648
cpu_info:111:cpu_info111:current_clock_Hz	1648762500
cpu_info:111:cpu_info111:device_ID	111
cpu_info:111:cpu_info111:fpu_type	sparcv9
cpu_info:111:cpu_info111:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:111:cpu_info111:pg_id	43
cpu_info:111:cpu_info111:snaptime	9305222.58941964
cpu_info:111:cpu_info111:state	on-line
cpu_info:111:cpu_info111:state_begin	1430258903
cpu_info:111:cpu_info111:supported_frequencies_Hz	1648762500
cpu_info:112:cpu_info112:brand	SPARC-T3
cpu_info:112:cpu_info112:chip_id	0
cpu_info:112:cpu_info112:class	misc
cpu_info:112:cpu_info112:clock_MHz	1649
cpu_info:112:cpu_info112:core_id	1124
cpu_info:112:cpu_info112:cpu_fru	hc:///component=
cpu_info:112:cpu_info112:cpu_type	sparcv9
cpu_info:112:cpu_info112:crtime	186.220644707
cpu_info:112:cpu_info112:current_clock_Hz	1648762500
cpu_info:112:cpu_info112:device_ID	112
cpu_info:112:cpu_info112:fpu_type	sparcv9
cpu_info:112:cpu_info112:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:112:cpu_info112:pg_id	44
cpu_info:112:cpu_info112:snaptime	9305222.59064377
cpu_info:112:cpu_info112:state	on-line
cpu_info:112:cpu_info112:state_begin	1430258903
cpu_info:112:cpu_info112:supported_frequencies_Hz	1648762500
cpu_info:113:cpu_info113:brand	SPARC-T3
cpu_info:113:cpu_info113:chip_id	0
cpu_info:113:cpu_info113:class	misc
cpu_info:113:cpu_info113:clock_MHz	1649
cpu_info:113:cpu_info113:core_id	1124
cpu_info:113:cpu_info113:cpu_fru	hc:///component=
cpu_info:113:cpu_info113:cpu_type	sparcv9
cpu_info:113:cpu_info113:crtime	186.224940351
cpu_info:113:cpu_info113:current_clock_Hz	1648762500
cpu_info:113:cpu_info113:device_ID	113
cpu_info:113:cpu_info113:fpu_type	sparcv9
cpu_info:113:cpu_info113:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:113:cpu_info113:pg_id	44
cpu_info:113:cpu_info113:snaptime	9305222.591819
cpu_info:113:cpu_info113:state	on-line
cpu_info:113:cpu_info113:state_begin	1430258903
cpu_info:113:cpu_info113:supported_frequencies_Hz	1648762500
cpu_info:114:cpu_info114:brand	SPARC-T3
cpu_info:114:cpu_info114:chip_id	0
cpu_info:114:cpu_info114:class	misc
cpu_info:114:cpu_info114:clock_MHz	1649
cpu_info:114:cpu_info114:core_id	1124
cpu_info:114:cpu_info114:cpu_fru	hc:///component=
cpu_info:114:cpu_info114:cpu_type	sparcv9
cpu_info:114:cpu_info114:crtime	186.228844719
cpu_info:114:cpu_info114:current_clock_Hz	1648762500
cpu_info:114:cpu_info114:device_ID	114
cpu_info:114:cpu_info114:fpu_type	sparcv9
cpu_info:114:cpu_info114:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:114:cpu_info114:pg_id	44
cpu_info:114:cpu_info114:snaptime	9305222.59298444
cpu_info:114:cpu_info114:state	on-line
cpu_info:114:cpu_info114:state_begin	1430258903
cpu_info:114:cpu_info114:supported_frequencies_Hz	1648762500
cpu_info:115:cpu_info115:brand	SPARC-T3
cpu_info:115:cpu_info115:chip_id	0
cpu_info:115:cpu_info115:class	misc
cpu_info:115:cpu_info115:clock_MHz	1649
cpu_info:115:cpu_info115:core_id	1124
cpu_info:115:cpu_info115:cpu_fru	hc:///component=
cpu_info:115:cpu_info115:cpu_type	sparcv9
cpu_info:115:cpu_info115:crtime	186.232733716
cpu_info:115:cpu_info115:current_clock_Hz	1648762500
cpu_info:115:cpu_info115:device_ID	115
cpu_info:115:cpu_info115:fpu_type	sparcv9
cpu_info:115:cpu_info115:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:115:cpu_info115:pg_id	44
cpu_info:115:cpu_info115:snaptime	9305222.5941387
cpu_info:115:cpu_info115:state	on-line
cpu_info:115:cpu_info115:state_begin	1430258903
cpu_info:115:cpu_info115:supported_frequencies_Hz	1648762500
cpu_info:116:cpu_info116:brand	SPARC-T3
cpu_info:116:cpu_info116:chip_id	0
cpu_info:116:cpu_info116:class	misc
cpu_info:116:cpu_info116:clock_MHz	1649
cpu_info:116:cpu_info116:core_id	1124
cpu_info:116:cpu_info116:cpu_fru	hc:///component=
cpu_info:116:cpu_info116:cpu_type	sparcv9
cpu_info:116:cpu_info116:crtime	186.236670225
cpu_info:116:cpu_info116:current_clock_Hz	1648762500
cpu_info:116:cpu_info116:device_ID	116
cpu_info:116:cpu_info116:fpu_type	sparcv9
cpu_info:116:cpu_info116:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:116:cpu_info116:pg_id	46
cpu_info:116:cpu_info116:snaptime	9305222.59529995
cpu_info:116:cpu_info116:state	on-line
cpu_info:116:cpu_info116:state_begin	1430258903
cpu_info:116:cpu_info116:supported_frequencies_Hz	1648762500
cpu_info:117:cpu_info117:brand	SPARC-T3
cpu_info:117:cpu_info117:chip_id	0
cpu_info:117:cpu_info117:class	misc
cpu_info:117:cpu_info117:clock_MHz	1649
cpu_info:117:cpu_info117:core_id	1124
cpu_info:117:cpu_info117:cpu_fru	hc:///component=
cpu_info:117:cpu_info117:cpu_type	sparcv9
cpu_info:117:cpu_info117:crtime	186.240778616
cpu_info:117:cpu_info117:current_clock_Hz	1648762500
cpu_info:117:cpu_info117:device_ID	117
cpu_info:117:cpu_info117:fpu_type	sparcv9
cpu_info:117:cpu_info117:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:117:cpu_info117:pg_id	46
cpu_info:117:cpu_info117:snaptime	9305222.59648495
cpu_info:117:cpu_info117:state	on-line
cpu_info:117:cpu_info117:state_begin	1430258903
cpu_info:117:cpu_info117:supported_frequencies_Hz	1648762500
cpu_info:118:cpu_info118:brand	SPARC-T3
cpu_info:118:cpu_info118:chip_id	0
cpu_info:118:cpu_info118:class	misc
cpu_info:118:cpu_info118:clock_MHz	1649
cpu_info:118:cpu_info118:core_id	1124
cpu_info:118:cpu_info118:cpu_fru	hc:///component=
cpu_info:118:cpu_info118:cpu_type	sparcv9
cpu_info:118:cpu_info118:crtime	186.244717919
cpu_info:118:cpu_info118:current_clock_Hz	1648762500
cpu_info:118:cpu_info118:device_ID	118
cpu_info:118:cpu_info118:fpu_type	sparcv9
cpu_info:118:cpu_info118:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:118:cpu_info118:pg_id	46
cpu_info:118:cpu_info118:snaptime	9305222.5976476
cpu_info:118:cpu_info118:state	on-line
cpu_info:118:cpu_info118:state_begin	1430258903
cpu_info:118:cpu_info118:supported_frequencies_Hz	1648762500
cpu_info:119:cpu_info119:brand	SPARC-T3
cpu_info:119:cpu_info119:chip_id	0
cpu_info:119:cpu_info119:class	misc
cpu_info:119:cpu_info119:clock_MHz	1649
cpu_info:119:cpu_info119:core_id	1124
cpu_info:119:cpu_info119:cpu_fru	hc:///component=
cpu_info:119:cpu_info119:cpu_type	sparcv9
cpu_info:119:cpu_info119:crtime	186.248661415
cpu_info:119:cpu_info119:current_clock_Hz	1648762500
cpu_info:119:cpu_info119:device_ID	119
cpu_info:119:cpu_info119:fpu_type	sparcv9
cpu_info:119:cpu_info119:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:119:cpu_info119:pg_id	46
cpu_info:119:cpu_info119:snaptime	9305222.59881723
cpu_info:119:cpu_info119:state	on-line
cpu_info:119:cpu_info119:state_begin	1430258903
cpu_info:119:cpu_info119:supported_frequencies_Hz	1648762500
cpu_info:120:cpu_info120:brand	SPARC-T3
cpu_info:120:cpu_info120:chip_id	0
cpu_info:120:cpu_info120:class	misc
cpu_info:120:cpu_info120:clock_MHz	1649
cpu_info:120:cpu_info120:core_id	1131
cpu_info:120:cpu_info120:cpu_fru	hc:///component=
cpu_info:120:cpu_info120:cpu_type	sparcv9
cpu_info:120:cpu_info120:crtime	186.252660808
cpu_info:120:cpu_info120:current_clock_Hz	1648762500
cpu_info:120:cpu_info120:device_ID	120
cpu_info:120:cpu_info120:fpu_type	sparcv9
cpu_info:120:cpu_info120:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:120:cpu_info120:pg_id	47
cpu_info:120:cpu_info120:snaptime	9305222.59998826
cpu_info:120:cpu_info120:state	on-line
cpu_info:120:cpu_info120:state_begin	1430258903
cpu_info:120:cpu_info120:supported_frequencies_Hz	1648762500
cpu_info:121:cpu_info121:brand	SPARC-T3
cpu_info:121:cpu_info121:chip_id	0
cpu_info:121:cpu_info121:class	misc
cpu_info:121:cpu_info121:clock_MHz	1649
cpu_info:121:cpu_info121:core_id	1131
cpu_info:121:cpu_info121:cpu_fru	hc:///component=
cpu_info:121:cpu_info121:cpu_type	sparcv9
cpu_info:121:cpu_info121:crtime	186.257104577
cpu_info:121:cpu_info121:current_clock_Hz	1648762500
cpu_info:121:cpu_info121:device_ID	121
cpu_info:121:cpu_info121:fpu_type	sparcv9
cpu_info:121:cpu_info121:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:121:cpu_info121:pg_id	47
cpu_info:121:cpu_info121:snaptime	9305222.60114672
cpu_info:121:cpu_info121:state	on-line
cpu_info:121:cpu_info121:state_begin	1430258903
cpu_info:121:cpu_info121:supported_frequencies_Hz	1648762500
cpu_info:122:cpu_info122:brand	SPARC-T3
cpu_info:122:cpu_info122:chip_id	0
cpu_info:122:cpu_info122:class	misc
cpu_info:122:cpu_info122:clock_MHz	1649
cpu_info:122:cpu_info122:core_id	1131
cpu_info:122:cpu_info122:cpu_fru	hc:///component=
cpu_info:122:cpu_info122:cpu_type	sparcv9
cpu_info:122:cpu_info122:crtime	186.260994971
cpu_info:122:cpu_info122:current_clock_Hz	1648762500
cpu_info:122:cpu_info122:device_ID	122
cpu_info:122:cpu_info122:fpu_type	sparcv9
cpu_info:122:cpu_info122:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:122:cpu_info122:pg_id	47
cpu_info:122:cpu_info122:snaptime	9305222.60230238
cpu_info:122:cpu_info122:state	on-line
cpu_info:122:cpu_info122:state_begin	1430258903
cpu_info:122:cpu_info122:supported_frequencies_Hz	1648762500
cpu_info:123:cpu_info123:brand	SPARC-T3
cpu_info:123:cpu_info123:chip_id	0
cpu_info:123:cpu_info123:class	misc
cpu_info:123:cpu_info123:clock_MHz	1649
cpu_info:123:cpu_info123:core_id	1131
cpu_info:123:cpu_info123:cpu_fru	hc:///component=
cpu_info:123:cpu_info123:cpu_type	sparcv9
cpu_info:123:cpu_info123:crtime	186.264900737
cpu_info:123:cpu_info123:current_clock_Hz	1648762500
cpu_info:123:cpu_info123:device_ID	123
cpu_info:123:cpu_info123:fpu_type	sparcv9
cpu_info:123:cpu_info123:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:123:cpu_info123:pg_id	47
cpu_info:123:cpu_info123:snaptime	9305222.60351952
cpu_info:123:cpu_info123:state	on-line
cpu_info:123:cpu_info123:state_begin	1430258903
cpu_info:123:cpu_info123:supported_frequencies_Hz	1648762500
cpu_info:124:cpu_info124:brand	SPARC-T4
cpu_info:124:cpu_info124:chip_id	0
cpu_info:124:cpu_info124:class	misc
cpu_info:124:cpu_info124:clock_MHz	1649
cpu_info:124:cpu_info124:core_id	1131
cpu_info:124:cpu_info124:cpu_fru	hc:///component=
cpu_info:124:cpu_info124:cpu_type	sparcv9
cpu_info:124:cpu_info124:crtime	186.268767375
cpu_info:124:cpu_info124:current_clock_Hz	1648762500
cpu_info:124:cpu_info124:device_ID	124
cpu_info:124:cpu_info124:fpu_type	sparcv9
cpu_info:124:cpu_info124:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:124:cpu_info124:pg_id	49
cpu_info:124:cpu_info124:snaptime	9305222.60468497
cpu_info:124:cpu_info124:state	off-line
cpu_info:124:cpu_info124:state_begin	1430258903
cpu_info:124:cpu_info124:supported_frequencies_Hz	1648762500
cpu_info:125:cpu_info125:brand	SPARC-T4
cpu_info:125:cpu_info125:chip_id	0
cpu_info:125:cpu_info125:class	misc
cpu_info:125:cpu_info125:clock_MHz	1649
cpu_info:125:cpu_info125:core_id	1131
cpu_info:125:cpu_info125:cpu_fru	hc:///component=
cpu_info:125:cpu_info125:cpu_type	sparcv9
cpu_info:125:cpu_info125:crtime	186.272702486
cpu_info:125:cpu_info125:current_clock_Hz	1648762500
cpu_info:125:cpu_info125:device_ID	125
cpu_info:125:cpu_info125:fpu_type	sparcv9
cpu_info:125:cpu_info125:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:125:cpu_info125:pg_id	49
cpu_info:125:cpu_info125:snaptime	9305222.60585879
cpu_info:125:cpu_info125:state	off-line
cpu_info:125:cpu_info125:state_begin	1430258903
cpu_info:125:cpu_info125:supported_frequencies_Hz	1648762500
cpu_info:126:cpu_info126:brand	SPARC-T4
cpu_info:126:cpu_info126:chip_id	0
cpu_info:126:cpu_info126:class	misc
cpu_info:126:cpu_info126:clock_MHz	1649
cpu_info:126:cpu_info126:core_id	1131
cpu_info:126:cpu_info126:cpu_fru	hc:///component=
cpu_info:126:cpu_info126:cpu_type	sparcv9
cpu_info:126:cpu_info126:crtime	186.27663061
cpu_info:126:cpu_info126:current_clock_Hz	1648762500
cpu_info:126:cpu_info126:device_ID	126
cpu_info:126:cpu_info126:fpu_type	sparcv9
cpu_info:126:cpu_info126:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:126:cpu_info126:pg_id	49
cpu_info:126:cpu_info126:snaptime	9305222.60703821
cpu_info:126:cpu_info126:state	off-line
cpu_info:126:cpu_info126:state_begin	1430258903
cpu_info:126:cpu_info126:supported_frequencies_Hz	1648762500
cpu_info:127:cpu_info127:brand	SPARC-T4
cpu_info:127:cpu_info127:chip_id	0
cpu_info:127:cpu_info127:class	misc
cpu_info:127:cpu_info127:clock_MHz	1649
cpu_info:127:cpu_info127:core_id	1131
cpu_info:127:cpu_info127:cpu_fru	hc:///component=
cpu_info:127:cpu_info127:cpu_type	sparcv9
cpu_info:127:cpu_info127:crtime	186.281711599
cpu_info:127:cpu_info127:current_clock_Hz	1648762500
cpu_info:127:cpu_info127:device_ID	127
cpu_info:127:cpu_info127:fpu_type	sparcv9
cpu_info:127:cpu_info127:implementation	SPARC-T3 (chipid 0, clock 1649 MHz)
cpu_info:127:cpu_info127:pg_id	49
cpu_info:127:cpu_info127:snaptime	9305222.60819247
cpu_info:127:cpu_info127:state	off-line
cpu_info:127:cpu_info127:state_begin	1430258903
cpu_info:127:cpu_info127:supported_frequencies_Hz	1648762500
END
      allow(@plugin).to receive(:shell_out).with("kstat -p cpu_info").and_return(mock_shell_out(0, kstatinfo_output, ""))
      @plugin.run
    end

    it "should get the total virtual processor count" do
      expect(@plugin["cpu"]["total"]).to eql(128)
    end

    it "should get the total processor count" do
      expect(@plugin["cpu"]["real"]).to eql(1)
    end

    it "should get the total core count" do
      expect(@plugin["cpu"]["cores"]).to eql(16)
    end

    it "should get the number of threads per core" do
      expect(@plugin["cpu"]["corethreads"]).to eql(8)
    end

    it "should get the total number of online cores" do
      expect(@plugin["cpu"]["cpustates"]["on-line"]).to eql(124)
    end

    it "should get the total number of offline cores" do
      expect(@plugin["cpu"]["cpustates"]["off-line"]).to eql(4)
    end

    describe "per-cpu information" do
      it "should include processor model names" do
        expect(@plugin["cpu"]["0"]["model_name"]).to eql("SPARC-T3")
        expect(@plugin["cpu"]["1"]["model_name"]).to eql("SPARC-T3")
        expect(@plugin["cpu"]["2"]["model_name"]).to eql("SPARC-T3")
        expect(@plugin["cpu"]["3"]["model_name"]).to eql("SPARC-T3")
        expect(@plugin["cpu"]["124"]["model_name"]).to eql("SPARC-T4")
        expect(@plugin["cpu"]["125"]["model_name"]).to eql("SPARC-T4")
        expect(@plugin["cpu"]["126"]["model_name"]).to eql("SPARC-T4")
        expect(@plugin["cpu"]["127"]["model_name"]).to eql("SPARC-T4")
      end

      it "should include processor sockets" do
        expect(@plugin["cpu"]["0"]["socket"]).to eql("0")
        expect(@plugin["cpu"]["1"]["socket"]).to eql("0")
        expect(@plugin["cpu"]["2"]["socket"]).to eql("0")
        expect(@plugin["cpu"]["3"]["socket"]).to eql("0")
        expect(@plugin["cpu"]["124"]["socket"]).to eql("0")
        expect(@plugin["cpu"]["125"]["socket"]).to eql("0")
        expect(@plugin["cpu"]["126"]["socket"]).to eql("0")
        expect(@plugin["cpu"]["127"]["socket"]).to eql("0")
      end

      it "should include processor MHz" do
        expect(@plugin["cpu"]["0"]["mhz"]).to eql("1649")
        expect(@plugin["cpu"]["1"]["mhz"]).to eql("1649")
        expect(@plugin["cpu"]["2"]["mhz"]).to eql("1649")
        expect(@plugin["cpu"]["3"]["mhz"]).to eql("1649")
        expect(@plugin["cpu"]["124"]["mhz"]).to eql("1649")
        expect(@plugin["cpu"]["125"]["mhz"]).to eql("1649")
        expect(@plugin["cpu"]["126"]["mhz"]).to eql("1649")
        expect(@plugin["cpu"]["127"]["mhz"]).to eql("1649")
      end

      it "should include processor core IDs" do
        expect(@plugin["cpu"]["0"]["core_id"]).to eql("1026")
        expect(@plugin["cpu"]["8"]["core_id"]).to eql("1033")
        expect(@plugin["cpu"]["16"]["core_id"]).to eql("1040")
        expect(@plugin["cpu"]["24"]["core_id"]).to eql("1047")
        expect(@plugin["cpu"]["32"]["core_id"]).to eql("1054")
        expect(@plugin["cpu"]["40"]["core_id"]).to eql("1061")
        expect(@plugin["cpu"]["48"]["core_id"]).to eql("1068")
        expect(@plugin["cpu"]["56"]["core_id"]).to eql("1075")
        expect(@plugin["cpu"]["64"]["core_id"]).to eql("1082")
        expect(@plugin["cpu"]["72"]["core_id"]).to eql("1089")
        expect(@plugin["cpu"]["80"]["core_id"]).to eql("1096")
        expect(@plugin["cpu"]["88"]["core_id"]).to eql("1103")
        expect(@plugin["cpu"]["96"]["core_id"]).to eql("1110")
        expect(@plugin["cpu"]["104"]["core_id"]).to eql("1117")
        expect(@plugin["cpu"]["112"]["core_id"]).to eql("1124")
        expect(@plugin["cpu"]["120"]["core_id"]).to eql("1131")
      end

      it "should include processor architecture" do
        expect(@plugin["cpu"]["0"]["arch"]).to eql("sparcv9")
        expect(@plugin["cpu"]["1"]["arch"]).to eql("sparcv9")
        expect(@plugin["cpu"]["2"]["arch"]).to eql("sparcv9")
        expect(@plugin["cpu"]["3"]["arch"]).to eql("sparcv9")
        expect(@plugin["cpu"]["124"]["arch"]).to eql("sparcv9")
        expect(@plugin["cpu"]["125"]["arch"]).to eql("sparcv9")
        expect(@plugin["cpu"]["126"]["arch"]).to eql("sparcv9")
        expect(@plugin["cpu"]["127"]["arch"]).to eql("sparcv9")
      end

      it "should include processor FPU type" do
        expect(@plugin["cpu"]["0"]["fpu_type"]).to eql("sparcv9")
        expect(@plugin["cpu"]["1"]["fpu_type"]).to eql("sparcv9")
        expect(@plugin["cpu"]["2"]["fpu_type"]).to eql("sparcv9")
        expect(@plugin["cpu"]["3"]["fpu_type"]).to eql("sparcv9")
        expect(@plugin["cpu"]["124"]["fpu_type"]).to eql("sparcv9")
        expect(@plugin["cpu"]["125"]["fpu_type"]).to eql("sparcv9")
        expect(@plugin["cpu"]["126"]["fpu_type"]).to eql("sparcv9")
        expect(@plugin["cpu"]["127"]["fpu_type"]).to eql("sparcv9")
      end

      it "should include processor state" do
        expect(@plugin["cpu"]["0"]["state"]).to eql("on-line")
        expect(@plugin["cpu"]["1"]["state"]).to eql("on-line")
        expect(@plugin["cpu"]["2"]["state"]).to eql("on-line")
        expect(@plugin["cpu"]["3"]["state"]).to eql("on-line")
        expect(@plugin["cpu"]["124"]["state"]).to eql("off-line")
        expect(@plugin["cpu"]["125"]["state"]).to eql("off-line")
        expect(@plugin["cpu"]["126"]["state"]).to eql("off-line")
        expect(@plugin["cpu"]["127"]["state"]).to eql("off-line")
      end
    end
  end
end
