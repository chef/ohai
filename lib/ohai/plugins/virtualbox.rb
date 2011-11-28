#
# Author:: Philip (flip) Kromer (<flip@infochimps.com>)
# Copyright:: Copyright (c) 2011 Infochimps, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

provides "vagrant"

require_plugin "hostname"
require_plugin "kernel"
require_plugin "network"
require_plugin "virtualization"

extend Ohai::Mixin::Command

def looks_like_virtualbox?
  virtualization[:system] == "vbox"
end

#
# given a property tuple like
#   ["GuestInfo/Net/1/IP", "33.33.33.12", "1322321247836958000", "<NULL>"]
# sets the corresponding ohai property
#   ohai.virtualbox[:guest_info][:net]['1'][:ip] = "33.33.33.12"
#
# Note that we don't try to be clever about the '1' being an array: all property
# tree branches are hashlike.
#
def set_virtualbox_property(name, val, timestamp, flags)
  name_segs = name.wmi_underscore.split("/")
  val = nil if val == '<NULL>'
  # walk out through the hash: ['guest_info','net','1','ip'] gets
  # virtualbox['guest_info'], virtualbox['guest_info']['net'] and so forth
  branch = virtualbox ; leaf_seg = name_segs.pop
  name_segs.each{|seg| branch[seg] ||= Mash.new ; branch = branch[seg] }
  branch[leaf_seg] = val
end

#
# run the virtualbox property sniffer to get
#
def get_virtualbox_info
  vbox_info_blob = run_virtualbox_sniffer
  if vbox_info_blob
    vbox_info_blob.split("\n").each do |line|
      line.strip!
      case line
      when /^Name: \/VirtualBox\/([^,]+), value: ([^,]+), timestamp: (\d+), flags: (.*)/
        set_virtualbox_property($1, $2, $3, $4)
      when "" then next
      when /^(?:Oracle VM VirtualBox|\(C\) \d+-\d+|All rights)/ then next
      else
        Ohai::Log.debug("bogus virtualbox sniffer line #{line}")
      end
    end
  else
    virtualbox[:cannot_sniff] = true
  end
end

#
# * `:private_xx`: ipv4 private address space IPs are classified by which private space
# * `:host_only`:  33.33.xx.xx -- by convention, these are host-only (private) subnets
# * `:public`:     anything else
#
# Note that 192.168.xx.xx addresses are classified as **private**, even if that
# address is used to poke out to your local router's LAN subnet.
#
# @returns [Symbol] one of [:private_24, :private_20, :private_16, :host_only, :public]
def vbox_classify_interface(ipv4)
  case ipv4
  # http://en.wikipedia.org/wiki/IP_address#IPv4_private_addresses --
  #
  when /^10\.\d+\.\d+\.\d+$/                   then :private_24
  when /^172\.(?:1[6-9]|2\d|3[01])\.\d+\.\d+$/ then :private_20
  when /^192\.168\.\d+\.\d+$/                  then :private_16
  when /^33\.33\.\d+\.\d+$/                    then :host_only
  else :public
  end
end

#
# Lists ipv4 address of all virtualbox-enumerated interfaces, in the order
# virtualbox constructs them.
#
def get_net_info_from_sniffed
  net_count = virtualbox[:guest_info][:net][:count].to_i
  net_infos = virtualbox[:guest_info][:net].reject{|k,v| k == "count"}
  net_infos.
    sort_by{|idx_str, info| idx_str.to_i }.
    map{|idx_str, info| info[:v4][:ip] }
end

#
# Lists ipv4 address of all non-Loopback interfaces, with the address
# corresponding to network[:default_interface] listed first.
#
def get_net_info_from_network
  ips = []
  network[:interfaces].sort_by{|k,v| k.to_s }.each do |name, info|
    next if info[:encapsulation] == 'Loopback'
    ip = info[:addresses].keys.detect{|addr| info[:addresses][addr][:family] == 'inet' }
    if name == network[:default_interface]
      ips.unshift(ip)
    else
      ips.push(ip)
    end
  end
  ips.flatten.compact.uniq
end

#
# File the interfaces into public and private, using the following rules:
#
# * host_only:   ips in 33.33.xx.xx by convention
# * private_ips:
#   - host-only ips
#   - in IPv4 private address space (10.xx.xx.xx, 172.16.xx.xx to 172.31.xx.xx, and 192.168.xx.xx)
# * public_ips:  everything else
#
# and this exception:
# * if no public_ips, the first non-host-only ip is relocated to public_ips,
#   under the assumption that is the interface open to the host machine
#
def normalize_virtualbox_info
  virtualbox[:public_ips]    = []
  virtualbox[:private_ips]   = []
  virtualbox[:host_only_ips] = []
  if virtualbox[:guest_info] && virtualbox[:guest_info][:net]
    ips = get_net_info_from_sniffed
  else
    ips = get_net_info_from_network
  end
  ips.each do |ip|
    case vbox_classify_interface(ip)
    when :private_24, :private_20, :private_16
      virtualbox[:private_ips] << ip
    when :host_only
      virtualbox[:private_ips] << ip
      virtualbox[:host_only_ips] << ip
    else
      virtualbox[:public_ips] << ip
    end
  end
  if virtualbox[:public_ips].empty?
    first_private_ip = (virtualbox[:private_ips] - virtualbox[:host_only_ips]).first
    if first_private_ip
      virtualbox[:public_ips]   = [first_private_ip]
      virtualbox[:private_ips] -= [first_private_ip]
    end
  end
  virtualbox[:local_ipv4]      = virtualbox[:host_only_ips].first || virtualbox[:private_ips].first
  virtualbox[:public_ipv4]     = virtualbox[:public_ips].first
  virtualbox[:public_hostname] = fqdn
end

#
# path to virtualbox property sniffer: on windows, 'VboxControl.exe', else 'VboxControl'
#
def vbox_control_program
  if RUBY_PLATFORM =~ /mswin|mingw32|windows/
    'VBoxControl.exe'
  else
    'VBoxControl'
  end
end

def run_virtualbox_sniffer
  begin
    status, stdout, stderr = run_command(:command => "#{vbox_control_program} guestproperty enumerate", :no_status_check => true)
    if    status == 0 # success!
      return stdout
    elsif status == 1 # sadness, but a sadness we understand
      if stderr =~ /user\s+permissions/
        Ohai::Log.debug("cannot gather virtualbox information: must be root")
      else
        Ohai::Log.debug("cannot gather virtualbox information, #{vbox_control_program} says: #{stderr}")
      end
    else              # error code, and we don't know why
      Ohai::Log.debug("cannot gather virtualbox information, #{vbox_control_program} returned an unknown error code")
    end
  rescue Ohai::Exceptions::Exec => boom
    Ohai::Log.debug("no virtualbox extensions installed, or can't find VBoxControl program")
  end
  return nil
end

if looks_like_virtualbox?
  Ohai::Log.debug("looks_like_virtualbox? == true")
  virtualbox Mash.new
  get_virtualbox_info
  normalize_virtualbox_info
else
  Ohai::Log.debug("looks_like_virtualbox? == false")
  false
end
