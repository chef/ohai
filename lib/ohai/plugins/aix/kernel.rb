#
# Author:: Joshua Timberman <joshua@chef.io>
# Author:: Isa Farnik (<isa@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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

Ohai.plugin(:Kernel) do
  provides "kernel", "kernel/modules"

  collect_data(:aix) do
    kernel Mash.new

    kernel[:name] =    shell_out("uname -s").stdout.split($/)[0].downcase
    kernel[:release] = shell_out("uname -r").stdout.split($/)[0]
    kernel[:version] = shell_out("uname -v").stdout.split($/)[0]
    kernel[:machine] = shell_out("uname -p").stdout.split($/)[0]
    kernel[:bits] =    shell_out("getconf KERNEL_BITMODE").stdout.strip

    modules = Mash.new
    so = shell_out("genkex -d")
    #     Text address     Size     Data address     Size File
    #
    # f1000000c0338000    77000 f1000000c0390000    1ec8c /usr/lib/drivers/cluster
    #          6390000    20000          63a0000      ba8 /usr/lib/drivers/if_en
    # f1000000c0318000    20000 f1000000c0320000    17138 /usr/lib/drivers/random
    so.stdout.lines do |line|
      if line =~ /\s*([0-9a-f]+)\s+([0-9a-f]+)\s+([0-9a-f]+)\s+([0-9a-f]+)\s+([a-zA-Z0-9\/\._]+)/
        modules[$5] = { :text => { :address => $1, :size => $2 }, :data => { :address => $3, :size => $4 } }
      end
    end

    kernel[:modules] = modules
  end
end
