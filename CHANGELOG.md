# Ohai Changelog

## Unreleased: 7.0.2

* Skip v7 plugins when refreshing a v6 plugin. Fixes
  `Ohai::Exceptions::AttributeNotFound` errors in Chef's ohai resource

## Last Release: 7.0.0 (04/08/2014)

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

http://www.getchef.com/blog/2014/01/20/ohai-7-0-release-candidate/
http://www.getchef.com/blog/2014/04/08/release-chef-client-11-12-0-10-32-2/
