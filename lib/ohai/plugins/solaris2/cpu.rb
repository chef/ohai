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
  
  collect_data(:solaris2) do
    cpu Mash.new
    # This does assume that /usr/bin/kstat is in the path
    processor_info = shell_out("kstat -p cpu_info").stdout.lines
    cpu["total"]=0 
    cpu["sockets"]=0 
    cpu["cores"]=0
    cpu["corethreads"]=0
    cpu["total_online"]=0
    cpu["total_offline"]=0

    currentcpu=0
    cpucores=Array.new
    cpusockets=Array.new
    processor_info.each_with_index do |processor, i|
      desc,instance,record,keyvalue = processor.split(":")
      cpu[instance] = Mash.new if cpu[instance].nil?
      if ( currentcpu != instance )
         cpu["total"]+=1
         currentcpu = instance
      end 
      kv=keyvalue.gsub(/\s+/,"=").split(/=/)
      key=kv.shift
      value=kv.join(" ").chomp
      case key
        when /chip_id/
           cpu[instance]["socket"] = value
           cpusockets.push(value) if cpusockets.index(value).nil?
        when /cpu_type/
           cpu[instance]["arch"]=value
        when /clock_MHz/
           cpu[instance]["mhz"]=value
        when /brand/
           cpu[instance]["model_name"]=value.sub(/\s+/," ")
        when /state$/
           cpu[instance]["state"]=value
           cpu["total_offline"]+=1 if ( value.include? "off-line" )
           cpu["total_online"]+=1 if ( value.include? "on-line" )
        when /core_id/
           cpu[instance]["core_id"]=value
           # Detect hyperthreading/multithreading
           cpucores.push(value) if cpucores.index(value).nil?
        when /family|fpu_type|model|stepping|vendor_id/
           cpu[instance][key]=value
      end
    end
    cpu["cores"]=cpucores.size
    cpu["corethreads"]=(cpu["total"]/cpucores.size)
    cpu["sockets"]=cpusockets.size
    cpu["real"]=cpusockets.size
  end
end
