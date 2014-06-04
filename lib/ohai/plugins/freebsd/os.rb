#
# Authors:: Adam Jacob (<adam@opscode.com>)
#           Richard Manyanza (<liseki@nyikacraftsmen.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# Copyright:: Copyright (c) 2014 Richard Manyanza.
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

require 'ohai/mixin/os'

Ohai.plugin(:OS) do
  provides "os", "os_version"

  collect_data(:freebsd) do
    os collect_os

    # This is __FreeBSD_version. See sys/param.h or 
    # http://www.freebsd.org/doc/en/books/porters-handbook/freebsd-versions.html.
    os_version shell_out("sysctl -n kern.osreldate").stdout.split($/)[0]
  end
end
