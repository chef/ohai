#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

Ohai.plugin(:Hostname) do
  provides "domain", "hostname", "fqdn"

  def from_cmd(cmd)
    so = shell_out(cmd)
    so.stdout.split($/)[0]
  end

  def collect_domain
    # Domain is everything after the first dot
    if fqdn
      fqdn =~ /.+?\.(.*)/
      domain $1
    end
  end
  
  collect_data(:default) do
    domain collect_domain
  end

  collect_data(:aix, :hpux, :sigar) do
    require 'sigar'
    sigar = Sigar.new
    hostname sigar.net_info.host_name
    fqdn sigar.fqdn
    domain collect_domain
  end

  collect_data(:darwin, :netbsd, :openbsd) do
    hostname from_cmd("hostname -s")
    fqdn from_cmd("hostname")
    domain collect_domain
  end

  collect_data(:freebsd) do
    hostname from_cmd("hostname -s")
    fqdn from_cmd("hostname -f")
    domain collect_domain
  end

  collect_data(:linux) do
    hostname from_cmd("hostname -s")
    begin
      fqdn from_cmd("hostname --fqdn")
    rescue
      Ohai::Log.debug("hostname -f returned an error, probably no domain is set")
    end
    domain collect_domain
  end

  collect_data(:solaris2) do
    require 'socket'

    hostname from_cmd("hostname")
    fqdn_lookup = Socket.getaddrinfo(hostname, nil, nil, nil, nil, Socket::AI_CANONNAME).first[2]
    if fqdn_lookup.split('.').length > 1
      # we recieved an fqdn
      fqdn fqdn_lookup
    else
      # default to assembling one
      so = shell_out("hostname")
      h = so.stdout.split($/)[0]
      so = shell_out("domainname")
      d = so.stdout.split($/)[0]

      fqdn("#{h}.#{d}")
    end
    domain collect_domain
  end

  collect_data(:windows) do
    require 'ruby-wmi'
    require 'socket'

    host = WMI::Win32_ComputerSystem.find(:first)
    hostname "#{host.Name}"

    info = Socket.gethostbyname(Socket.gethostname)
    if info.first =~ /.+?\.(.*)/
      fqdn info.first
    else
      #host is not in dns. optionally use:
      #C:\WINDOWS\system32\drivers\etc\hosts
      fqdn Socket.gethostbyaddr(info.last).first
    end
    domain collect_domain
  end
end

