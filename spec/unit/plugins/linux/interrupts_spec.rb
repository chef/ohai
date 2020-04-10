#
# Author:: Davide Cavalca <dcavalca@fb.com>
# Copyright:: Copyright (c) 2020 Facebook
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

  it "populates interrupts" do
    @proc_interrupts = double("/proc/interrupts")
    allow(@proc_interrupts).to receive(:each)
      .and_yield("            CPU0       CPU1       CPU2       CPU3       ")
      .and_yield("   0:         10          0          0          0  IR-IO-APIC    2-edge      timer")
      .and_yield("   1:      23893          0          0      47577  IR-IO-APIC    1-edge      i8042")
      .and_yield("   8:          0          1          0          0  IR-IO-APIC    8-edge      rtc0")
      .and_yield("   9:       2550       8705          0          0  IR-IO-APIC    9-fasteoi   acpi")
      .and_yield("  12:          6          0        191          0  IR-IO-APIC   12-edge      i8042")
      .and_yield("  16:      10054          0          0       7570  IR-IO-APIC   16-fasteoi   i801_smbus")
      .and_yield(" 120:          0          0          0          0  DMAR-MSI    0-edge      dmar0")
      .and_yield(" 121:          0          0          0          0  DMAR-MSI    1-edge      dmar1")
      .and_yield(" 122:         31          0         26          0  IR-PCI-MSI 1048576-edge      rtsx_pci")
      .and_yield(" 123:          0         40          0          0  IR-PCI-MSI 360448-edge      mei_me")
      .and_yield(" 124:          0          0          0         11  IR-PCI-MSI 2621440-edge      nvme0q0")
      .and_yield(" 125:          0          0       3226          0  IR-PCI-MSI 514048-edge      snd_hda_intel:card0")
      .and_yield(" 126:          0          0          0     184403  IR-PCI-MSI 5767168-edge      xhci_hcd")
      .and_yield(" 127:          0          0          0          0  IR-PCI-MSI 5767169-edge      xhci_hcd")
      .and_yield(" 128:          0          0          0          0  IR-PCI-MSI 5767170-edge      xhci_hcd")
      .and_yield(" 129:          0          0          0          0  IR-PCI-MSI 5767171-edge      xhci_hcd")
      .and_yield(" 130:          0          0          0          0  IR-PCI-MSI 5767172-edge      xhci_hcd")
      .and_yield(" 131:       3345       3732          0          0  IR-PCI-MSI 4194304-edge      thunderbolt")
      .and_yield(" 132:       3345          0       3727          0  IR-PCI-MSI 4194305-edge      thunderbolt")
      .and_yield(" 141:      15573          0          0          0  IR-PCI-MSI 327680-edge      xhci_hcd")
      .and_yield(" 148:          0          0          0     289071  IR-PCI-MSI 6815744-edge      xhci_hcd")
      .and_yield(" 149:          0          0          0          0  IR-PCI-MSI 6815745-edge      xhci_hcd")
      .and_yield(" 150:          0          0          0          0  IR-PCI-MSI 6815746-edge      xhci_hcd")
      .and_yield(" 151:          0          0          0          0  IR-PCI-MSI 6815747-edge      xhci_hcd")
      .and_yield(" 152:          0          0          0          0  IR-PCI-MSI 6815748-edge      xhci_hcd")
      .and_yield(" 153:          0       4641          0          0  IR-PCI-MSI 520192-edge      enp0s31f6")
      .and_yield(" 154:      49453          0          0          0  IR-PCI-MSI 2621441-edge      nvme0q1")
      .and_yield(" 155:          0      51007          0          0  IR-PCI-MSI 2621442-edge      nvme0q2")
      .and_yield(" 156:          0          0      45975          0  IR-PCI-MSI 2621443-edge      nvme0q3")
      .and_yield(" 157:       2579          0          0       2019     dummy   44  rmi4_smbus")
      .and_yield(" 158:          0          0          0          0      rmi4    0  rmi4-00.fn34")
      .and_yield(" 159:          0          0          0          0      rmi4    1  rmi4-00.fn01")
      .and_yield(" 160:    1784676          0          0          0  IR-PCI-MSI 2097152-edge      iwlwifi")
      .and_yield(" 161:          0          0       1016          1      rmi4    2  rmi4-00.fn03")
      .and_yield(" 162:          0          0       3580          0      rmi4    3  rmi4-00.fn11")
      .and_yield(" 163:          0          0          0          0      rmi4    4  rmi4-00.fn11")
      .and_yield(" 164:          0          0          2          0      rmi4    5  rmi4-00.fn30")
      .and_yield(" 165:    2008273    3789134          0          0  IR-PCI-MSI 32768-edge      i915")
      .and_yield(" 166:          0          0          0      46740  IR-PCI-MSI 2621444-edge      nvme0q4")
      .and_yield(" NMI:        319        444        439        436   Non-maskable interrupts")
      .and_yield(" LOC:    8860101    9203856    8779117    8664864   Local timer interrupts")
      .and_yield(" SPU:          0          0          0          0   Spurious interrupts")
      .and_yield(" PMI:        319        444        439        436   Performance monitoring interrupts")
      .and_yield(" IWI:     142355     234400        224         88   IRQ work interrupts")
      .and_yield(" RTR:          0          0          0          0   APIC ICR read retries")
      .and_yield(" RES:    1342987    1237722    1430670    1111989   Rescheduling interrupts")
      .and_yield(" CAL:    1441625    1446396    1447611    1432443   Function call interrupts")
      .and_yield(" TLB:    1468833    1470049    1470021    1452257   TLB shootdowns")
      .and_yield(" TRM:     282150     282150     282150     282150   Thermal event interrupts")
      .and_yield(" THR:          0          0          0          0   Threshold APIC interrupts")
      .and_yield(" DFR:          0          0          0          0   Deferred Error APIC interrupts")
      .and_yield(" MCE:          0          0          0          0   Machine check exceptions")
      .and_yield(" MCP:        134        134        134        134   Machine check polls")
      .and_yield(" HYP:          0          0          0          0   Hypervisor callback interrupts")
      .and_yield(" HRE:          0          0          0          0   Hyper-V reenlightenment interrupts")
      .and_yield(" HVS:          0          0          0          0   Hyper-V stimer0 interrupts")
      .and_yield(" ERR:          0")
      .and_yield(" MIS:          0")
      .and_yield(" PIN:          0          0          0          0   Posted-interrupt notification event")
      .and_yield(" NPI:          0          0          0          0   Nested posted-interrupt event")
      .and_yield(" PIW:          0          0          0          0   Posted-interrupt wakeup event")
    interrupts = {
      "irq" => {
        "0" => {
          "device" => "timer",
          "events_by_cpu" => {
            0 => 10,
            1 => 0,
            2 => 0,
            3 => 0,
          },
          "type" => "IR-IO-APIC",
          "vector" => "2-edge",
        },
        "1" => {
          "device" => "i8042",
          "events_by_cpu" => {
            0 => 23893, 1 => 0, 2 => 0, 3 => 47577
          },
          "smp_affinity_by_cpu" => {
            0 => true, 1 => true, 2 => true, 3 => true
          },
          "type" => "IR-IO-APIC",
          "vector" => "1-edge",
        },
        "12" => {
          "device" => "i8042",
          "events_by_cpu" => {
            0 => 6, 1 => 0, 2 => 191, 3 => 0
          },
          "type" => "IR-IO-APIC",
          "vector" => "12-edge",
        },
        "120" => {
          "device" => "dmar0",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "DMAR-MSI",
          "vector" => "0-edge",
        },
        "121" => {
          "device" => "dmar1",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "DMAR-MSI",
          "vector" => "1-edge",
        },
        "122" => {
          "device" => "rtsx_pci",
          "events_by_cpu" => {
            0 => 31, 1 => 0, 2 => 26, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "1048576-edge",
        },
        "123" => {
          "device" => "mei_me",
          "events_by_cpu" => {
            0 => 0, 1 => 40, 2 => 0, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "360448-edge",
        },
        "124" => {
          "device" => "nvme0q0",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 11
          },
          "type" => "IR-PCI-MSI",
          "vector" => "2621440-edge",
        },
        "125" => {
          "device" => "snd_hda_intel:card0",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 3226, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "514048-edge",
        },
        "126" => {
          "device" => "xhci_hcd",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 184403
          },
          "type" => "IR-PCI-MSI",
          "vector" => "5767168-edge",
        },
        "127" => {
          "device" => "xhci_hcd",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "5767169-edge",
        },
        "128" => {
          "device" => "xhci_hcd",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "5767170-edge",
        },
        "129" => {
          "device" => "xhci_hcd",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "5767171-edge",
        },
        "130" => {
          "device" => "xhci_hcd",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "5767172-edge",
        },
        "131" => {
          "device" => "thunderbolt",
          "events_by_cpu" => {
            0 => 3345, 1 => 3732, 2 => 0, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "4194304-edge",
        },
        "132" => {
          "device" => "thunderbolt",
          "events_by_cpu" => {
            0 => 3345, 1 => 0, 2 => 3727, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "4194305-edge",
        },
        "141" => {
          "device" => "xhci_hcd",
          "events_by_cpu" => {
            0 => 15573, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "327680-edge",
        },
        "148" => {
          "device" => "xhci_hcd",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 289071
          },
          "type" => "IR-PCI-MSI",
          "vector" => "6815744-edge",
        },
        "149" => {
          "device" => "xhci_hcd",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "6815745-edge",
        },
        "150" => {
          "device" => "xhci_hcd",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "6815746-edge",
        },
        "151" => {
          "device" => "xhci_hcd",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "6815747-edge",
        },
        "152" => {
          "device" => "xhci_hcd",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "6815748-edge",
        },
        "153" => {
          "device" => "enp0s31f6",
          "events_by_cpu" => {
            0 => 0, 1 => 4641, 2 => 0, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "520192-edge",
        },
        "154" => {
          "device" => "nvme0q1",
          "events_by_cpu" => {
            0 => 49453, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "2621441-edge",
        },
        "155" => {
          "device" => "nvme0q2",
          "events_by_cpu" => {
            0 => 0, 1 => 51007, 2 => 0, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "2621442-edge",
        },
        "156" => {
          "device" => "nvme0q3",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 45975, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "2621443-edge",
        },
        "157" => {
          "device" => "rmi4_smbus",
          "events_by_cpu" => {
            0 => 2579, 1 => 0, 2 => 0, 3 => 2019
          },
          "type" => "dummy",
          "vector" => "44",
        },
        "158" => {
          "device" => "rmi4-00.fn34",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "rmi4",
          "vector" => "0",
        },
        "159" => {
          "device" => "rmi4-00.fn01",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "rmi4",
          "vector" => "1",
        },
        "16" => {
          "device" => "i801_smbus",
          "events_by_cpu" => {
            0 => 10054, 1 => 0, 2 => 0, 3 => 7570
          },
          "type" => "IR-IO-APIC",
          "vector" => "16-fasteoi",
        },
        "160" => {
          "device" => "iwlwifi",
          "events_by_cpu" => {
            0 => 1784676, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "2097152-edge",
        },
        "161" => {
          "device" => "rmi4-00.fn03",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 1016, 3 => 1
          },
          "type" => "rmi4",
          "vector" => "2",
        },
        "162" => {
          "device" => "rmi4-00.fn11",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 3580, 3 => 0
          },
          "type" => "rmi4",
          "vector" => "3",
        },
        "163" => {
          "device" => "rmi4-00.fn11",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "rmi4",
          "vector" => "4",
        },
        "164" => {
          "device" => "rmi4-00.fn30",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 2, 3 => 0
          },
          "type" => "rmi4",
          "vector" => "5",
        },
        "165" => {
          "device" => "i915",
          "events_by_cpu" => {
            0 => 2008273, 1 => 3789134, 2 => 0, 3 => 0
          },
          "type" => "IR-PCI-MSI",
          "vector" => "32768-edge",
        },
        "166" => {
          "device" => "nvme0q4",
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 46740
          },
          "type" => "IR-PCI-MSI",
          "vector" => "2621444-edge",
        },
        "8" => {
          "device" => "rtc0",
          "events_by_cpu" => {
            0 => 0, 1 => 1, 2 => 0, 3 => 0
          },
          "type" => "IR-IO-APIC",
          "vector" => "8-edge",
        },
        "9" => {
          "device" => "acpi",
          "events_by_cpu" => {
            0 => 2550, 1 => 8705, 2 => 0, 3 => 0
          },
          "type" => "IR-IO-APIC",
          "vector" => "9-fasteoi",
        },
        "CAL" => {
          "events_by_cpu" => {
            0 => 1441625, 1 => 1446396, 2 => 1447611, 3 => 1432443
          },
          "type" => "Function call interrupts",
        },
        "DFR" => {
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "Deferred Error APIC interrupts",
        },
        "ERR" => {
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
        },
        "HRE" => {
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "Hyper-V reenlightenment interrupts",
        },
        "HVS" => {
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "Hyper-V stimer0 interrupts",
        },
        "HYP" => {
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "Hypervisor callback interrupts",
        },
        "IWI" => {
          "events_by_cpu" => {
            0 => 142355, 1 => 234400, 2 => 224, 3 => 88
          },
          "type" => "IRQ work interrupts",
        },
        "LOC" => {
          "events_by_cpu" => {
            0 => 8860101, 1 => 9203856, 2 => 8779117, 3 => 8664864
          },
          "type" => "Local timer interrupts",
        },
        "MCE" => {
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "Machine check exceptions",
        },
        "MCP" => {
          "events_by_cpu" => {
            0 => 134, 1 => 134, 2 => 134, 3 => 134
          },
          "type" => "Machine check polls",
        },
        "MIS" => {
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
        },
        "NMI" => {
          "events_by_cpu" => {
            0 => 319, 1 => 444, 2 => 439, 3 => 436
          },
          "type" => "Non-maskable interrupts",
        },
        "NPI" => {
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "Nested posted-interrupt event",
        },
        "PIN" => {
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "Posted-interrupt notification event",
        },
        "PIW" => {
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "Posted-interrupt wakeup event",
        },
        "PMI" => {
          "events_by_cpu" => {
            0 => 319, 1 => 444, 2 => 439, 3 => 436
          },
          "type" => "Performance monitoring interrupts",
        },
        "RES" => {
          "events_by_cpu" => {
            0 => 1342987, 1 => 1237722, 2 => 1430670, 3 => 1111989
          },
          "type" => "Rescheduling interrupts",
        },
        "RTR" => {
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "APIC ICR read retries",
        },
        "SPU" => {
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "Spurious interrupts",
        },
        "THR" => {
          "events_by_cpu" => {
            0 => 0, 1 => 0, 2 => 0, 3 => 0
          },
          "type" => "Threshold APIC interrupts",
        },
        "TLB" => {
          "events_by_cpu" => {
            0 => 1468833, 1 => 1470049, 2 => 1470021, 3 => 1452257
          },
          "type" => "TLB shootdowns",
        },
        "TRM" => {
          "events_by_cpu" => {
            0 => 282150, 1 => 282150, 2 => 282150, 3 => 282150
          },
          "type" => "Thermal event interrupts",
        },
      },
      "smp_affinity_by_cpu" => {
        0 => true, 1 => true, 2 => true, 3 => true
      },
    }

    plugin[:cpu] = {
      "total" => 4,
    }
    allow(File).to receive(:exist?).and_return(false)
    allow(File).to receive(:open).with("/proc/interrupts").and_return(@proc_interrupts)
    allow(File).to receive(:exist?).with("/proc/irq/default_smp_affinity").and_return(true)
    allow(File).to receive(:read).with("/proc/irq/default_smp_affinity").and_return("ff")
    allow(File).to receive(:exist?).with("/proc/irq/1/smp_affinity").and_return(true)
    allow(File).to receive(:read).with("/proc/irq/1/smp_affinity").and_return("ff")
    plugin.run
    expect(plugin[:interrupts]).to eq(interrupts)
  end
end
