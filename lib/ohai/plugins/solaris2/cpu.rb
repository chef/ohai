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

Ohai.plugin(:CPU) do
  provides "cpu"
  
  def set_x86_processor_info
    processor_info = shell_out("psrinfo -v -p | grep Hz").stdout
    processors = processor_info.split(/^    [^\s]/)
    processors.each_with_index do |processor, i|
      cpu_info, model_name = processor.split("\n      ")
      cpu_info = cpu_info.tr("()","").split

      index = i.to_s
      cpu[index] = Mash.new
      cpu[index]["vendor_id"] = cpu_info[1]
      cpu[index]["family"] = cpu_info[4]
      cpu[index]["model"] = cpu_info[6]
      cpu[index]["stepping"] = cpu_info[8]
      cpu[index]["model_name"] = model_name.strip
      cpu[index]["mhz"] = cpu_info[10]
    end
  end

  def set_sparc_processor_info
    i = 0
    cores = 0
    shell_out("psrinfo -v -p").stdout.lines.each do |line|
      case  line.strip
        when /(\d+)\s+cores/
          cores += $1.to_i
        when /^(\S+).*\b(\d+)\s+MHz\)$/
          index = i.to_s
          cpu[index] = Mash.new
          cpu[index]["model_name"] = $1
          cpu[index]["mhz"] = $2
          i += 1
      end
    end
    cpu[:cores] = cores
  end

  collect_data(:solaris2) do
    cpu Mash.new
    cpu[:total] = shell_out("psrinfo | wc -l").stdout.to_i
    cpu[:real] = shell_out("psrinfo -p").stdout.to_i
    
    processor_type = shell_out("uname -p").stdout.strip
    if processor_type == "sparc"
        set_sparc_processor_info
    else
        set_x86_processor_info
    end
  end
end
