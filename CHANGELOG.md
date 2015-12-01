# Change Log

## [8.8.0](https://github.com/chef/ohai/tree/8.8.0) (2015-11-30)
[Full Changelog](https://github.com/chef/ohai/compare/v8.7.0...8.8.0)

**Implemented enhancements:**

- Fix and extend CPU detection on FreeBSD [\#640](https://github.com/chef/ohai/pull/640) ([tas50](https://github.com/tas50))

**Fixed bugs:**

- Invalid pid, name used after sigar fails to throw exception [\#423](https://github.com/chef/ohai/issues/423)
- Tell ps to stop constraining the width of it's output [\#616](https://github.com/chef/ohai/pull/616) ([clewis](https://github.com/clewis))
- Workaround for hyperic/sigar\#48, throw on 0 pid [\#483](https://github.com/chef/ohai/pull/483) ([werkt](https://github.com/werkt))

**Closed issues:**

- -d on Windows doesn't use path with backslash [\#636](https://github.com/chef/ohai/issues/636)
- FreeBSD 10.X not showing DMI data under Virtualbox [\#635](https://github.com/chef/ohai/issues/635)
- ohai filesystem plugin output needs adjustment for solaris11 [\#629](https://github.com/chef/ohai/issues/629)
- KVM/Virtualization Detection [\#621](https://github.com/chef/ohai/issues/621)
- On \*BSD, node\[:command\]\[:ps\] is limited to 79 characters wide [\#615](https://github.com/chef/ohai/issues/615)
- ohai virtualization does not detect docker on rhel 7.1 [\#592](https://github.com/chef/ohai/issues/592)
- Missing memory information for windows systems [\#515](https://github.com/chef/ohai/issues/515)
- ohai doesn't recognize cloud metadata in aws ap-southeast [\#456](https://github.com/chef/ohai/issues/456)

**Merged pull requests:**

- Fix naming of virtualbox spec [\#659](https://github.com/chef/ohai/pull/659) ([tas50](https://github.com/tas50))
- Update changelog for current changes [\#656](https://github.com/chef/ohai/pull/656) ([tas50](https://github.com/tas50))
- Add a plugin for Virtualbox details [\#653](https://github.com/chef/ohai/pull/653) ([tas50](https://github.com/tas50))
- Opscode -\> Chef in docs [\#644](https://github.com/chef/ohai/pull/644) ([tas50](https://github.com/tas50))
- Detect vbox/vmware/kvm on Windows and speed up runs [\#642](https://github.com/chef/ohai/pull/642) ([tas50](https://github.com/tas50))
- Collect inode data on FreeBSD and add filesystem specs [\#641](https://github.com/chef/ohai/pull/641) ([tas50](https://github.com/tas50))
- Add detection for RHEV \(on Linux guests\) to virtualization plugin [\#639](https://github.com/chef/ohai/pull/639) ([jflemer-ndp](https://github.com/jflemer-ndp))
- Provide AIX kernel bittiness [\#638](https://github.com/chef/ohai/pull/638) ([curiositycasualty](https://github.com/curiositycasualty))
- Escape plugin directories for globbing [\#637](https://github.com/chef/ohai/pull/637) ([mcquin](https://github.com/mcquin))
- Update changelog [\#633](https://github.com/chef/ohai/pull/633) ([mcquin](https://github.com/mcquin))
- Add gemspec files to allow bundler to run from the gem [\#632](https://github.com/chef/ohai/pull/632) ([ksubrama](https://github.com/ksubrama))
- Configurable filesystem properties collected for Solaris2.x [\#630](https://github.com/chef/ohai/pull/630) ([mcquin](https://github.com/mcquin))
- Removed chef as development\_dependency in gemspec as it is already li… [\#627](https://github.com/chef/ohai/pull/627) ([tylercloke](https://github.com/tylercloke))
- Initial support for DragonFly BSD [\#626](https://github.com/chef/ohai/pull/626) ([375gnu](https://github.com/375gnu))

## [v8.7.0](https://github.com/chef/ohai/tree/v8.7.0) (2015-10-05)
[Full Changelog](https://github.com/chef/ohai/compare/v8.6.0...v8.7.0)

**Fixed bugs:**

- abort does not abort [\#516](https://github.com/chef/ohai/issues/516)

**Closed issues:**

- wrong CPU count  [\#623](https://github.com/chef/ohai/issues/623)
- uptime plugin hangs/takes forever on Windows [\#619](https://github.com/chef/ohai/issues/619)
- net-dhcp is GPL licensed, revert cloudstack contribution [\#501](https://github.com/chef/ohai/issues/501)

**Merged pull requests:**

- Bump revision to 8.7.0 [\#631](https://github.com/chef/ohai/pull/631) ([jkeiser](https://github.com/jkeiser))
- Fix Windows cpu enumeration, add tests [\#628](https://github.com/chef/ohai/pull/628) ([chefsalim](https://github.com/chefsalim))
- Fix behavior of Ohai plug-in abort [\#625](https://github.com/chef/ohai/pull/625) ([chefsalim](https://github.com/chefsalim))
- Properly detect WPAR networking [\#620](https://github.com/chef/ohai/pull/620) ([curiositycasualty](https://github.com/curiositycasualty))
- Adding support for Wind River Linux 7. [\#618](https://github.com/chef/ohai/pull/618) ([adamleff](https://github.com/adamleff))
- Add total cores to linux cpu plugin [\#612](https://github.com/chef/ohai/pull/612) ([sh9189](https://github.com/sh9189))

## [v8.6.0](https://github.com/chef/ohai/tree/v8.6.0) (2015-09-02)
[Full Changelog](https://github.com/chef/ohai/compare/8.5.1...v8.6.0)

**Implemented enhancements:**

- Make aix, solaris memory output consistent to linux, add spec test for linux memory [\#609](https://github.com/chef/ohai/pull/609) ([sh9189](https://github.com/sh9189))

**Merged pull requests:**

- Plugin configuration [\#613](https://github.com/chef/ohai/pull/613) ([mcquin](https://github.com/mcquin))
- Change windows cpu plugin to be consistent with other plaforms, add spec test [\#611](https://github.com/chef/ohai/pull/611) ([sh9189](https://github.com/sh9189))
- Convert Solaris OHAI CPU detection to kstat from psrinfo [\#610](https://github.com/chef/ohai/pull/610) ([cachamber](https://github.com/cachamber))
- Make AIX cpu plugin's output consistent with Solaris cpu plugin [\#608](https://github.com/chef/ohai/pull/608) ([sh9189](https://github.com/sh9189))
- Windows memory plugin [\#606](https://github.com/chef/ohai/pull/606) ([sh9189](https://github.com/sh9189))
- use bundle rake tasks [\#604](https://github.com/chef/ohai/pull/604) ([thommay](https://github.com/thommay))
- Add swap space attributes for AIX [\#602](https://github.com/chef/ohai/pull/602) ([sh9189](https://github.com/sh9189))
- Add support for sparc based processors in solaris cpu plugin [\#601](https://github.com/chef/ohai/pull/601) ([sh9189](https://github.com/sh9189))
- Only run ifconfig against active interfaces [\#600](https://github.com/chef/ohai/pull/600) ([acaiafa](https://github.com/acaiafa))
- Add swap space attributes for solaris memory plugin [\#599](https://github.com/chef/ohai/pull/599) ([sh9189](https://github.com/sh9189))
- Fix aix memory plugin output [\#598](https://github.com/chef/ohai/pull/598) ([sh9189](https://github.com/sh9189))
- Lcg/cisco refactor [\#597](https://github.com/chef/ohai/pull/597) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix memory plugin output on solaris [\#591](https://github.com/chef/ohai/pull/591) ([sh9189](https://github.com/sh9189))
- add vmware plugin [\#551](https://github.com/chef/ohai/pull/551) ([cmluciano](https://github.com/cmluciano))
- return correct ipaddress for openvz guests \(fixes \#415\) [\#547](https://github.com/chef/ohai/pull/547) ([MichaelSp](https://github.com/MichaelSp))
- ec2 plugin should handle binary userdata too [\#504](https://github.com/chef/ohai/pull/504) ([sean-horn](https://github.com/sean-horn))
- Add support for Softlayer cloud [\#448](https://github.com/chef/ohai/pull/448) ([akarpik](https://github.com/akarpik))

## [8.5.1](https://github.com/chef/ohai/tree/8.5.1) (2015-08-10)
[Full Changelog](https://github.com/chef/ohai/compare/8.5.0...8.5.1)

**Fixed bugs:**

- ohai WARN: unable to detect ipaddress, macaddress [\#397](https://github.com/chef/ohai/issues/397)

**Closed issues:**

- virtualization does not detect centos 7.1 kvm guests running on a centos 7.1 host [\#590](https://github.com/chef/ohai/issues/590)
- Unable to run Ohai::System.all\_plugins within reasonable time on my Windows machine [\#581](https://github.com/chef/ohai/issues/581)
- linux filesystem plugin can't handle CentOS7 bind mounts [\#558](https://github.com/chef/ohai/issues/558)
- Docker changed their cgroups format [\#531](https://github.com/chef/ohai/issues/531)
- cannot encode to UTF-8 \(FFI\_Yajl::EncodeError\) [\#523](https://github.com/chef/ohai/issues/523)
- The kitten must die. [\#514](https://github.com/chef/ohai/issues/514)
- Missing Build badges on the master README.md [\#497](https://github.com/chef/ohai/issues/497)
- Intermittent Build Failures - Travis CI [\#496](https://github.com/chef/ohai/issues/496)

**Merged pull requests:**

- Detect KVM guest from dmidecode [\#594](https://github.com/chef/ohai/pull/594) ([mcquin](https://github.com/mcquin))
- Remove config logging, resolve :auto log-level. [\#593](https://github.com/chef/ohai/pull/593) ([mcquin](https://github.com/mcquin))
- Update Ohai::VERSION [\#589](https://github.com/chef/ohai/pull/589) ([mcquin](https://github.com/mcquin))
- Ohai::Application loads configuration file [\#588](https://github.com/chef/ohai/pull/588) ([mcquin](https://github.com/mcquin))
- Grab alpha release of chef-config gem [\#587](https://github.com/chef/ohai/pull/587) ([mcquin](https://github.com/mcquin))
- Update the chef-config dependency version to be compatible with chef [\#586](https://github.com/chef/ohai/pull/586) ([mcquin](https://github.com/mcquin))
- Correct platform, platform\_family and version detection on Cisco's Nexus platforms. [\#585](https://github.com/chef/ohai/pull/585) ([mattray](https://github.com/mattray))
- rspec\_junit\_formatter has been released with RSpec3 support [\#584](https://github.com/chef/ohai/pull/584) ([juliandunn](https://github.com/juliandunn))
- remove "warning: already initialized constant ETHERNET\_ENCAPS" [\#583](https://github.com/chef/ohai/pull/583) ([juliandunn](https://github.com/juliandunn))
- better KVM virtualization detection [\#578](https://github.com/chef/ohai/pull/578) ([davide125](https://github.com/davide125))
- Deprecate Ohai::Config in favor of Ohai::Config.ohai [\#574](https://github.com/chef/ohai/pull/574) ([mcquin](https://github.com/mcquin))
- filesystem2 bugfix [\#573](https://github.com/chef/ohai/pull/573) ([jaymzh](https://github.com/jaymzh))
- \[filesystem2\] Minor linux bug [\#571](https://github.com/chef/ohai/pull/571) ([jaymzh](https://github.com/jaymzh))
- Move filesystem-related specs to use `let` [\#568](https://github.com/chef/ohai/pull/568) ([jaymzh](https://github.com/jaymzh))
- Fix my\_mountpoint view in filesystem2; add tests [\#567](https://github.com/chef/ohai/pull/567) ([jaymzh](https://github.com/jaymzh))
- Forward port fix for \#469 [\#566](https://github.com/chef/ohai/pull/566) ([jaymzh](https://github.com/jaymzh))
- Fix darwin filesystem plugin on newer OSX. [\#565](https://github.com/chef/ohai/pull/565) ([jaymzh](https://github.com/jaymzh))
- Port new filesystem2 plugin to darwin. [\#564](https://github.com/chef/ohai/pull/564) ([jaymzh](https://github.com/jaymzh))
- Fix changelog from merge on PR\#559 [\#563](https://github.com/chef/ohai/pull/563) ([jaymzh](https://github.com/jaymzh))
- Provide a new and improved linux filesystem plugin [\#559](https://github.com/chef/ohai/pull/559) ([jaymzh](https://github.com/jaymzh))
- The detection of Parallels virtualization added. [\#557](https://github.com/chef/ohai/pull/557) ([Kasen](https://github.com/Kasen))
- Fix windows 2008 hostname truncation  [\#554](https://github.com/chef/ohai/pull/554) ([involucelate](https://github.com/involucelate))
- Change lsblk usage in linux filesystem plugin [\#550](https://github.com/chef/ohai/pull/550) ([josqu4red](https://github.com/josqu4red))
- fixes \#545 \(IPv6 bug in detecting link-local addresses\) [\#546](https://github.com/chef/ohai/pull/546) ([rmoriz](https://github.com/rmoriz))

## [8.5.0](https://github.com/chef/ohai/tree/8.5.0) (2015-06-23)
[Full Changelog](https://github.com/chef/ohai/compare/8.4.0...8.5.0)

**Fixed bugs:**

- Linux filesystems plugin report wrong fs-type for logical volumes [\#469](https://github.com/chef/ohai/issues/469)
- ohai ipaddress returns loopback address on servers virtualized through OpenVZ [\#415](https://github.com/chef/ohai/issues/415)

**Closed issues:**

- centos 7 platform not detected on master [\#560](https://github.com/chef/ohai/issues/560)
- no macaddress on solaris [\#549](https://github.com/chef/ohai/issues/549)
- IPv6 bug in detecting link-local addresses [\#545](https://github.com/chef/ohai/issues/545)
- Ohai collects a \*lot\* of data if you have an OEM Logo set on Windows [\#533](https://github.com/chef/ohai/issues/533)

**Merged pull requests:**

- Release Ohai 8.5.0 [\#562](https://github.com/chef/ohai/pull/562) ([jaym](https://github.com/jaym))
- El7 platform \(\#560\) [\#561](https://github.com/chef/ohai/pull/561) ([danielsdeleo](https://github.com/danielsdeleo))
- drop ruby 2.0 on travis in line with chef [\#555](https://github.com/chef/ohai/pull/555) ([thommay](https://github.com/thommay))
- Update list of solaris ethernet drivers [\#553](https://github.com/chef/ohai/pull/553) ([thommay](https://github.com/thommay))
- force ohai output to UTF-8 [\#548](https://github.com/chef/ohai/pull/548) ([lamont-granquist](https://github.com/lamont-granquist))
- add support for Wind River Linux and Cisco's Nexus platforms [\#544](https://github.com/chef/ohai/pull/544) ([mattray](https://github.com/mattray))

## [8.4.0](https://github.com/chef/ohai/tree/8.4.0) (2015-05-22)
[Full Changelog](https://github.com/chef/ohai/compare/8.3.0...8.4.0)

**Closed issues:**

- no dmi information on centos [\#542](https://github.com/chef/ohai/issues/542)
- no dmi information on solaris2 [\#539](https://github.com/chef/ohai/issues/539)
- dmi plugin captures data for skipped handles [\#538](https://github.com/chef/ohai/issues/538)
- dmi processor all\_records contains system slot information [\#500](https://github.com/chef/ohai/issues/500)
- Linux vs Windows filesystem plugin inconsistencies [\#481](https://github.com/chef/ohai/issues/481)

**Merged pull requests:**

- prep for 8.4.0 [\#543](https://github.com/chef/ohai/pull/543) ([thommay](https://github.com/thommay))
- make DMI work on solaris [\#541](https://github.com/chef/ohai/pull/541) ([thommay](https://github.com/thommay))
- Correctly ignore unwanted DMI data [\#540](https://github.com/chef/ohai/pull/540) ([thommay](https://github.com/thommay))
- OEM logo is large and completely useless. Remove [\#534](https://github.com/chef/ohai/pull/534) ([jaym](https://github.com/jaym))

## [8.3.0](https://github.com/chef/ohai/tree/8.3.0) (2015-04-27)
[Full Changelog](https://github.com/chef/ohai/compare/8.3.0.rc.0...8.3.0)

**Fixed bugs:**

- ohai detects wrong ipv6 address [\#380](https://github.com/chef/ohai/issues/380)

**Merged pull requests:**

- 8.3.0 [\#528](https://github.com/chef/ohai/pull/528) ([thommay](https://github.com/thommay))
- Work correctly when IPv6 is disabled on Linux [\#527](https://github.com/chef/ohai/pull/527) ([thommay](https://github.com/thommay))
- Move windows drivers out of kernel [\#526](https://github.com/chef/ohai/pull/526) ([jaym](https://github.com/jaym))
- Update README.md [\#521](https://github.com/chef/ohai/pull/521) ([jjasghar](https://github.com/jjasghar))

## [8.3.0.rc.0](https://github.com/chef/ohai/tree/8.3.0.rc.0) (2015-04-21)
[Full Changelog](https://github.com/chef/ohai/compare/8.2.0...8.3.0.rc.0)

**Merged pull requests:**

- Update ip binary detection logic to work on Gentoo/CoreOS [\#510](https://github.com/chef/ohai/pull/510) ([tas50](https://github.com/tas50))

## [8.2.0](https://github.com/chef/ohai/tree/8.2.0) (2015-03-25)
[Full Changelog](https://github.com/chef/ohai/compare/8.1.1...8.2.0)

**Closed issues:**

- Ohai 8.1 fails with error in Digital Ocean plugin [\#487](https://github.com/chef/ohai/issues/487)

**Merged pull requests:**

- Ohai 8.2.0 [\#509](https://github.com/chef/ohai/pull/509) ([jaym](https://github.com/jaym))
- Reverting \#354 because change bring in GPLv3 dependency [\#506](https://github.com/chef/ohai/pull/506) ([jaym](https://github.com/jaym))
- remove 1.9.3 from travis [\#505](https://github.com/chef/ohai/pull/505) ([lamont-granquist](https://github.com/lamont-granquist))
- bumping ffi-yajl to pick up 2.x [\#502](https://github.com/chef/ohai/pull/502) ([lamont-granquist](https://github.com/lamont-granquist))
- Add travis badge for build status to readme [\#495](https://github.com/chef/ohai/pull/495) ([cmluciano](https://github.com/cmluciano))
- Try to use travis container thingys [\#490](https://github.com/chef/ohai/pull/490) ([jaym](https://github.com/jaym))

## [8.1.1](https://github.com/chef/ohai/tree/8.1.1) (2015-02-17)
[Full Changelog](https://github.com/chef/ohai/compare/8.1.0...8.1.1)

**Fixed bugs:**

- cloud\_v2 fails to initialize on GCE hosts without external IP [\#432](https://github.com/chef/ohai/issues/432)

**Merged pull requests:**

- Ohai 8.1 is broken [\#489](https://github.com/chef/ohai/pull/489) ([jaym](https://github.com/jaym))

## [8.1.0](https://github.com/chef/ohai/tree/8.1.0) (2015-02-17)
[Full Changelog](https://github.com/chef/ohai/compare/7.4.1...8.1.0)

**Implemented enhancements:**

- Zend Engine and Zend OPcache versions should be exposed in PHP plugin [\#440](https://github.com/chef/ohai/issues/440)
- openstack kvm guest not detected by virtualization plugin [\#425](https://github.com/chef/ohai/issues/425)

**Fixed bugs:**

- "ohai -d" doesn't work in windows [\#435](https://github.com/chef/ohai/issues/435)
- Platform version is missing on archlinux platform [\#405](https://github.com/chef/ohai/issues/405)
- Ohai detects server inside gce under specific conditions [\#399](https://github.com/chef/ohai/issues/399)
- Ohai should use lsblk instead of \(or in addition to\) blkid [\#351](https://github.com/chef/ohai/issues/351)
- DMI plugin stripping issue [\#470](https://github.com/chef/ohai/issues/470)

**Closed issues:**

- ruby config detection no longer works in ruby version 2.2 [\#453](https://github.com/chef/ohai/issues/453)

**Merged pull requests:**

- Bump version to 8.1.0 [\#486](https://github.com/chef/ohai/pull/486) ([jaym](https://github.com/jaym))
- Jdm/merge into 8 stable [\#485](https://github.com/chef/ohai/pull/485) ([jaym](https://github.com/jaym))
- Jdm/merge into master [\#484](https://github.com/chef/ohai/pull/484) ([jaym](https://github.com/jaym))
- Lcg/merges2 [\#472](https://github.com/chef/ohai/pull/472) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/merges [\#471](https://github.com/chef/ohai/pull/471) ([lamont-granquist](https://github.com/lamont-granquist))
- Added appveyor.yml [\#467](https://github.com/chef/ohai/pull/467) ([jaym](https://github.com/jaym))
- Added appveyor.yml [\#465](https://github.com/chef/ohai/pull/465) ([jaym](https://github.com/jaym))
- Added appveyor.yml [\#464](https://github.com/chef/ohai/pull/464) ([jaym](https://github.com/jaym))

## [7.4.1](https://github.com/chef/ohai/tree/7.4.1) (2015-01-14)
[Full Changelog](https://github.com/chef/ohai/compare/8.0.1...7.4.1)

**Closed issues:**

- FQDN Incorrectly Determined to be "localhost" on OS X [\#457](https://github.com/chef/ohai/issues/457)
- sudo ohai reports root as current\_user instead of the value of SUDO\_USER [\#451](https://github.com/chef/ohai/issues/451)
- Segfault in Ohai when trying to run chef-client via the chef gem [\#445](https://github.com/chef/ohai/issues/445)

**Merged pull requests:**

- Bump version to 7.4.1 [\#462](https://github.com/chef/ohai/pull/462) ([jaym](https://github.com/jaym))
- Jdm/json backport [\#461](https://github.com/chef/ohai/pull/461) ([jaym](https://github.com/jaym))

## [8.0.1](https://github.com/chef/ohai/tree/8.0.1) (2014-12-04)
[Full Changelog](https://github.com/chef/ohai/compare/8.0.0...8.0.1)

**Merged pull requests:**

- add require resolv to work around missing constant issue in cvt testers [\#443](https://github.com/chef/ohai/pull/443) ([lamont-granquist](https://github.com/lamont-granquist))
- Always use posix output [\#446](https://github.com/chef/ohai/pull/446) ([jaymzh](https://github.com/jaymzh))

## [8.0.0](https://github.com/chef/ohai/tree/8.0.0) (2014-12-03)
[Full Changelog](https://github.com/chef/ohai/compare/7.6.0...8.0.0)

## [7.6.0](https://github.com/chef/ohai/tree/7.6.0) (2014-12-01)
[Full Changelog](https://github.com/chef/ohai/compare/7.6.0.rc.1...7.6.0)

**Merged pull requests:**

- Update to RSpec 3 syntax [\#438](https://github.com/chef/ohai/pull/438) ([mcquin](https://github.com/mcquin))

## [7.6.0.rc.1](https://github.com/chef/ohai/tree/7.6.0.rc.1) (2014-10-27)
[Full Changelog](https://github.com/chef/ohai/compare/7.6.0.rc.0...7.6.0.rc.1)

**Implemented enhancements:**

- Need new attribute target\_architecture and plugin to set it [\#436](https://github.com/chef/ohai/issues/436)
- Ohai supports Raspbian but not Pidora [\#424](https://github.com/chef/ohai/issues/424)

**Fixed bugs:**

- Look for any number of spaces between the VxID and the value [\#411](https://github.com/chef/ohai/pull/411) ([nshahzad](https://github.com/nshahzad))
- Eucalyptus metadata server, presume 'latest' API version on 404 [\#368](https://github.com/chef/ohai/pull/368) ([btm](https://github.com/btm))
- \[OHAI-518\] remove \*.static.cloud-ips.com [\#345](https://github.com/chef/ohai/pull/345) ([squaresurf](https://github.com/squaresurf))

**Closed issues:**

- No CHANGELOG.md updates for 7.4.0 [\#434](https://github.com/chef/ohai/issues/434)
- Undefined Method to\_json for 22:IPAddress::Prefix32 [\#426](https://github.com/chef/ohai/issues/426)
- Ohai does not see EC2 VPC instances as EC2 [\#409](https://github.com/chef/ohai/issues/409)
- How do include just cpu plugin [\#406](https://github.com/chef/ohai/issues/406)
- AIX: always use "netstat -rn" rather than "route" to get network information [\#396](https://github.com/chef/ohai/issues/396)
- Ohai doesn’t differentiate between EC2 node being EBS- vs. instance-backed [\#381](https://github.com/chef/ohai/issues/381)

**Merged pull requests:**

- 7.6.0 Release Merge [\#437](https://github.com/chef/ohai/pull/437) ([sersut](https://github.com/sersut))
- Update contribution info for community merges. [\#430](https://github.com/chef/ohai/pull/430) ([mcquin](https://github.com/mcquin))
- Look for any number of spaces between the VxID and the value \[\#411\] [\#429](https://github.com/chef/ohai/pull/429) ([mcquin](https://github.com/mcquin))
- Update platform.rb [\#427](https://github.com/chef/ohai/pull/427) ([barnabear](https://github.com/barnabear))
- Ensure CPU total is an integer on FreeBSD [\#421](https://github.com/chef/ohai/pull/421) ([schisamo](https://github.com/schisamo))
- \[AIX-53\] fix incorrect uptime [\#419](https://github.com/chef/ohai/pull/419) ([kaustubh-d](https://github.com/kaustubh-d))
- \[AIX-48\] fix network plugin to use netstat instead of route, which is privileged [\#418](https://github.com/chef/ohai/pull/418) ([kaustubh-d](https://github.com/kaustubh-d))
- Fix java version parsing regex [\#417](https://github.com/chef/ohai/pull/417) ([kaustubh-d](https://github.com/kaustubh-d))
- Update CHANGELOG.md [\#413](https://github.com/chef/ohai/pull/413) ([glensc](https://github.com/glensc))
- mixlib-shellout gem released [\#410](https://github.com/chef/ohai/pull/410) ([lamont-granquist](https://github.com/lamont-granquist))
- this blocks chef-solo for 10 minutes [\#379](https://github.com/chef/ohai/pull/379) ([carck](https://github.com/carck))

## [7.6.0.rc.0](https://github.com/chef/ohai/tree/7.6.0.rc.0) (2014-09-10)
[Full Changelog](https://github.com/chef/ohai/compare/7.4.0...7.6.0.rc.0)

**Merged pull requests:**

- bump mixlib-shellout + misc gemspec [\#408](https://github.com/chef/ohai/pull/408) ([lamont-granquist](https://github.com/lamont-granquist))
- Add rake to the bundle to be able to run 'bundle exec rake gem' in build. [\#407](https://github.com/chef/ohai/pull/407) ([sersut](https://github.com/sersut))

## [7.4.0](https://github.com/chef/ohai/tree/7.4.0) (2014-09-06)
[Full Changelog](https://github.com/chef/ohai/compare/6.24.2...7.4.0)

**Fixed bugs:**

- Encapsulate print command in function [\#322](https://github.com/chef/ohai/pull/322) ([lamont-granquist](https://github.com/lamont-granquist))

**Merged pull requests:**

- fix busted rake install [\#404](https://github.com/chef/ohai/pull/404) ([lamont-granquist](https://github.com/lamont-granquist))
- Ignore passwd plugin on Windows [\#403](https://github.com/chef/ohai/pull/403) ([btm](https://github.com/btm))
- Update CHANGELOG for the last two releases [\#402](https://github.com/chef/ohai/pull/402) ([btm](https://github.com/btm))
- remove ffi\_yajl monkeypatching [\#398](https://github.com/chef/ohai/pull/398) ([lamont-granquist](https://github.com/lamont-granquist))
- Docs for last commit [\#394](https://github.com/chef/ohai/pull/394) ([jaymzh](https://github.com/jaymzh))

## [6.24.2](https://github.com/chef/ohai/tree/6.24.2) (2014-08-21)
[Full Changelog](https://github.com/chef/ohai/compare/6.24.0...6.24.2)

**Merged pull requests:**

- \[Ohai 7\] Fix lsblk calls [\#393](https://github.com/chef/ohai/pull/393) ([jaymzh](https://github.com/jaymzh))
- \[Ohai 6\] Fix lsblk calls [\#392](https://github.com/chef/ohai/pull/392) ([jaymzh](https://github.com/jaymzh))

## [6.24.0](https://github.com/chef/ohai/tree/6.24.0) (2014-08-19)
[Full Changelog](https://github.com/chef/ohai/compare/7.2.4...6.24.0)

## [7.2.4](https://github.com/chef/ohai/tree/7.2.4) (2014-08-18)
[Full Changelog](https://github.com/chef/ohai/compare/7.2.2...7.2.4)

**Closed issues:**

- linux::network plugin doesn't handle ECMP routes [\#388](https://github.com/chef/ohai/issues/388)

**Merged pull requests:**

- Merge pull request \#390 from jaymzh/7-ecmp-routes [\#391](https://github.com/chef/ohai/pull/391) ([sersut](https://github.com/sersut))
- \[Ohai 7\] Add support for ECMP routes to linux::network [\#390](https://github.com/chef/ohai/pull/390) ([jaymzh](https://github.com/jaymzh))
- \[Ohai 6\] Add support for ECMP routes to linux::network [\#389](https://github.com/chef/ohai/pull/389) ([jaymzh](https://github.com/jaymzh))
- Fix README errors \(grammar, links, formatting\) [\#387](https://github.com/chef/ohai/pull/387) ([juliandunn](https://github.com/juliandunn))
- getlogin\(\) often lies, especially when run under "su" [\#386](https://github.com/chef/ohai/pull/386) ([juliandunn](https://github.com/juliandunn))

## [7.2.2](https://github.com/chef/ohai/tree/7.2.2) (2014-08-15)
[Full Changelog](https://github.com/chef/ohai/compare/7.2.0...7.2.2)

**Implemented enhancements:**

- add virtualization plugin to AIX to detect LPARs and WPARs [\#362](https://github.com/chef/ohai/issues/362)
- Parallels cloud server platform support. [\#369](https://github.com/chef/ohai/pull/369) ([Kasen](https://github.com/Kasen))
- Go plugin [\#366](https://github.com/chef/ohai/pull/366) ([btm](https://github.com/btm))
- Retreive OpenStack specific metadata [\#352](https://github.com/chef/ohai/pull/352) ([sawanoboly](https://github.com/sawanoboly))

**Fixed bugs:**

- AIX: getting unable to detect ipaddress and macaddress from ohai [\#360](https://github.com/chef/ohai/issues/360)
- Match zpool output for omnios 151006 [\#367](https://github.com/chef/ohai/pull/367) ([nhuff](https://github.com/nhuff))

**Closed issues:**

- Segmentation fault when using Ohai 7.2 with Chef 10.22 [\#383](https://github.com/chef/ohai/issues/383)

**Merged pull requests:**

- Fix node\['hostname'\] on systems with only a bare hostname. [\#385](https://github.com/chef/ohai/pull/385) ([juliandunn](https://github.com/juliandunn))
- Collect kernel modules for AIX [\#384](https://github.com/chef/ohai/pull/384) ([juliandunn](https://github.com/juliandunn))
- Ohai Powershell plugin [\#378](https://github.com/chef/ohai/pull/378) ([jaym](https://github.com/jaym))
- Add virtualization plugin for AIX to detect LPARs and WPARs. Fixes \#362. [\#377](https://github.com/chef/ohai/pull/377) ([juliandunn](https://github.com/juliandunn))
- Fix reading /proc/mounts harder [\#376](https://github.com/chef/ohai/pull/376) ([jaymzh](https://github.com/jaymzh))
- Fix reading /proc/mounts harder [\#375](https://github.com/chef/ohai/pull/375) ([jaymzh](https://github.com/jaymzh))
- Revert "Fix Linux::Filesystem reading of /proc/mounts" [\#374](https://github.com/chef/ohai/pull/374) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix Linux::Filesystem reading of /proc/mounts [\#373](https://github.com/chef/ohai/pull/373) ([jaymzh](https://github.com/jaymzh))
- Fix linux::filesystem reading of /proc/mounts [\#372](https://github.com/chef/ohai/pull/372) ([jaymzh](https://github.com/jaymzh))
- Fix failures on Aix [\#371](https://github.com/chef/ohai/pull/371) ([kaustubh-d](https://github.com/kaustubh-d))
- Remove newlines in CPU strings on Darwin [\#365](https://github.com/chef/ohai/pull/365) ([tas50](https://github.com/tas50))
- Cloudstack support [\#354](https://github.com/chef/ohai/pull/354) ([lndbrg](https://github.com/lndbrg))

## [7.2.0](https://github.com/chef/ohai/tree/7.2.0) (2014-07-23)
[Full Changelog](https://github.com/chef/ohai/compare/6.24.0.rc.0...7.2.0)

**Merged pull requests:**

- \[ci\] bundle install into system gems [\#370](https://github.com/chef/ohai/pull/370) ([schisamo](https://github.com/schisamo))

## [6.24.0.rc.0](https://github.com/chef/ohai/tree/6.24.0.rc.0) (2014-07-17)
[Full Changelog](https://github.com/chef/ohai/compare/7.2.0.rc.2...6.24.0.rc.0)

**Fixed bugs:**

- fix newlines in platform/platform\_family [\#361](https://github.com/chef/ohai/pull/361) ([lamont-granquist](https://github.com/lamont-granquist))

**Closed issues:**

- undefined method `to\_json' for 24:IPAddress::Prefix32 \(NoMethodError\) [\#356](https://github.com/chef/ohai/issues/356)

**Merged pull requests:**

- \[ohai 7\] Linux::filesystems should prefer lsblk to blkid when available [\#363](https://github.com/chef/ohai/pull/363) ([jaymzh](https://github.com/jaymzh))
- pin rspec version to 2.14 [\#359](https://github.com/chef/ohai/pull/359) ([mcquin](https://github.com/mcquin))
- add Object\#to\_json monkeypatches [\#358](https://github.com/chef/ohai/pull/358) ([lamont-granquist](https://github.com/lamont-granquist))
- Revert "pin rspec version to 2.14" [\#357](https://github.com/chef/ohai/pull/357) ([mcquin](https://github.com/mcquin))
- pin rspec version to 2.14 [\#355](https://github.com/chef/ohai/pull/355) ([mcquin](https://github.com/mcquin))

## [7.2.0.rc.2](https://github.com/chef/ohai/tree/7.2.0.rc.2) (2014-07-02)
[Full Changelog](https://github.com/chef/ohai/compare/7.2.0.rc.1...7.2.0.rc.2)

**Implemented enhancements:**

- Add support for ip version ss131122 [\#346](https://github.com/chef/ohai/pull/346) ([cread](https://github.com/cread))

**Fixed bugs:**

- \[ohai 6\] Linux::filesystems should prefer lsblk to blkid when available [\#353](https://github.com/chef/ohai/pull/353) ([jaymzh](https://github.com/jaymzh))
- Save IAM security credentials only if hint is present [\#350](https://github.com/chef/ohai/pull/350) ([mcquin](https://github.com/mcquin))

## [7.2.0.rc.1](https://github.com/chef/ohai/tree/7.2.0.rc.1) (2014-06-27)
[Full Changelog](https://github.com/chef/ohai/compare/7.2.0.rc.0...7.2.0.rc.1)

**Merged pull requests:**

- Bump ffi version to something compatible with chef. [\#349](https://github.com/chef/ohai/pull/349) ([sersut](https://github.com/sersut))

## [7.2.0.rc.0](https://github.com/chef/ohai/tree/7.2.0.rc.0) (2014-06-27)
[Full Changelog](https://github.com/chef/ohai/compare/7.2.0.alpha.0...7.2.0.rc.0)

**Implemented enhancements:**

- Added inodes testing [\#238](https://github.com/chef/ohai/pull/238) ([jasonpgignac](https://github.com/jasonpgignac))

**Fixed bugs:**

- OHAI-587: Rackspace plugin rescues Errno::ENOENT if xenstore-\* utils are not found [\#342](https://github.com/chef/ohai/pull/342) ([jcsalterego](https://github.com/jcsalterego))
- OHAI-541: return a response even when ec2 metadata is 404 [\#332](https://github.com/chef/ohai/pull/332) ([miketheman](https://github.com/miketheman))
- OHAI-431: provide basic memory information for Mac OS X [\#331](https://github.com/chef/ohai/pull/331) ([patcoll](https://github.com/patcoll))
- do not warn for missing gateway IPs [\#290](https://github.com/chef/ohai/pull/290) ([hollow](https://github.com/hollow))
- \[OHAI-458\] Include Joyent SmartOS specific attributes in Ohai [\#133](https://github.com/chef/ohai/pull/133) ([sawanoboly](https://github.com/sawanoboly))

**Merged pull requests:**

- Merge master into 7-stable for 7.2.0 release. [\#348](https://github.com/chef/ohai/pull/348) ([sersut](https://github.com/sersut))
- replace ruby-yajl with ffi-yajl gem [\#344](https://github.com/chef/ohai/pull/344) ([lamont-granquist](https://github.com/lamont-granquist))
- OHAI-491: Implement root\_group for Windows  [\#341](https://github.com/chef/ohai/pull/341) ([adamedx](https://github.com/adamedx))
- Temporarily use junit formatter from github for rspec 3 compat [\#340](https://github.com/chef/ohai/pull/340) ([danielsdeleo](https://github.com/danielsdeleo))
- Update tests for RSpec 3 [\#339](https://github.com/chef/ohai/pull/339) ([danielsdeleo](https://github.com/danielsdeleo))
- Only execute tests with elevated privileges [\#338](https://github.com/chef/ohai/pull/338) ([schisamo](https://github.com/schisamo))
- \[OHAI-584\] Update systemu to 2.6.4 for Ruby 2.1.x optimization [\#337](https://github.com/chef/ohai/pull/337) ([juliandunn](https://github.com/juliandunn))

## [7.2.0.alpha.0](https://github.com/chef/ohai/tree/7.2.0.alpha.0) (2014-05-30)
[Full Changelog](https://github.com/chef/ohai/compare/7.0.4...7.2.0.alpha.0)

**Fixed bugs:**

- Replace ruby-wmi dependency with wmi-lite gem to address Ruby 2.0 faults [\#335](https://github.com/chef/ohai/pull/335) ([adamedx](https://github.com/adamedx))

**Closed issues:**

- ec2.rb fails for vpc instances [\#6](https://github.com/chef/ohai/issues/6)
- Fails on OSX with fink-installed hostname [\#5](https://github.com/chef/ohai/issues/5)
- Fails on OSX with fink-installed hostname [\#4](https://github.com/chef/ohai/issues/4)
- doesn't install in windows [\#3](https://github.com/chef/ohai/issues/3)
- Error in Ruby 1.9.1 [\#2](https://github.com/chef/ohai/issues/2)

**Merged pull requests:**

- Contribution info for OHAI-561. [\#334](https://github.com/chef/ohai/pull/334) ([sersut](https://github.com/sersut))
- Convert README to md and update dev instructions [\#329](https://github.com/chef/ohai/pull/329) ([danielsdeleo](https://github.com/danielsdeleo))
- FW port :disabled\_plugin check to the master [\#327](https://github.com/chef/ohai/pull/327) ([sersut](https://github.com/sersut))
- \[\#OHAI-561\] Ignore users if we've already seen them [\#303](https://github.com/chef/ohai/pull/303) ([swalberg](https://github.com/swalberg))
- Update README.doc to fix spelling error [\#88](https://github.com/chef/ohai/pull/88) ([dkullmann](https://github.com/dkullmann))
- typo [\#63](https://github.com/chef/ohai/pull/63) ([Erkan-Yilmaz](https://github.com/Erkan-Yilmaz))

## [7.0.4](https://github.com/chef/ohai/tree/7.0.4) (2014-04-30)
[Full Changelog](https://github.com/chef/ohai/compare/7.0.4.rc.0...7.0.4)

**Merged pull requests:**

- Move :disabled\_plugin check for plugins to running time of the plugins [\#326](https://github.com/chef/ohai/pull/326) ([sersut](https://github.com/sersut))

## [7.0.4.rc.0](https://github.com/chef/ohai/tree/7.0.4.rc.0) (2014-04-24)
[Full Changelog](https://github.com/chef/ohai/compare/7.0.2...7.0.4.rc.0)

**Merged pull requests:**

- Merge for 7.0.4.rc.0 [\#321](https://github.com/chef/ohai/pull/321) ([adamedx](https://github.com/adamedx))
- name returns given plugin name [\#314](https://github.com/chef/ohai/pull/314) ([mcquin](https://github.com/mcquin))

## [7.0.2](https://github.com/chef/ohai/tree/7.0.2) (2014-04-09)
[Full Changelog](https://github.com/chef/ohai/compare/6.22.0...7.0.2)

**Merged pull requests:**

- Skip v7 plugins when refreshing a v6 plugin [\#312](https://github.com/chef/ohai/pull/312) ([danielsdeleo](https://github.com/danielsdeleo))

## [6.22.0](https://github.com/chef/ohai/tree/6.22.0) (2014-04-08)
[Full Changelog](https://github.com/chef/ohai/compare/7.0.0...6.22.0)

## [7.0.0](https://github.com/chef/ohai/tree/7.0.0) (2014-04-08)
[Full Changelog](https://github.com/chef/ohai/compare/7.0.0.rc.3...7.0.0)

## [7.0.0.rc.3](https://github.com/chef/ohai/tree/7.0.0.rc.3) (2014-04-04)
[Full Changelog](https://github.com/chef/ohai/compare/7.0.0.rc.2...7.0.0.rc.3)

**Merged pull requests:**

- Merge OHAI-551 latest + specs to 7-stable [\#311](https://github.com/chef/ohai/pull/311) ([adamedx](https://github.com/adamedx))
- Merge OHAI-551 latest + specs [\#310](https://github.com/chef/ohai/pull/310) ([adamedx](https://github.com/adamedx))
- Use a timeout when running 'df' and 'mount' [\#308](https://github.com/chef/ohai/pull/308) ([jaymzh](https://github.com/jaymzh))

## [7.0.0.rc.2](https://github.com/chef/ohai/tree/7.0.0.rc.2) (2014-03-31)
[Full Changelog](https://github.com/chef/ohai/compare/6.22.0.rc.0...7.0.0.rc.2)

**Merged pull requests:**

- Merge OHAI-542, OHAI-550, OHAI-551, OHAI-554, OHAI-557 into 7-stable [\#306](https://github.com/chef/ohai/pull/306) ([adamedx](https://github.com/adamedx))
- Merge OHAI-542, OHAI-550, OHAI-551, OHAI-554, OHAI-557 [\#305](https://github.com/chef/ohai/pull/305) ([adamedx](https://github.com/adamedx))

## [6.22.0.rc.0](https://github.com/chef/ohai/tree/6.22.0.rc.0) (2014-03-31)
[Full Changelog](https://github.com/chef/ohai/compare/7.0.0.rc.1...6.22.0.rc.0)

## [7.0.0.rc.1](https://github.com/chef/ohai/tree/7.0.0.rc.1) (2014-03-30)
[Full Changelog](https://github.com/chef/ohai/compare/7.0.0.rc.0...7.0.0.rc.1)

**Merged pull requests:**

- Rake ruby18 fix [\#304](https://github.com/chef/ohai/pull/304) ([danielsdeleo](https://github.com/danielsdeleo))
- OHAI-420: Add support for determining which package is running as init [\#301](https://github.com/chef/ohai/pull/301) ([sersut](https://github.com/sersut))
- CC-55: Contribution information for ohai merges. [\#300](https://github.com/chef/ohai/pull/300) ([sersut](https://github.com/sersut))
- OHAI-339: platform "suse" confuses openSUSE and SUSE Linux Enterprise [\#299](https://github.com/chef/ohai/pull/299) ([sersut](https://github.com/sersut))
- Fix `hostname --fqdn` stupidity on linux -- ohai6 [\#296](https://github.com/chef/ohai/pull/296) ([jaymzh](https://github.com/jaymzh))
- Handle `hostname --fqdn` stupidity [\#294](https://github.com/chef/ohai/pull/294) ([jaymzh](https://github.com/jaymzh))
- New policy files for OHAI. [\#292](https://github.com/chef/ohai/pull/292) ([sersut](https://github.com/sersut))
- rackspace private network discovery [\#284](https://github.com/chef/ohai/pull/284) ([paulczar](https://github.com/paulczar))
- \[OHAI-467\] Prevents fe80:: link-local address from becoming ip6address [\#244](https://github.com/chef/ohai/pull/244) ([mpasternacki](https://github.com/mpasternacki))
- \[OHAI-536\] Turn down ip6address logging to debug [\#234](https://github.com/chef/ohai/pull/234) ([juliandunn](https://github.com/juliandunn))
- \[OHAI-497\] Add additional cpu information to darwin, matching what we gather on linux [\#233](https://github.com/chef/ohai/pull/233) ([tas50](https://github.com/tas50))

## [7.0.0.rc.0](https://github.com/chef/ohai/tree/7.0.0.rc.0) (2014-01-20)
[Full Changelog](https://github.com/chef/ohai/compare/6.20.0...7.0.0.rc.0)

**Merged pull requests:**

- OC-11083 MS C compiler plugin regression -- trailing return character removal [\#282](https://github.com/chef/ohai/pull/282) ([adamedx](https://github.com/adamedx))
- Fixes from running ohai-verifier on windows. [\#281](https://github.com/chef/ohai/pull/281) ([sersut](https://github.com/sersut))
- OHAI-525: reverting part of OHAI-525 [\#280](https://github.com/chef/ohai/pull/280) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix OpenStack plugin for v7 changes, add tests [\#279](https://github.com/chef/ohai/pull/279) ([danielsdeleo](https://github.com/danielsdeleo))
- OHAI-546: cannot print specified attributes on the command line  [\#278](https://github.com/chef/ohai/pull/278) ([sersut](https://github.com/sersut))
- capitalization derp [\#277](https://github.com/chef/ohai/pull/277) ([lamont-granquist](https://github.com/lamont-granquist))
- avoid monkeypatching the encaps\_lookup\(\) method [\#276](https://github.com/chef/ohai/pull/276) ([lamont-granquist](https://github.com/lamont-granquist))
- collect only unique providers [\#275](https://github.com/chef/ohai/pull/275) ([mcquin](https://github.com/mcquin))
- OC-10998: Test & Fix Chef ohai resource  [\#274](https://github.com/chef/ohai/pull/274) ([sersut](https://github.com/sersut))
- Merge 6 stable [\#271](https://github.com/chef/ohai/pull/271) ([mcquin](https://github.com/mcquin))
- missed one :sigar [\#270](https://github.com/chef/ohai/pull/270) ([lamont-granquist](https://github.com/lamont-granquist))
- Move Ohai Platform Simulation tests to its own directory under spec. [\#269](https://github.com/chef/ohai/pull/269) ([sersut](https://github.com/sersut))
- Remove -f / --file option from OHAI. [\#268](https://github.com/chef/ohai/pull/268) ([sersut](https://github.com/sersut))
- s/:sigar/:default/g [\#267](https://github.com/chef/ohai/pull/267) ([lamont-granquist](https://github.com/lamont-granquist))
- fix uptime plugin to remove sigar [\#266](https://github.com/chef/ohai/pull/266) ([lamont-granquist](https://github.com/lamont-granquist))
- fix hostname plugin + add machinename variable [\#265](https://github.com/chef/ohai/pull/265) ([lamont-granquist](https://github.com/lamont-granquist))
- save plugin source\(s\) for version 7 plugins during loading [\#264](https://github.com/chef/ohai/pull/264) ([mcquin](https://github.com/mcquin))
- make linux/network.rb define collect\_data\(:linux\) [\#263](https://github.com/chef/ohai/pull/263) ([mcquin](https://github.com/mcquin))
- remove plugin windows/kernel\_devices.rb [\#262](https://github.com/chef/ohai/pull/262) ([mcquin](https://github.com/mcquin))
- Lcg/fix network listeners [\#261](https://github.com/chef/ohai/pull/261) ([lamont-granquist](https://github.com/lamont-granquist))
- Update refresh plugin logic for 7.0 architecture [\#260](https://github.com/chef/ohai/pull/260) ([danielsdeleo](https://github.com/danielsdeleo))
- send log output to STDERR by default [\#259](https://github.com/chef/ohai/pull/259) ([lamont-granquist](https://github.com/lamont-granquist))
- catch and ignore failure to load chef [\#258](https://github.com/chef/ohai/pull/258) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix kernel\[:modules\] on :darwin [\#256](https://github.com/chef/ohai/pull/256) ([mcquin](https://github.com/mcquin))
- Temporarily force rubygems 2.1.x for travis [\#255](https://github.com/chef/ohai/pull/255) ([danielsdeleo](https://github.com/danielsdeleo))
- Evaluate all plugin files before instatiating plugin objects [\#254](https://github.com/chef/ohai/pull/254) ([danielsdeleo](https://github.com/danielsdeleo))
- OC-10250 [\#250](https://github.com/chef/ohai/pull/250) ([mcquin](https://github.com/mcquin))
- Explicitly test dependency cycle detection for self-dependency [\#249](https://github.com/chef/ohai/pull/249) ([danielsdeleo](https://github.com/danielsdeleo))
- Pass user-requested attributes from CLI to whitelist [\#248](https://github.com/chef/ohai/pull/248) ([danielsdeleo](https://github.com/danielsdeleo))
- Make sure :disabled\_plugins can disable both v6 and v7 plugins. [\#247](https://github.com/chef/ohai/pull/247) ([sersut](https://github.com/sersut))
- Dependency fixup [\#246](https://github.com/chef/ohai/pull/246) ([danielsdeleo](https://github.com/danielsdeleo))
- Add spec test to check the platform specific collect\_data check. [\#245](https://github.com/chef/ohai/pull/245) ([sersut](https://github.com/sersut))
- Add option to only run plugins providing requested attributes [\#243](https://github.com/chef/ohai/pull/243) ([danielsdeleo](https://github.com/danielsdeleo))
- OC-10251: Comments and minor changes for Nitpicks [\#242](https://github.com/chef/ohai/pull/242) ([sersut](https://github.com/sersut))
- when a plugin depends on an attribute that doesn't have a provider, look... [\#240](https://github.com/chef/ohai/pull/240) ([mcquin](https://github.com/mcquin))
- OC-9924 - Recursively search plugin\_path directories for plugins [\#239](https://github.com/chef/ohai/pull/239) ([sersut](https://github.com/sersut))
- Clean up `jenkins\_run\_tests.bat` [\#236](https://github.com/chef/ohai/pull/236) ([schisamo](https://github.com/schisamo))
- OHAI-537: Require the os plugin in the hostname plugin [\#235](https://github.com/chef/ohai/pull/235) ([btm](https://github.com/btm))
- Plugin provider cleanup [\#232](https://github.com/chef/ohai/pull/232) ([danielsdeleo](https://github.com/danielsdeleo))
- added comment to help someone [\#227](https://github.com/chef/ohai/pull/227) ([caryp](https://github.com/caryp))
- Fix Mac OS X stub java workaround [\#223](https://github.com/chef/ohai/pull/223) ([danielsdeleo](https://github.com/danielsdeleo))
- Remove self-dependency in libvirt plugin [\#222](https://github.com/chef/ohai/pull/222) ([danielsdeleo](https://github.com/danielsdeleo))
- \[OHAI-522\] Correct help output to reference ohai not chef [\#221](https://github.com/chef/ohai/pull/221) ([tas50](https://github.com/tas50))
- swap order of redirects [\#212](https://github.com/chef/ohai/pull/212) ([lamont-granquist](https://github.com/lamont-granquist))
- \[OHAI-508\] Detect CloudLinux as RHEL platform\_family [\#193](https://github.com/chef/ohai/pull/193) ([alexzorin](https://github.com/alexzorin))

## [6.20.0](https://github.com/chef/ohai/tree/6.20.0) (2013-10-31)
[Full Changelog](https://github.com/chef/ohai/compare/6.20.0.rc.1...6.20.0)

**Merged pull requests:**

- Fail Ohai when \> 1 collect\_data blocks defined per platform [\#217](https://github.com/chef/ohai/pull/217) ([mcquin](https://github.com/mcquin))

## [6.20.0.rc.1](https://github.com/chef/ohai/tree/6.20.0.rc.1) (2013-10-21)
[Full Changelog](https://github.com/chef/ohai/compare/6.20.0.rc.0...6.20.0.rc.1)

**Merged pull requests:**

- Pin version of systemu to the same version included in chef. [\#216](https://github.com/chef/ohai/pull/216) ([sersut](https://github.com/sersut))

## [6.20.0.rc.0](https://github.com/chef/ohai/tree/6.20.0.rc.0) (2013-10-18)
[Full Changelog](https://github.com/chef/ohai/compare/6.18.0...6.20.0.rc.0)

**Merged pull requests:**

- Rename providers -\> plugins && seperate v6 methods from v7 methods in system.rb [\#214](https://github.com/chef/ohai/pull/214) ([mcquin](https://github.com/mcquin))
- Test for LANG=C and input contains UTF-8 [\#213](https://github.com/chef/ohai/pull/213) ([lamont-granquist](https://github.com/lamont-granquist))
- Add CI automation scripts to ohai [\#210](https://github.com/chef/ohai/pull/210) ([sersut](https://github.com/sersut))
- OHAI-507: GCE Ohai plugin update for GCE v1beta1 compatibility [\#209](https://github.com/chef/ohai/pull/209) ([adamedx](https://github.com/adamedx))
- Add platform option to collect\_data [\#208](https://github.com/chef/ohai/pull/208) ([mcquin](https://github.com/mcquin))
- OC-9106 AIX Ohai changes re-merge [\#207](https://github.com/chef/ohai/pull/207) ([adamedx](https://github.com/adamedx))
- Bump mixlib-config dependency to 2.0 [\#205](https://github.com/chef/ohai/pull/205) ([jkeiser](https://github.com/jkeiser))
- Revert unintentional changes from master [\#204](https://github.com/chef/ohai/pull/204) ([adamedx](https://github.com/adamedx))
- Added cross-platform tests for the rest of the language plugins [\#203](https://github.com/chef/ohai/pull/203) ([nordsieck-oc](https://github.com/nordsieck-oc))
- Use mixlib-config 2.0 and reset config before each test [\#200](https://github.com/chef/ohai/pull/200) ([jkeiser](https://github.com/jkeiser))
- Fix tests broken on windows by the Mixlib::ShellOut conversion. [\#199](https://github.com/chef/ohai/pull/199) ([nordsieck-oc](https://github.com/nordsieck-oc))
- Fix: cycle detection [\#198](https://github.com/chef/ohai/pull/198) ([mcquin](https://github.com/mcquin))
- Converting the built-in plugins to Mixlib::ShellOut [\#197](https://github.com/chef/ohai/pull/197) ([nordsieck-oc](https://github.com/nordsieck-oc))
- Run v6 plugins that require v7 plugins [\#196](https://github.com/chef/ohai/pull/196) ([mcquin](https://github.com/mcquin))
- Beautify logging and fix command line ohai [\#194](https://github.com/chef/ohai/pull/194) ([nordsieck-oc](https://github.com/nordsieck-oc))
- Add ability to run v6 plugins [\#192](https://github.com/chef/ohai/pull/192) ([mcquin](https://github.com/mcquin))
- Fixing all the weird, hard-to deal with shell command invocations.  Also, random bug fixes. [\#186](https://github.com/chef/ohai/pull/186) ([nordsieck-oc](https://github.com/nordsieck-oc))
- Add dependency resolution to Ohai [\#181](https://github.com/chef/ohai/pull/181) ([mcquin](https://github.com/mcquin))
- Generate more feedback when a plugin throws an exception or fails an RSpec test [\#176](https://github.com/chef/ohai/pull/176) ([nordsieck-oc](https://github.com/nordsieck-oc))
- OC-8704: OC-9106: AIX patches for Ohai platform detection [\#175](https://github.com/chef/ohai/pull/175) ([adamedx](https://github.com/adamedx))
- Detect plugin version [\#172](https://github.com/chef/ohai/pull/172) ([mcquin](https://github.com/mcquin))
- Documentation for adding a cross-platform test, assorted bug fixes and tweaks. [\#171](https://github.com/chef/ohai/pull/171) ([nordsieck-oc](https://github.com/nordsieck-oc))
- Tn/windows Add windows support [\#170](https://github.com/chef/ohai/pull/170) ([nordsieck-oc](https://github.com/nordsieck-oc))
- Plugin classes are named with a random unique identifier [\#169](https://github.com/chef/ohai/pull/169) ([mcquin](https://github.com/mcquin))
- Fix the Build! [\#168](https://github.com/chef/ohai/pull/168) ([nordsieck-oc](https://github.com/nordsieck-oc))
- Introduction of new DSL for OHAI [\#166](https://github.com/chef/ohai/pull/166) ([sersut](https://github.com/sersut))
- Added cross-platform functional tests to linux/kernel, python, php, java and erlang plugins. [\#164](https://github.com/chef/ohai/pull/164) ([nordsieck-oc](https://github.com/nordsieck-oc))

## [6.18.0](https://github.com/chef/ohai/tree/6.18.0) (2013-07-19)
[Full Changelog](https://github.com/chef/ohai/compare/6.18.0.rc.4...6.18.0)

## [6.18.0.rc.4](https://github.com/chef/ohai/tree/6.18.0.rc.4) (2013-07-17)
[Full Changelog](https://github.com/chef/ohai/compare/7.0.0.alpha.0...6.18.0.rc.4)

**Merged pull requests:**

- Disable root\_group on Windows [\#162](https://github.com/chef/ohai/pull/162) ([danielsdeleo](https://github.com/danielsdeleo))
- Disable root\_group on Windows [\#161](https://github.com/chef/ohai/pull/161) ([danielsdeleo](https://github.com/danielsdeleo))

## [7.0.0.alpha.0](https://github.com/chef/ohai/tree/7.0.0.alpha.0) (2013-07-16)
[Full Changelog](https://github.com/chef/ohai/compare/6.18.0.rc.3...7.0.0.alpha.0)

**Merged pull requests:**

- OHAI-412 plus RSpec 2.14 Fixes [\#160](https://github.com/chef/ohai/pull/160) ([danielsdeleo](https://github.com/danielsdeleo))

## [6.18.0.rc.3](https://github.com/chef/ohai/tree/6.18.0.rc.3) (2013-07-15)
[Full Changelog](https://github.com/chef/ohai/compare/6.18.0.rc.2...6.18.0.rc.3)

**Merged pull requests:**

- Use module functions to avoid method name conflict [\#159](https://github.com/chef/ohai/pull/159) ([danielsdeleo](https://github.com/danielsdeleo))

## [6.18.0.rc.2](https://github.com/chef/ohai/tree/6.18.0.rc.2) (2013-07-05)
[Full Changelog](https://github.com/chef/ohai/compare/6.18.0.rc.1...6.18.0.rc.2)

## [6.18.0.rc.1](https://github.com/chef/ohai/tree/6.18.0.rc.1) (2013-06-27)
[Full Changelog](https://github.com/chef/ohai/compare/6.18.0.rc.0...6.18.0.rc.1)

**Merged pull requests:**

- Reap processes and close fds when exec fails [\#154](https://github.com/chef/ohai/pull/154) ([danielsdeleo](https://github.com/danielsdeleo))

## [6.18.0.rc.0](https://github.com/chef/ohai/tree/6.18.0.rc.0) (2013-06-25)
[Full Changelog](https://github.com/chef/ohai/compare/6.16.0...6.18.0.rc.0)

**Merged pull requests:**

- OHAI-126: Improve file regex to handle trailing slash [\#153](https://github.com/chef/ohai/pull/153) ([btm](https://github.com/btm))
- OHAI-419: OC-5329: Azure public ip address unavailable for knife ssh [\#151](https://github.com/chef/ohai/pull/151) ([adamedx](https://github.com/adamedx))
- \[OHAI-434\] Detect and use the latest \(recognized-working\) EC2 metadata API [\#129](https://github.com/chef/ohai/pull/129) ([javmorin](https://github.com/javmorin))
- OHAI-428: add root\_group plugin [\#124](https://github.com/chef/ohai/pull/124) ([josephholsten](https://github.com/josephholsten))

## [6.16.0](https://github.com/chef/ohai/tree/6.16.0) (2013-01-17)
[Full Changelog](https://github.com/chef/ohai/compare/6.14.0...6.16.0)

**Merged pull requests:**

- OHAI-400 \(3\): fixed URI parsing bug when MAC address starts with a number [\#114](https://github.com/chef/ohai/pull/114) ([zuazo](https://github.com/zuazo))
- Fix windows cpu plugin not to use numberofcores property on Windows Serv... [\#109](https://github.com/chef/ohai/pull/109) ([sersut](https://github.com/sersut))
- OHAI-400 \(2\): Show IAM role security credentials in Amazon EC2 [\#105](https://github.com/chef/ohai/pull/105) ([zuazo](https://github.com/zuazo))
- adding raspbian as a distinct platform in the debian family [\#103](https://github.com/chef/ohai/pull/103) ([lamont-opscode](https://github.com/lamont-opscode))
- \[OHAI-380\] Typo in virtualization.rb prevents storage volumes from being listed [\#82](https://github.com/chef/ohai/pull/82) ([philwo](https://github.com/philwo))

## [6.14.0](https://github.com/chef/ohai/tree/6.14.0) (2012-05-30)
[Full Changelog](https://github.com/chef/ohai/compare/0.6.14.rc.1...6.14.0)

## [0.6.14.rc.1](https://github.com/chef/ohai/tree/0.6.14.rc.1) (2012-05-15)
[Full Changelog](https://github.com/chef/ohai/compare/0.6.12...0.6.14.rc.1)

**Merged pull requests:**

- \[Ohai 336\] - Running ohai \(and chef-client\) on OSX without Java prompts user [\#68](https://github.com/chef/ohai/pull/68) ([paulmooring](https://github.com/paulmooring))

## [0.6.12](https://github.com/chef/ohai/tree/0.6.12) (2012-03-22)
[Full Changelog](https://github.com/chef/ohai/compare/0.6.12.rc.3...0.6.12)

**Merged pull requests:**

- add explicit require for rspec [\#57](https://github.com/chef/ohai/pull/57) ([pravi](https://github.com/pravi))

## [0.6.12.rc.3](https://github.com/chef/ohai/tree/0.6.12.rc.3) (2012-03-06)
[Full Changelog](https://github.com/chef/ohai/compare/0.6.12.rc.2...0.6.12.rc.3)

**Merged pull requests:**

- ohai 0.6.12.rc.2 fails to detect peer addresses [\#62](https://github.com/chef/ohai/pull/62) ([hollow](https://github.com/hollow))

## [0.6.12.rc.2](https://github.com/chef/ohai/tree/0.6.12.rc.2) (2012-03-02)
[Full Changelog](https://github.com/chef/ohai/compare/0.6.12.rc.1...0.6.12.rc.2)

**Merged pull requests:**

- Please update dependency on systemu 2.2.0 -\> 2.4.2 [\#60](https://github.com/chef/ohai/pull/60) ([purp](https://github.com/purp))

## [0.6.12.rc.1](https://github.com/chef/ohai/tree/0.6.12.rc.1) (2012-02-09)
[Full Changelog](https://github.com/chef/ohai/compare/0.6.10...0.6.12.rc.1)

**Merged pull requests:**

- OHAI-325 [\#55](https://github.com/chef/ohai/pull/55) ([ctennis](https://github.com/ctennis))
- \[OHAI-324\] Add specs for linux network plugin [\#54](https://github.com/chef/ohai/pull/54) ([ctennis](https://github.com/ctennis))

## [0.6.10](https://github.com/chef/ohai/tree/0.6.10) (2011-10-23)
[Full Changelog](https://github.com/chef/ohai/compare/0.6.8...0.6.10)

## [0.6.8](https://github.com/chef/ohai/tree/0.6.8) (2011-10-05)
[Full Changelog](https://github.com/chef/ohai/compare/0.6.6...0.6.8)

**Merged pull requests:**

- patch for lsb issue on rhel w/ redhat-lsb package installed [\#41](https://github.com/chef/ohai/pull/41) ([bryanwb](https://github.com/bryanwb))

## [0.6.6](https://github.com/chef/ohai/tree/0.6.6) (2011-10-03)
[Full Changelog](https://github.com/chef/ohai/compare/0.6.6.rc.1...0.6.6)

## [0.6.6.rc.1](https://github.com/chef/ohai/tree/0.6.6.rc.1) (2011-09-26)
[Full Changelog](https://github.com/chef/ohai/compare/0.6.6.rc.0...0.6.6.rc.1)

**Merged pull requests:**

- Modified linux/virtualization to look for /proc/xen and then /dev/xen/evt [\#38](https://github.com/chef/ohai/pull/38) ([josephreynolds](https://github.com/josephreynolds))

## [0.6.6.rc.0](https://github.com/chef/ohai/tree/0.6.6.rc.0) (2011-09-21)
[Full Changelog](https://github.com/chef/ohai/compare/0.6.4...0.6.6.rc.0)

## [0.6.4](https://github.com/chef/ohai/tree/0.6.4) (2011-04-28)
[Full Changelog](https://github.com/chef/ohai/compare/0.6.2...0.6.4)

## [0.6.2](https://github.com/chef/ohai/tree/0.6.2) (2011-04-14)
[Full Changelog](https://github.com/chef/ohai/compare/0.6.0.rc.0...0.6.2)

## [0.6.0.rc.0](https://github.com/chef/ohai/tree/0.6.0.rc.0) (2011-04-14)
[Full Changelog](https://github.com/chef/ohai/compare/0.6.0...0.6.0.rc.0)

## [0.6.0](https://github.com/chef/ohai/tree/0.6.0) (2011-04-13)
[Full Changelog](https://github.com/chef/ohai/compare/0.5.8...0.6.0)

## [0.5.8](https://github.com/chef/ohai/tree/0.5.8) (2010-10-19)
[Full Changelog](https://github.com/chef/ohai/compare/0.5.8.rc.0...0.5.8)

## [0.5.8.rc.0](https://github.com/chef/ohai/tree/0.5.8.rc.0) (2010-10-07)
[Full Changelog](https://github.com/chef/ohai/compare/0.5.6...0.5.8.rc.0)

## [0.5.6](https://github.com/chef/ohai/tree/0.5.6) (2010-06-21)
[Full Changelog](https://github.com/chef/ohai/compare/0.5.4...0.5.6)

## [0.5.4](https://github.com/chef/ohai/tree/0.5.4) (2010-05-11)
[Full Changelog](https://github.com/chef/ohai/compare/beta-1...0.5.4)

## [beta-1](https://github.com/chef/ohai/tree/beta-1) (2010-05-11)
[Full Changelog](https://github.com/chef/ohai/compare/0.5.2...beta-1)

## [0.5.2](https://github.com/chef/ohai/tree/0.5.2) (2010-05-06)
[Full Changelog](https://github.com/chef/ohai/compare/alpha_deploy_4...0.5.2)

## [alpha_deploy_4](https://github.com/chef/ohai/tree/alpha_deploy_4) (2010-04-13)
[Full Changelog](https://github.com/chef/ohai/compare/0.5.0...alpha_deploy_4)

## [0.5.0](https://github.com/chef/ohai/tree/0.5.0) (2010-03-04)
[Full Changelog](https://github.com/chef/ohai/compare/0.4.0...0.5.0)

## [0.4.0](https://github.com/chef/ohai/tree/0.4.0) (2010-02-28)
[Full Changelog](https://github.com/chef/ohai/compare/alpha_deploy_3...0.4.0)

## [alpha_deploy_3](https://github.com/chef/ohai/tree/alpha_deploy_3) (2010-02-28)
[Full Changelog](https://github.com/chef/ohai/compare/alpha_deploy_2...alpha_deploy_3)

## [alpha_deploy_2](https://github.com/chef/ohai/tree/alpha_deploy_2) (2010-02-28)
[Full Changelog](https://github.com/chef/ohai/compare/0.3.6...alpha_deploy_2)

## [0.3.6](https://github.com/chef/ohai/tree/0.3.6) (2009-10-26)
[Full Changelog](https://github.com/chef/ohai/compare/0.3.4rc0...0.3.6)

## [0.3.4rc0](https://github.com/chef/ohai/tree/0.3.4rc0) (2009-10-06)
[Full Changelog](https://github.com/chef/ohai/compare/0.3.2...0.3.4rc0)

## [0.3.2](https://github.com/chef/ohai/tree/0.3.2) (2009-07-13)
[Full Changelog](https://github.com/chef/ohai/compare/0.3.0...0.3.2)

## [0.3.0](https://github.com/chef/ohai/tree/0.3.0) (2009-06-18)
[Full Changelog](https://github.com/chef/ohai/compare/0.2.0...0.3.0)

## [0.2.0](https://github.com/chef/ohai/tree/0.2.0) (2009-03-06)
[Full Changelog](https://github.com/chef/ohai/compare/0.1.4...0.2.0)

## [0.1.4](https://github.com/chef/ohai/tree/0.1.4) (2009-02-01)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*