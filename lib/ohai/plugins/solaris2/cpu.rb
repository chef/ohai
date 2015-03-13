#
# Author:: Isa Farnik (isa@chef.io)
# Copyright:: Copyright (c) 2015 Chef Software Inc.
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

Ohai.plugin(:CPU) do
  provides "cpu"

  collect_data(:solaris2) do
    cpu Mash.new

    cpu[:total] = shell_out("psrinfo | wc -l").stdout.to_i
    cpu[:real] = shell_out("psrinfo -p").stdout.to_i

    #  CPU flags could be collected from:
    #  /usr/bin/isainfo -v

    #  Cores and virtual processors can
    #  also be collected from psrinfo
    #
    #  Tested against:
    #    - Sun-Fire-V245
    #    - T5240
    #    - Dell R610

    #  Matches:
    #    - model_name
    #    - chipid
    #    - vender_id
    #    - family
    #    - model
    #    - step
    #    - clock
    #    - intel-specific details
    cpu_regex=%r{(?<proc_specs>(?<model_name>[^\s]*) \((?:.*?(?:chipid (?<chipid>\d+(?:x\d+)*),* )*.*?(?:(?<vender_id>GenuineIntel) )*.*?(?:.{5} )*.*?(?:family (?<family>\d+) )*.*?(?:model (?<model>\d+) )*.*?(?:step (?<step>\d+) )*)(?:clock (?<mhz>\d+) MHz).*?\))(?<alt_spec>(?:\n[\s\t]*(?<alt_model>(?<intel_model>.*?) CPU(?:[\s\t]{4,}).*?(?<intel_model_num>\w*)\s*.*?(?<ghz>\d+(?:\.\d+))GHz))*)*}

    cpu[:real].times do |cpu_slot|
      processor_info = shell_out("psrinfo -v -p #{cpu_slot}").stdout
      results = processor_info.match(cpu_regex)
      cpu[cpu_slot.to_i] = Mash[ results.names.zip( results.captures ) ]

      #  Replace the model name when CPU model
      #  is generic and CPU is Intel
      if cpu[cpu_slot.to_i][:model_name] == 'x86' || cpu[cpu_slot.to_i][:alt_spec].include?("Intel")
        replacement_model = cpu[cpu_slot.to_i][:alt_model].gsub(/\s{2,}/, ' ')
        cpu[cpu_slot.to_i][:proc_specs].gsub(/x86/, replacement_model)
        cpu[cpu_slot.to_i][:model_name] = "#{cpu[cpu_slot.to_i][:intel_model]} #{cpu[cpu_slot.to_i][:intel_model_num]}"
      end

      #  Clear empty values
      cpu[cpu_slot.to_i].each do |key,value|
        if value.nil? || value == ""
         cpu[cpu_slot.to_i].delete(key)
        end
      end
    end
  end
end
