# Ohai Changelog

## Unreleased: 7.2.0

* [**Lance Bragstad**:](https://github.com/lbragstad)
  Added platform_family support for ibm_powerkvm (OHAI-558)
* [**Pierre Carrier**:](https://github.com/pcarrier)
  EC2 metadata errors are unhelpful (OHAI-566)
* [**Elan Ruusamae**:](https://github.com/glensc)
  Support deep virtualization systems in node[:virtualization][:systems] (OHAI-182)
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

* `Ohai::Exceptions::AttributeNotFound` errors in Chef's ohai resource
* Be reluctant to call something an LXC host (OHAI-573)

## Last Release: 7.0.0 (04/01/2014)

http://www.getchef.com/blog/2014/04/08/release-chef-client-11-12-0-10-32-2/
