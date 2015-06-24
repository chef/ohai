#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Benjamin Black (<nostromo@gmail.com>)
# Author:: Bryan McLellan (<btm@loftninjas.org>)
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Author:: James Gartrell (<jgartrel@gmail.com>)
# Copyright:: Copyright (c) 2008, 2009 Opscode, Inc.
# Copyright:: Copyright (c) 2009 Bryan McLellan
# Copyright:: Copyright (c) 2009 Daniel DeLeo
# Copyright:: Copyright (c) 2010 VMware, Inc.
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

require 'socket'
require 'ipaddr'

Ohai.plugin(:Hostname) do
  provides "domain", "hostname", "fqdn", "machinename"

  # hostname : short hostname
  # machinename : output of hostname command (might be short on solaris)
  # fqdn : result of canonicalizing hostname using DNS or /etc/hosts
  # domain : domain part of FQDN
  #
  # hostname and machinename should always exist
  # fqdn and domain may be broken if DNS is broken on the host

  def from_cmd(cmd)
    so = shell_out(cmd)
    so.stdout.split($/)[0]
  end

  # forward and reverse lookup to canonicalize FQDN (hostname -f equivalent)
  # this is ipv6-safe, works on ruby 1.8.7+
  def resolve_fqdn
    begin
      hostname = from_cmd("hostname")
      addrinfo = Socket.getaddrinfo(hostname, nil).first
      iaddr = IPAddr.new(addrinfo[3])
      Socket.gethostbyaddr(iaddr.hton)[0]
    rescue
      nil
    end
  end

  def collect_domain
    # Domain is everything after the first dot
    if fqdn
      fqdn =~ /.+?\.(.*)/
      domain $1
    end
  end

  def collect_hostname
    # Hostname is everything before the first dot
    if machinename
      machinename =~ /(\w+)\.?/
      hostname $1
    elsif fqdn
      fqdn =~ /(.+?)\./
      hostname $1
    end
  end

  def get_fqdn_from_sigar
    require 'sigar'
    sigar = Sigar.new
    sigar.fqdn
  end

  def sigar_is_available?
    begin
      require 'sigar'
      true
    rescue LoadError
      false
    end
  end

  collect_data(:aix, :hpux, :default) do
    machinename from_cmd("hostname")
    fqdn sigar_is_available? ? get_fqdn_from_sigar : resolve_fqdn
    collect_hostname
    collect_domain
  end

  collect_data(:darwin, :netbsd, :openbsd) do
    hostname from_cmd("hostname -s")
    fqdn resolve_fqdn
    machinename from_cmd("hostname")
    collect_domain
  end

  collect_data(:freebsd) do
    hostname from_cmd("hostname -s")
    machinename from_cmd("hostname")
    fqdn from_cmd("hostname -f")
    collect_domain
  end

  collect_data(:linux) do
    hostname from_cmd("hostname -s")
    machinename from_cmd("hostname")
    begin
      ourfqdn = from_cmd("hostname --fqdn")
      # Sometimes... very rarely, but sometimes, 'hostname --fqdn' falsely
      # returns a blank string. WTF.
      if ourfqdn.nil? || ourfqdn.empty?
        Ohai::Log.debug("hostname --fqdn returned an empty string, retrying " +
                        "once.")
        ourfqdn = from_cmd("hostname --fqdn")
      end

      if ourfqdn.nil? || ourfqdn.empty?
        Ohai::Log.debug("hostname --fqdn returned an empty string twice and " +
                        "will not be set.")
      else
        fqdn ourfqdn
      end
    rescue
      Ohai::Log.debug(
        "hostname --fqdn returned an error, probably no domain set")
    end
    domain collect_domain
  end

  collect_data(:solaris2) do
    machinename from_cmd("hostname")
    hostname from_cmd("hostname")
    fqdn resolve_fqdn
    domain collect_domain
  end

  collect_data(:windows) do
    require 'wmi-lite/wmi'
    require 'socket'

    wmi = WmiLite::Wmi.new
    host = wmi.first_of('Win32_ComputerSystem')

    hostname "#{host['dnshostname']}"
    machinename "#{host['name']}"

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
