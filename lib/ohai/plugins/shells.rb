#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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

Ohai.plugin(:Shells) do
  provides "shells"

  collect_data do
    if ::File.exist?("/etc/shells")
      shells []
      ::File.readlines("/etc/shells").each do |line|
        # remove carriage returns and skip over comments / empty lines
        shells << line.chomp if line[0] == "/"
      end
    end
  end
end
