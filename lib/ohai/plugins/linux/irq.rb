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
      irqn, fields = line.split(":", 2)
      next if fields.nil?
      irqn.strip!

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
      if /\d+/.match(irqn)
        irq[irqn][:type], irq[irqn][:vector], irq[irqn][:device] = fields[cpus].split
      else
        irq[irqn][:type] = fields[cpus].strip
      end
    end
  end
end
