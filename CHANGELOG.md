# Change Log

## [8.20.0](https://github.com/chef/ohai/tree/8.20.0) (2016-09-06)
[Full Changelog](https://github.com/chef/ohai/compare/v8.19.2...8.20.0)

**Implemented Enhancements:**

- Retrofit network plugin to work on Windows Nano Server [\#872](https://github.com/chef/ohai/pull/872) ([mwrock](https://github.com/mwrock))
- chefstyle 0.4.0 [\#870](https://github.com/chef/ohai/pull/870) ([lamont-granquist](https://github.com/lamont-granquist))

## [8.19.2](https://github.com/chef/ohai/tree/8.19.2) (2016-08-15)

[Full Changelog](https://github.com/chef/ohai/compare/v8.19.1...8.19.2)

**Fixed bugs:**

- Require at least mixlib-log 1.7.1 [#866](https://github.com/chef/ohai/pull/866) ([tas50](https://github.com/tas50))

## [8.19.1](https://github.com/chef/ohai/tree/8.19.1) (2016-08-12)

[Full Changelog](https://github.com/chef/ohai/compare/v8.19.0...8.19.1)

**Fixed bugs:**

- Move log configuration down to Mixlib::Log [#864](https://github.com/chef/ohai/pull/864) ([thommay](https://github.com/thommay))
- Only configure logging if we must [#863](https://github.com/chef/ohai/pull/863) ([thommay](https://github.com/thommay))

## [8.19.0](https://github.com/chef/ohai/tree/8.19.0) (2016-08-11)

[Full Changelog](https://github.com/chef/ohai/compare/v8.18.0...8.19.0)

**Implemented enhancements:**

- Add platform detection for Arista EOS [#860](https://github.com/chef/ohai/pull/860) ([jerearista](https://github.com/jerearista))

**Fixed bugs:**

- Fix installs on Ruby 2.1 and rspec testing with rspec 3.5 [#861](https://github.com/chef/ohai/pull/861) ([tas50](https://github.com/tas50))
- Fix solaris2 plugin network interface detection [#859](https://github.com/chef/ohai/pull/859) ([acaiafa](https://github.com/acaiafa))

## [8.18.0](https://github.com/chef/ohai/tree/8.18.0) (2016-08-04)

[Full Changelog](https://github.com/chef/ohai/compare/v8.17.1...8.18.0)

**Implemented enhancements:**

- Add a plugin for collecting available shells [#856](https://github.com/chef/ohai/pull/856) ([tas50](https://github.com/tas50))
- BlockDevice: Add physical and logical block size [#850](https://github.com/chef/ohai/pull/850) ([sun77](https://github.com/sun77))
- Properly detect PHP 7 [#848](https://github.com/chef/ohai/pull/848) ([tas50](https://github.com/tas50))
- Add support for Linux HugePages [#842](https://github.com/chef/ohai/pull/842) ([bjk-soundcloud](https://github.com/bjk-soundcloud))
- Add detection of Virtualbox and VMware Fusion on OS X [#840](https://github.com/chef/ohai/pull/840) ([tas50](https://github.com/tas50))
- Remove support for Ruby 2.0 [#838](https://github.com/chef/ohai/pull/838) ([tas50](https://github.com/tas50))
- Add hardware plugin for ohai on darwin [#839](https://github.com/chef/ohai/pull/839) ([natewalck](https://github.com/natewalck))

**Fixed bugs:**

- Avoid global mutation. [#852](https://github.com/chef/ohai/pull/852) ([coderanger](https://github.com/coderanger))


## [8.17.1](https://github.com/chef/ohai/tree/8.17.1) (2016-06-30)
[Full Changelog](https://github.com/chef/ohai/compare/v8.17.0...8.17.1)

**Fixed bugs:**

- Move timezone value under time [\#836](https://github.com/chef/ohai/pull/836) ([tas50](https://github.com/tas50))
- Update PowerShell Version Compat Detection / Unblock bundler on Appveyor [\#832](https://github.com/chef/ohai/pull/832) ([smurawski](https://github.com/smurawski))


## [v8.17.0](https://github.com/chef/ohai/tree/v8.17.0) (2016-06-20)
[Full Changelog](https://github.com/chef/ohai/compare/v8.16.0...v8.17.0)

**Implemented enhancements:**

- Add additional info to networking interfaces/addresses [\#830](https://github.com/chef/ohai/pull/830) ([jaymzh](https://github.com/jaymzh))
- Add a simple plugin to get the local timezone. [\#829](https://github.com/chef/ohai/pull/829) ([johnbellone](https://github.com/johnbellone))
- Switch to kernel version to identify platform_version on Gentoo [\#828](https://github.com/chef/ohai/pull/828) ([tas50](https://github.com/tas50))
- Expose ring parameters in the network plugin [\#827](https://github.com/chef/ohai/pull/827) ([davide125](https://github.com/davide125))
- Improve packages attributes [\#820](https://github.com/chef/ohai/pull/820) ([glensc](https://github.com/glensc))
- Add version for linux modules when available [\#816](https://github.com/chef/ohai/pull/816) ([jmauro](https://github.com/jmauro))
- Add freebsd support in packages plugin [\#814](https://github.com/chef/ohai/pull/814) ([vr](https://github.com/vr))

## [v8.16.0](https://github.com/chef/ohai/tree/v8.16.0) (2016-05-12)
[Full Changelog](https://github.com/chef/ohai/compare/v8.15.1...v8.16.0)

**Implemented enhancements:**

- Properly poll Openstack metadata + other Openstack improvements [\#818](https://github.com/chef/ohai/pull/818) ([tas50](https://github.com/tas50))
- Update packages plugin to support PLD Linux as an RPM distro [\#813](https://github.com/chef/ohai/pull/813) ([glensc](https://github.com/glensc))
- Add detection of bhyve guests running Linux/\*BSD [\#812](https://github.com/chef/ohai/pull/812) ([tas50](https://github.com/tas50))
- Consistent plugin debug logging [\#810](https://github.com/chef/ohai/pull/810) ([tas50](https://github.com/tas50))
- Extra debug logging and error handling in plugin loading [\#808](https://github.com/chef/ohai/pull/808) ([tas50](https://github.com/tas50))
- Language plugins: Improve failure logging, update specs, general cleanup [\#805](https://github.com/chef/ohai/pull/805) ([tas50](https://github.com/tas50))
- Add method to safely get or check the existence of attributes [\#796](https://github.com/chef/ohai/pull/796) ([mcquin](https://github.com/mcquin))

**Fixed bugs:**

- Prevent parallels spec from checking the filesystem [\#811](https://github.com/chef/ohai/pull/811) ([tas50](https://github.com/tas50))

## [v8.15.1](https://github.com/chef/ohai/tree/v8.15.1) (2016-04-20)
[Full Changelog](https://github.com/chef/ohai/compare/v8.15.0...v8.15.1)

**Fixed bugs:**

- Avoid defining WINDOWS\_ATTRIBUTE\_ALIASES multiple times [\#806](https://github.com/chef/ohai/pull/806) ([mwrock](https://github.com/mwrock))

## [8.15.0](https://github.com/chef/ohai/tree/8.15.0) (2016-04-18)
[Full Changelog](https://github.com/chef/ohai/compare/v8.14.0...8.15.0)

**Implemented enhancements:**

- Add a fips plugin to detect if fips is enabled [\#803](https://github.com/chef/ohai/pull/803) ([mwrock](https://github.com/mwrock))
- Add debug logging to hints and improve cloud specs [\#797](https://github.com/chef/ohai/pull/797) ([tas50](https://github.com/tas50))

**Fixed bugs:**

- Fix Elixir version detection on newer Elixir releases [\#802](https://github.com/chef/ohai/pull/802) ([tas50](https://github.com/tas50))
- Correct the version detection in erlang plugin [\#801](https://github.com/chef/ohai/pull/801) ([tas50](https://github.com/tas50))
- Fix mono builddate capture and add debug logging [\#800](https://github.com/chef/ohai/pull/800) ([tas50](https://github.com/tas50))
- Fix the scala plugin to properly return data [\#799](https://github.com/chef/ohai/pull/799) ([tas50](https://github.com/tas50))
- Don't execute .so libs for Windows [\#798](https://github.com/chef/ohai/pull/798) ([chefsalim](https://github.com/chefsalim))

## [8.14.0](https://github.com/chef/ohai/tree/8.14.0) (2016-04-08)

[Full Changelog](https://github.com/chef/ohai/compare/v8.13.0...8.14.0)

**Implemented enhancements:**

- Improve Linux EC2 detection, fix false detection, and add Windows detection [#793](https://github.com/chef/ohai/pull/793) ([tas50](https://github.com/tas50))
- Ohai shell_out logging, timeouts, and error handling [#788](https://github.com/chef/ohai/pull/788) ([mcquin](https://github.com/mcquin))
- Detect openSUSE Leap as platform opensuseleap [#784](https://github.com/chef/ohai/pull/784) ([tas50](https://github.com/tas50))
- Windows packages plugin - Get packages from registry [#778](https://github.com/chef/ohai/pull/778) ([sh9189](https://github.com/sh9189))

**Fixed bugs:**

- AIX: Set os_version to match the output of oslevel -s [#790](https://github.com/chef/ohai/pull/790) ([juliandunn](https://github.com/juliandunn))
- Remove ec2metadata CLI as an EC2 detection method [#787](https://github.com/chef/ohai/pull/787) ([tas50](https://github.com/tas50))
- solaris11_network: Handle solaris 11 zone interfaces [#742](https://github.com/chef/ohai/pull/742) ([MarkGibbons](https://github.com/MarkGibbons))

**Merged pull requests:**

- Update chefstyle to 0.3.1 and fix new offenses. [#789](https://github.com/chef/ohai/pull/789) ([mcquin](https://github.com/mcquin))

## [v8.13.0](https://github.com/chef/ohai/tree/v8.13.0) (2016-03-24)

[Full Changelog](https://github.com/chef/ohai/compare/v8.12.1...v8.13.0)

**Implemented enhancements:**

- Add language scala [#524](https://github.com/chef/ohai/pull/524) ([cmluciano](https://github.com/cmluciano))

**Fixed bugs:**

- Lock plist to 3.x [#779](https://github.com/chef/ohai/pull/779) ([danielsdeleo](https://github.com/danielsdeleo))

## [v8.12.1](https://github.com/chef/ohai/tree/v8.12.1) (2016-03-15)

[Full Changelog](https://github.com/chef/ohai/compare/v8.12.0...v8.12.1)

**Fixed bugs:**

- Fix gem conflicts in ruby environments that load rake 11 [#774](https://github.com/chef/ohai/pull/774) ([danielsdeleo](https://github.com/danielsdeleo))

## [v8.12.0](https://github.com/chef/ohai/tree/v8.12.0) (2016-03-09)

[Full Changelog](https://github.com/chef/ohai/compare/v8.11.1...v8.12.0)

**Implemented enhancements:**

- add plugin to detect user sessions using loginctl [#766](https://github.com/chef/ohai/pull/766) ([davide125](https://github.com/davide125))
- Improve virtualization detection on Solaris [#760](https://github.com/chef/ohai/pull/760) ([tas50](https://github.com/tas50))
- Improve FreeBSD guest virtualization detection [#756](https://github.com/chef/ohai/pull/756) ([tas50](https://github.com/tas50))
- Detect Openstack hosts [#751](https://github.com/chef/ohai/pull/751) ([tas50](https://github.com/tas50))
- Improve KVM host and guest detection [#750](https://github.com/chef/ohai/pull/750) ([tas50](https://github.com/tas50))
- Update GCE metadata API version and fail better [#736](https://github.com/chef/ohai/pull/736) ([tas50](https://github.com/tas50))

**Fixed bugs:**

- Make ohai work with Chef 12.7 and below [#768](https://github.com/chef/ohai/pull/768) ([jkeiser](https://github.com/jkeiser))
- Remove XML output in VirtualizationInfo and need for hpricot gem [#755](https://github.com/chef/ohai/pull/755) ([tas50](https://github.com/tas50))

## [v8.11.1](https://github.com/chef/ohai/tree/v8.11.1) (2016-03-08)

[Full Changelog](https://github.com/chef/ohai/compare/v8.10.0...v8.11.1)

**Implemented enhancements:**

- Detect Azure on non-bootstrapped hosts [#657](https://github.com/chef/ohai/issues/657)
- Deprecate run_command and popen4 in the command mixin [#730](https://github.com/chef/ohai/pull/730) ([tas50](https://github.com/tas50))
- OHAI-726 Regex to support openjdk 1.8 [#727](https://github.com/chef/ohai/pull/727) ([davidnewman](https://github.com/davidnewman))
- Add support for the 2 latest EC2 metadata versions [#725](https://github.com/chef/ohai/pull/725) ([tas50](https://github.com/tas50))
- Improved debug logging for cloud plugins [#724](https://github.com/chef/ohai/pull/724) ([tas50](https://github.com/tas50))
- Detect paravirt amazon instances without hint files [#722](https://github.com/chef/ohai/pull/722) ([tas50](https://github.com/tas50))
- Detect Azure using the Azure agent and DHCP options [#714](https://github.com/chef/ohai/pull/714) ([tas50](https://github.com/tas50))

**Fixed bugs:**

- Use escape_glob_dir instead of escape_glob [#747](https://github.com/chef/ohai/pull/747) ([jaym](https://github.com/jaym))
- have a proper dependency on plist [#737](https://github.com/chef/ohai/pull/737) ([thommay](https://github.com/thommay))
- Fix digital ocean ip address detection [#735](https://github.com/chef/ohai/pull/735) ([ctso](https://github.com/ctso))
- Log sigar gem load failures [#731](https://github.com/chef/ohai/pull/731) ([tas50](https://github.com/tas50))
- ipaddress on Linux - default route pointing to unaddressed interface, with route src [#682](https://github.com/chef/ohai/pull/682) ([glennmatthews](https://github.com/glennmatthews))

## Release 8.10.0
* [pr#720](https://github.com/chef/ohai/pull/720) Make Windows driver plugin opt-in via config
* [pr#717](https://github.com/chef/ohai/pull/717) Don't enable packages plugin by default
* [pr#711](https://github.com/chef/ohai/pull/711) Improve EC2 detection for HVM instances when a hint isn't present

## Release 8.9.0
* [**phreakocious**](https://github.com/phreakocious):
  - Collect layer 1 Ethernet information per NIC on Linux hosts
* [**Mark Gibbons**](https://www.github.com/MarkGibbons):
  - Add kernel[:processor] with output of uname -p output
* [**Shahul Khajamohideen**](https://github.com/sh9189)
  - Add packages plugin
* [**electrolinux**](https://github.com/electrolinux)
  - Add "alpine" platform and platform_family
* [**Julien Berard**](https://github.com/jujugrrr)
  - Add instance_id to rackspace plugin
* [**Matt Whiteley**](https://github.com/whiteley)
  - Allow route table override
* [**JM Howard Brown**](https://github.com/jmhbrown)
  - Add tests and queue_depth to block_device
* [pr#672](https://github.com/chef/ohai/pull/672) CPU plugin for Darwin (OS X) now properly reports the number of real CPUs adds "cores" to match the CPU output on Linux
* [pr#674](https://github.com/chef/ohai/pull/674) CPU plugin for FreeBSD now reports "real" and "core" values to match the CPU output on Linux
* [pr#654](https://github.com/chef/ohai/pull/654) Improvements to filesystem and wpar detection on AIX
* [pr#683](https://github.com/chef/ohai/pull/683) Properly detect the init package on older Linux kernels
* [pr#684](https://github.com/chef/ohai/pull/684) Remove non-functional cucumber tests
* [pr#695](https://github.com/chef/ohai/pull/695) Fix detection of mac address on IPv6 only systems
* [pr#703](https://github.com/chef/ohai/pull/703) Enable ChefStyle per RFC 64

## Release 8.8.1
* [pr#677](https://github.com/chef/ohai/pull/677) Remove dependency on mime-types gem
* [pr#662](https://github.com/chef/ohai/pull/662) Skip the VMware plugin if DMI data doesn't indicate we're on a VMware system

## Release 8.8.0
* [**James Flemer, NDP LLC**](https://github.com/jflemer-ndp):
  - Add detection for RHEV (on Linux guests) to virtualization plugin
* [**Shahul Khajamohideen**](https://github.com/sh9189):
  - Fixes Windows :CPU plugin inconsistencies with other platforms: modifies
  `cpu[:total]` to return total number of logical processors, adds `cpu[:cores]`
  to return total number of cores.
* [**clewis**](https://github.com/clewis):
  - Don't constrain the width of `ps` output.
* [**George Gensure**](https://github.com/werkt):
  - Prevents invalid memory access on subsequent failed calls to `proc_state`
  on sigar by throwing exception on returned invalid PID.
* [**Hleb Valoshka**](https://github.com/375gnu):
  - Add support for DragonFly BSD
* [**Austin Ziegler**](https://github.com/halostatue):
  - Bump mime-type dependency to 3.0
* Make collected zfs filesystem properties configurable on solaris2.
* Add kernel bitness detection for AIX
* Fix CPU detection on FreeBSD 10.2+, add collection CPU family and model data.
* Add inode data for filesystems on FreeBSD
* Detect Virtualbox, VMware, and KVM on Windows guests and speed up Ohai runs
* Add a plugin for Virtualbox to provide host / guest version information
* Escape plugin directory path to prevent failures on Windows
* Detect Microsoft Hyper-V Linux/BSD guests, which were previously detected as VirtualPC guests
* Detect Microsoft VirtualPC Linux/BSD guests on additional releases of VirtualPC
* Add KVM, VirtualBox, and Openstack guest detection to BSD platforms and add the node[:virtualization][:systems] syntax

## Release 8.7.0
* [**Shahul Khajamohideen**](https://github.com/sh9189):
  - Add total cores to linux cpu plugin
* Fix behavior when abort called from plug-in (Ohai should exit with error code)

## Release 8.6.0
* [**Phil Dibowitz**](https://github.com/jaymzh):
  - Provide a new and improved filesystem plugin for Linux & Mac (filesystem2), to
  support CentOS7, multiple virtual filesystems, etc.
  - Fix Darwin filesystem plugin on newer MacOSX
* [**Jonathan Amiez**](https://github.com/josqu4red):
  - Linux filesystems plugin report wrong fs-type for logical volumes
* [**involucelate**](https://github.com/involucelate)
  - Fix Windows 2008 hostname truncation #554
* [**Pavel Yudin**](https://github.com/Kasen):
  - Detect Parallels host and guest virtualization
* [**Claire McQuin**](https://github.com/mcquin):
  - Deprecate Ohai::Config in favor of Ohai::Config.ohai.
  - Load a configuration file while running as an application.
* [PR #597](https//github.com/chef/ohai/pull/597):
  - Correct platform, platform\_family and version detection on Cisco's Nexus platforms.
* [**cmluciano**](https://github.com/cmluciano):
  - add vmware plugin
* [**Jean Baptiste Favre**](https://github.com/jbfavre):
  - Detect updated docker cgroup format
* [**Shahul Khajamohideen**](https://github.com/sh9189):
  - Fix memory plugin output on Solaris
  - Add swap space attributes for Solaris memory plugin
  - Add swap space attributes for AIX
  - Add support for SPARC based processors in Solaris cpu plugin
  - Make AIX cpu plugin's output consistent with Solaris cpu plugin
  - Make AIX, Solaris memory output consistent to Linux
* [**Sean Horn**](https://github.com/sean-horn):
  - ec2 plugin should handle binary userdata too
* [**Alexey Karpik**](https://github.com/akarpik):
  - Add support for SoftLayer cloud
* [**MichaelSp**](https://github.com/MichaelSp):
  - return correct ipaddress for openvz guests
* [**Anthony Caiafa**](https://github.com/acaiafa):
  - Only run ifconfig against active interfaces
* [**Shahul Khajamohideen**](https://github.com/sh9189) and [**Sean Escriva**](https://github.com/webframp):
  - Windows Memory plugin
* [**Chris Chambers**](https://github.com/cachamber):
  - Convert Solaris OHAI CPU detection to kstat from psrinfo

## Release 8.5.0

* [PR #548](https://github.com/chef/ohai/pull/548):
  Coerce non-UTF8 strings to UTF8 in output to suppress UTF8 encoding exceptions
* [PR #544](https://github.com/chef/ohai/pull/544)
  add support for Wind River Linux and Cisco's Nexus platforms

## Release 8.4.0

* Correctly skip unwanted DMI information
* Collect DMI information on Solaris/x86

## Release 8.3.0

* [**Jeremy Mauro**](https://github.com/jmauro):
  Removing trailing space and '\r' for windows #474
* [**Tim Smith**](https://github.com/tas50):
  Ensure Gentoo based Linuxen get IP information
* [PR #534](https://github.com/chef/ohai/pull/534)
  Ignore OEM logo on Windows

## Release 8.2.0

* [**Michael Glenney**](https://github.com/Maniacal)
  Remove redundant if statement
* Remove CloudStack support due to GPL licensed library

## Release 8.1.1
* Fix broken DigitalOcean plugin

## Release 8.1.0

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
* [**Paul Czarkowski**](https://github.com/paulczar)
  detect if inside Docker container
* [**Michael Schmidt**](https://github.com/BugRoger)
  OHAI-339 Unable to detect IPAddress on CoreOS/Gentoo
* [**Stafford Brunk**](https://github.com/wingrunr21)
  Digital Ocean ohai/cloud support round
* [**Sten Spans**](https://github.com/sspans)
  Fix network.rb for XenServer Creedence
* [**Shuo Zhang**](https://github.com/zshuo)
  Update Linux plugin cpu.rb and spec_cpu.rb to support S390
* [**Alexey Karpik**](https://github.com/akarpik)
  Fix up incorrect CloudStack metadata
* [**Jeff Goldschrafe**](https://github.com/jgoldschrafe)
  cloud_v2 fails to initialize on GCE hosts without external IP
* [**Ryan Chipman**](https://github.com/rychipman)
  Archlinux Version
* [**Jose Luis Salas**](https://github.com/josacar)
  Add a trailing dot to avoid using search option in resolv.conf
* [**Eric G. Wolfe**](https://github.com/atomic-penguin)
  block_device rotational key
* [**Josh Blancett**](https://github.com/jblancett)
  add extra metadata passed in from hints in knife-linode
* Update mime-types dependency

## Release 8.0.0

* [**sawanoboly**](https://github.com/sawanoboly)
  Retrieve OpenStack-specific metadata.
* [**Olle Lundberg**](https://github.com/lndbrg)
  Add CloudStack support.
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
* Report Suse and OpenSuse separately in the :platform attribute.
* CPU information matching Linux is now available on Darwin.
* ip6address detection failure logging is turned down to :debug.
* fe80:: link-local address is not reported as ip6addresses anymore.
* Private network information is now available as [:rackspace][:private_networks] on Rackspace nodes.
* System init mechanism is now reported at [:init_package] on Linux.
* Define cloud plugin interface (OHAI-542)
* java -version wastes memory (OHAI-550)
* Ohai cannot detect running in an lxc container (OHAI-551)
* Normalize cloud attributes for Azure (OHAI-554)
* Capture FreeBSD osreldate for comparison purposes (OHAI-557)

http://www.chef.io/blog/2014/04/09/release-chef-client-11-12-2/
