#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Bryan McLellan (<btm@loftninjas.org>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
# Copyright:: Copyright (c) 2009 Bryan McLellan
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Ohai.plugin(:PS) do
  provides "command/ps"
  depends "command"

  collect_data(:aix, :darwin, :hpux, :linux, :solaris2) do
    command[:ps] = "ps -ef"
  end

  collect_data(:freebsd, :netbsd, :openbsd, :dragonflybsd) do
    # ps -e requires procfs
    command[:ps] = "ps -axww"
  end
end
