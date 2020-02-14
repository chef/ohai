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

Ohai.plugin(:Irq) do
  depends "cpu"
  provides "irq"

  collect_data(:linux) do
    irq Mash.new

    cpus = cpu['total']

    File.open("/proc/interrupts").each do |line|
      # Documentation: https://www.kernel.org/doc/Documentation/filesystems/proc.txt
      # format is "{irqn}: {CPUn...} [type] [vector] [device]"
      irqn, fields = line.split(":", 2)
      # skip the header
      next if fields.nil?

      irqn.strip!
      Ohai::Log.debug("irq: processing #{irqn}")

      irq[irqn] = Mash.new
      irq[irqn][:events_by_cpu] = Mash.new

      fields = fields.split(' ', cpus+1)
      (0..cpus-1).each do |cpu|
        if /\d+/.match(fields[cpu])
          irq[irqn][:events_by_cpu][cpu] = fields[cpu].to_i
        else
          irq[irqn][:events_by_cpu][cpu] = 0
        end
      end
      # Only regular IRQs have extra fields and affinity settings
      if /\d+/.match(irqn)
        irq[irqn][:type], irq[irqn][:vector], irq[irqn][:device] = fields[cpus].split

        # Documentation: https://www.kernel.org/doc/Documentation/IRQ-affinity.txt
        # format: comma-separate list of 32bit bitmask in hex
        # each bit is a CPU, right to left ordering (i.e. CPU0 is rightmost)
        if File.exists?("/proc/irq/#{irqn}/smp_affinity")
          masks = File.read("/proc/irq/#{irqn}/smp_affinity").strip
          bit_masks = []
          masks.split(",").each do |mask|
	    if mask.length != 8
              mask = "0" * (8 - mask.length) + mask
            end
            bit_masks << mask.to_i(16).to_s(2)
          end
          affinitize_mask = bit_masks.join()
          affinitize_by_cpu = affinitize_mask.split('').reverse()
          irq[irqn][:affinitize_by_cpu] = Mash.new
          (0..cpus-1).each do |cpu|
            irq[irqn][:affinitize_by_cpu][cpu] = affinitize_by_cpu[cpu].to_i == 1 ? true : false
          end
        end
      # ERR and MIS do not have any extra fields
      elsif fields[cpus]
        irq[irqn][:type] = fields[cpus].strip
      end
    end
  end
end
