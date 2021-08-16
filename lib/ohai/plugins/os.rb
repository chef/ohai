# frozen_string_literal: true
#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Isa Farnik (<isa@chef.io>)
# Author:: Richard Manyanza (<liseki@nyikacraftsmen.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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

Ohai.plugin(:OS) do
  require_relative "../mixin/os"
  provides "os", "os_version"
  depends "kernel"

  collect_data(:aix) do
    os collect_os
    os_version shell_out("oslevel -s").stdout.strip
  end

  collect_data(:dragonflybsd, :freebsd) do
    os collect_os

    # This is __DragonFly_version / __FreeBSD_version. See sys/param.h or
    # http://www.freebsd.org/doc/en/books/porters-handbook/freebsd-versions.html.
    os_version shell_out("sysctl -n kern.osreldate").stdout.strip
  end

  collect_data(:target) do
    os collect_os
  end

  collect_data do
    os collect_os
    os_version kernel[:release]
  end
end
