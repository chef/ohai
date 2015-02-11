# Ohai Changelog

## Unreleased:

* [**Warren Bain**](https://github.com/thoughtcroft)
  Fix for removal of :Config in ruby 2.2
* [**Chris Luciano**](https://github.com/cmluciano)
  Add language elixir
* [**Chris Luciano**](https://github.com/cmluciano)
  Update WARNING for ohai 7 syntax docs page
* [**Malte Swart**](https://github.com/mswart)
  ssh_host_key: detect ed25519 host key
* [**hirose31**](https://github.com/hirose31)
  Detect OpenStack guest server using dmidecode
* [**Chris Luciano**](https://github.com/cmluciano)
  Add language rust.
* [**Tim Smith**](https://github.com/tas50)
  Add additional information on the PHP engine versions to PHP plugin

## Release 8.0.0

* [**sawanoboly**](https://github.com/sawanoboly)
  Retrieve OpenStack-specific metadata.
* [**Olle Lundberg**](https://github.com/lndbrg)
  Add Cloudstack support.
* [**Tim Smith**](https://github.com/tas50)
  Remove newlines in CPU strings on Darwin.
* [**Nathan Huff**](https://github.com/nhuff)
  Match zpool output for OmniOS 151006.
* [**Pavel Yudin**](https://github.com/Kasen)
  Add Parallels Cloud Server (PCS) platform support.
* [**Christian Vozar**](https://github.com/christianvozar):
  Add Go language plugin.
* [**Phil Dibowitz**](https://github.com/jaymzh):
  regression: qualify device names from lsblk
* [**Chris Read**](https://github.com/cread):
  Add support for ip version ss131122.
* [**carck**](https://github.com/carck):
  Reduce GCE metadata timeout to 6 seconds.
* [**barnabear**](https://github.com/barnabear):
  Add Pidora platform detection.
* [**Ben Carpenter**](https://github.com/bcarpenter):
  Presume 'latest' API version on 404 from Eucalyptus metadata server.
* [**Nabeel Shahzad**](https://github.com/nshahzad):
  Look for any number of spaces between the VxID and the value.
* [**Daniel Searles**](https://github.com/squaresurf):
  Removed *.static.cloud-ips.com and fixed the DNS resolution on Rackspace hosts.

* Update specs to use RSpec 3 syntax
* Update mixlib-shellout pin to ~> 2.x

## Release 7.6.0

* This release was yanked due to mixlib-shellout 1.x/2.x issues

## Release 7.4.0

* Added Powershell plugin.

## Release 7.2.4

* [**Phil Dibowitz**](https://github.com/jaymzh):
  linux::network should handle ECMP routes

## Release 7.2.2

* [**Phil Dibowitz**:](https://github.com/jaymzh)
  Use lsblk instead of blkid if available.
* [**Phil Dibowitz**:](https://github.com/jaymzh)
  linux::filesystem now reads all of /proc/mounts instead of just 4K

## Release: 7.2.0

* [**Lance Bragstad**:](https://github.com/lbragstad)
  Added platform_family support for ibm_powerkvm (OHAI-558)
* [**Pierre Carrier**:](https://github.com/pcarrier)
  EC2 metadata errors are unhelpful (OHAI-566)
* [**Elan Ruusamäe**:](https://github.com/glensc)
  Support deep virtualization systems in `node[:virtualization][:systems]` (OHAI-182)
* [**Sean Walberg**:](https://github.com/swalberg)
  :Passwd plugin now ignores duplicate users. (OHAI-561)
* [**Joe Richards**:](https://github.com/viyh)
  Fix warning message about constants already defined (OHAI-572)
* [**Tim Smith**:](https://github.com/tas50)
  Present all CPU flags on FreeBSD (OHAI-568)
* [**Tim Smith**:](https://github.com/tas50)
  Ohai doesn't detect all KVM processor types as KVM on FreeBSD (OHAI-575)
* [**Tim Smith**:](https://github.com/tas50)
  Ohai should expose mdadm raid information on Linux systems (OHAI-578)
* [**Cam Cope**:](https://github.com/ccope)
  relax regex to match newer Oracle Solaris releases (OHAI-563)
* [**Vasiliy Tolstov**:](https://github.com/vtolstov)
  add exherbo support (OHAI-570)
* [**jasonpgignac**](https://github.com/jasonpgignac)
  Add inode information to the Linux Filesystem plugin. (OHAI-539)
* [**Benedikt Böhm**](https://github.com/hollow)
  Change log-level from warn to debug for missing gateway IPs.
* [**sawanoboly**](https://github.com/sawanoboly)
  Include Joyent SmartOS specific attributes in Ohai. (OHAI-458)
* [**Mike Fiedler**](https://github.com/miketheman)
  Collect ec2 metadata even if one of the resources returns a 404. (OHAI-541)
* [**Pat Collins**](https://github.com/patcoll)
  Provide basic memory information for Mac OS X. (OHAI-431)
* [**Jerry Chen**](https://github.com/jcsalterego):
  Rackspace plugin rescues Errno::ENOENT if xenstor-* utils are not found (OHAI-587)


* root_group provider not implemented for Windows (OHAI-491)
* `Ohai::Exceptions::AttributeNotFound` errors in Chef's ohai resource
* Be reluctant to call something an LXC host (OHAI-573)
* Assume 'latest' metadata versions on 404

## Release: 7.0.4

* Added platform_family support for ibm_powerkvm (OHAI-558)
* cannot disable Lsb plugin (OHAI-565)
* Skip v7 plugins when refreshing a v6 plugin. Fixes (OHAI-562)
  `Ohai::Exceptions::AttributeNotFound` errors in Chef's ohai resource
* Work around libc bug in `hostname --fqdn`
* Report Suse and OpenSuse seperately in the :platform attribute.
* CPU information matching linux is now available on darwin.
* ip6address detection failure logging is turned down to :debug.
* fe80:: link-local address is not reported as ip6addresses anymore.
* Private network information is now available as [:rackspace][:private_networks] on Rackspace nodes.
* System init mechanism is now reported at [:init_package] on linux.
* Define cloud plugin interface (OHAI-542)
* java -version wastes memory (OHAI-550)
* Ohai cannot detect running in an lxc container (OHAI-551)
* Normalize cloud attributes for Azure (OHAI-554)
* Capture FreeBSD osreldate for comparison purposes (OHAI-557)

http://www.getchef.com/blog/2014/04/09/release-chef-client-11-12-2/
