# frozen_string_literal: true
#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Benjamin Black (<nostromo@gmail.com>)
# Author:: Bryan McLellan (<btm@loftninjas.org>)
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Author:: James Gartrell (<jgartrel@gmail.com>)
# Author:: Isa Farnik (<isa@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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
    shell_out(cmd).stdout.strip
  end

  # forward and reverse lookup to canonicalize FQDN (hostname -f equivalent)
  # this is ipv6-safe, works on ruby 1.8.7+
  def resolve_fqdn
    require "socket" unless defined?(Socket)
    require "ipaddr" unless defined?(IPAddr)

    hostname = from_cmd("hostname")
    begin
      addrinfo = Socket.getaddrinfo(hostname, nil).first
    rescue SocketError
      # In the event that we got an exception from Socket, it's possible
      # that it will work if we restrict it to IPv4 only either because of
      # IPv6 misconfiguration or other bugs.
      #
      # Specifically it's worth noting that on macOS, getaddrinfo() will choke
      # if it gets back a link-local address (say if you have 'fe80::1 myhost'
      # in /etc/hosts). This will raise:
      #    SocketError (getnameinfo: Non-recoverable failure in name resolution)
      #
      # But general misconfiguration could cause similar issues, so attempt to
      # fall back to v4-only
      begin
        addrinfo = Socket.getaddrinfo(hostname, nil, :INET).first
      rescue
        # and if *that* fails, then try v6-only, in case we're in a v6-only
        # environment with v4 config issues
        addrinfo = Socket.getaddrinfo(hostname, nil, :INET6).first
      end
    end
    iaddr = IPAddr.new(addrinfo[3])
    Socket.gethostbyaddr(iaddr.hton)[0]
  rescue
    nil
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
      machinename =~ /([^.]+)\.?/
      hostname $1
    elsif fqdn
      fqdn =~ /(.+?)\./
      hostname $1
    end
  end

  collect_data(:default) do
    machinename from_cmd("hostname")
    fqdn resolve_fqdn
    collect_hostname
    collect_domain
  end

  collect_data(:aix) do
    machinename from_cmd("hostname -s")
    fqdn resolve_fqdn || from_cmd("hostname")
    collect_hostname
    collect_domain
  end

  collect_data(:netbsd, :openbsd, :dragonflybsd) do
    hostname from_cmd("hostname -s")
    fqdn resolve_fqdn
    machinename from_cmd("hostname")
    collect_domain
  end

  collect_data(:darwin) do
    hostname from_cmd("hostname -s")
    machinename from_cmd("hostname")
    begin
      our_fqdn = resolve_fqdn
      # Sometimes... very rarely, but sometimes, 'hostname --fqdn' falsely
      # returns a blank string. WTF.
      if our_fqdn.nil? || our_fqdn.empty?
        logger.trace("Plugin Hostname: hostname returned an empty string, retrying once.")
        our_fqdn = resolve_fqdn
      end

      if our_fqdn.nil? || our_fqdn.empty?
        logger.trace("Plugin Hostname: hostname returned an empty string twice and will" +
                        "not be set.")
      else
        fqdn our_fqdn
      end
    rescue
      logger.trace(
        "Plugin Hostname: hostname returned an error, probably no domain set"
      )
    end
    domain collect_domain
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
      our_fqdn = from_cmd("hostname --fqdn")
      # Sometimes... very rarely, but sometimes, 'hostname --fqdn' falsely
      # returns a blank string. WTF.
      if our_fqdn.nil? || our_fqdn.empty?
        logger.trace("Plugin Hostname: hostname --fqdn returned an empty string, retrying " +
                        "once.")
        our_fqdn = from_cmd("hostname --fqdn")
      end

      if our_fqdn.nil? || our_fqdn.empty?
        logger.trace("Plugin Hostname: hostname --fqdn returned an empty string twice and " +
                        "will not be set.")
      else
        fqdn our_fqdn
      end
    rescue
      logger.trace("Plugin Hostname: hostname --fqdn returned an error, probably no domain set")
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
    require "wmi-lite/wmi" unless defined?(WmiLite::Wmi)
    require "socket" unless defined?(Socket)

    wmi = WmiLite::Wmi.new
    host = wmi.first_of("Win32_ComputerSystem")

    hostname host["dnshostname"].to_s
    machinename host["name"].to_s

    info = Addrinfo.getaddrinfo(hostname, nil).first.getnameinfo
    fqdn info.first unless fqdn
    
    domain collect_domain
  end
end
