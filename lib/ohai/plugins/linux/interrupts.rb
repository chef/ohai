# frozen_string_literal: true
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

Ohai.plugin(:Interrupts) do
  depends "cpu"
  provides "interrupts", "interrupts/irq", "interrupts/smp_affinity_by_cpu"
  optional true

  # Documentation: https://www.kernel.org/doc/Documentation/IRQ-affinity.txt
  # format: comma-separate list of 32bit bitmask in hex
  # each bit is a CPU, right to left ordering (i.e. CPU0 is rightmost)
  def parse_smp_affinity(path, cpus)
    masks = file_read(path).strip
    bit_masks = []
    masks.split(",").each do |mask|
      bit_masks << mask.rjust(8, "0").to_i(16).to_s(2)
    end
    affinity_mask = bit_masks.join
    affinity_by_cpu = affinity_mask.split("").reverse
    smp_affinity_by_cpu = Mash.new
    (0..cpus - 1).each do |cpu|
      smp_affinity_by_cpu[cpu] = affinity_by_cpu[cpu].to_i == 1
    end
    smp_affinity_by_cpu
  end

  collect_data(:linux) do
    interrupts Mash.new

    cpus = cpu["total"]
    interrupts[:smp_affinity_by_cpu] =
      parse_smp_affinity("/proc/irq/default_smp_affinity", cpus)

    interrupts[:irq] = Mash.new
    file_open("/proc/interrupts").each do |line|
      # Documentation: https://www.kernel.org/doc/Documentation/filesystems/proc.txt
      # format is "{irqn}: {CPUn...} [type] [vector] [device]"
      irqn, fields = line.split(":", 2)
      # skip the header
      next if fields.nil?

      irqn.strip!
      Ohai::Log.debug("irq: processing #{irqn}")

      interrupts[:irq][irqn] = Mash.new
      interrupts[:irq][irqn][:events_by_cpu] = Mash.new

      fields = fields.split(nil, cpus + 1)
      (0..cpus - 1).each do |cpu|
        interrupts[:irq][irqn][:events_by_cpu][cpu] = fields[cpu].to_i
      end
      # Only regular IRQs have extra fields and affinity settings
      if /^\d+$/.match?(irqn)
        interrupts[:irq][irqn][:type],
        interrupts[:irq][irqn][:vector],
        interrupts[:irq][irqn][:device] =
          fields[cpus].split
        if file_exist?("/proc/irq/#{irqn}/smp_affinity")
          interrupts[:irq][irqn][:smp_affinity_by_cpu] =
            parse_smp_affinity("/proc/irq/#{irqn}/smp_affinity", cpus)
        end
      # ERR and MIS do not have any extra fields
      elsif fields[cpus]
        interrupts[:irq][irqn][:type] = fields[cpus].strip
      end
    end
  end
end
