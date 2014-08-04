#
# Author:: Julian C. Dunn (<jdunn@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

Ohai.plugin(:Virtualization) do
  provides "virtualization"

  collect_data(:aix) do
    virtualization Mash.new

    so = shell_out("uname -L")
    lpar_no = so.stdout.split($/)[0].split(/\s/)[0]
    lpar_name = so.stdout.split($/)[0].split(/\s/)[1]

    unless lpar_no.to_i == -1 || (lpar_no.to_i == 1 && lpar_name == "NULL")
      virtualization[:lpar_no] = lpar_no
      virtualization[:lpar_name] = lpar_name
    end

    so = shell_out("uname -W")
    wpar_no = so.stdout.split($/)[0]
    virtualization[:wpar_no] = wpar_no unless wpar_no.to_i == 0

  end
end