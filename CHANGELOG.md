# Change Log

<!-- latest_release -->
<!-- latest_release -->

<!-- release_rollup -->
<!-- release_rollup -->

<!-- latest_stable_release -->
## [v15.3.1](https://github.com/chef/ohai/tree/v15.3.1) (2019-09-05)

#### Merged Pull Requests
- Use Benchmark.realtime for the main application time as well [#1397](https://github.com/chef/ohai/pull/1397) ([tas50](https://github.com/tas50))
- rspec updates from rubocop-rspec [#1399](https://github.com/chef/ohai/pull/1399) ([tas50](https://github.com/tas50))
- Add sysctl ohai plugin [#1401](https://github.com/chef/ohai/pull/1401) ([joshuamiller01](https://github.com/joshuamiller01))
- Make the new sysctl plugin optional [#1402](https://github.com/chef/ohai/pull/1402) ([tas50](https://github.com/tas50))
- Simplify and fix Openstack detection on Linux [#1395](https://github.com/chef/ohai/pull/1395) ([tas50](https://github.com/tas50))
<!-- latest_stable_release -->

## [v15.2.5](https://github.com/chef/ohai/tree/v15.2.5) (2019-08-08)

#### Merged Pull Requests
- new chefstyle rules for 0.13.2 [#1384](https://github.com/chef/ohai/pull/1384) ([lamont-granquist](https://github.com/lamont-granquist))
- Feature - Change regex for detecting interface&#39;s state [#1382](https://github.com/chef/ohai/pull/1382) ([josephmilla](https://github.com/josephmilla))
- Switch from Appveyor to Buildkite for Windows PR testing [#1383](https://github.com/chef/ohai/pull/1383) ([tas50](https://github.com/tas50))
- Add other_versions subfield for RPM packages. [#1369](https://github.com/chef/ohai/pull/1369) ([jjustice6](https://github.com/jjustice6))
- Translating platform &quot;archarm&quot; to &quot;arch&quot; [#1388](https://github.com/chef/ohai/pull/1388) ([BackSlasher](https://github.com/BackSlasher))
- Display elapsed real time instead of total cpu time [#1392](https://github.com/chef/ohai/pull/1392) ([teknofire](https://github.com/teknofire))
- Use virtualization plugin to detect if we&#39;re on openstack on Windows. [#1391](https://github.com/chef/ohai/pull/1391) ([jjustice6](https://github.com/jjustice6))
- Simplify the Openstack plugin by not polling DMI data [#1394](https://github.com/chef/ohai/pull/1394) ([tas50](https://github.com/tas50))
- Fix platform_version detection on Fedora rawhide [#1396](https://github.com/chef/ohai/pull/1396) ([ritzk](https://github.com/ritzk))

## [15.1.5](https://github.com/chef/ohai/tree/15.1.5) (2019-06-22)

#### Merged Pull Requests
- [shard_seed] fix default_sources for linux, darwin and windows [#1379](https://github.com/chef/ohai/pull/1379) ([michel-slm](https://github.com/michel-slm))
- [shard_seed] fix default_digest_algorithm on darwin [#1381](https://github.com/chef/ohai/pull/1381) ([michel-slm](https://github.com/michel-slm))

## [15.1.3](https://github.com/chef/ohai/tree/15.1.3) (2019-06-14)

#### Merged Pull Requests
- Apply require speedups to ohai [#1363](https://github.com/chef/ohai/pull/1363) ([lamont-granquist](https://github.com/lamont-granquist))
- fix shellout require idempotency [#1365](https://github.com/chef/ohai/pull/1365) ([lamont-granquist](https://github.com/lamont-granquist))
- Solaris network plugin fix for issue https://github.com/chef/ohai/iss… [#1367](https://github.com/chef/ohai/pull/1367) ([devoptimist](https://github.com/devoptimist))
- Avoid constant warnings in windows/filesystem plugin [#1360](https://github.com/chef/ohai/pull/1360) ([tas50](https://github.com/tas50))
- Add VboxHost plugin to support VirtualBox as a virtualization host [#1339](https://github.com/chef/ohai/pull/1339) ([freakinhippie](https://github.com/freakinhippie))
- Test on ruby 2.6 in Appveyor and remove the travis config [#1372](https://github.com/chef/ohai/pull/1372) ([tas50](https://github.com/tas50))
- Use virtualization attributes to run or skip the virtualbox plugin [#1373](https://github.com/chef/ohai/pull/1373) ([tas50](https://github.com/tas50))
- Simplify how we create empty mashes in the plugins [#1374](https://github.com/chef/ohai/pull/1374) ([tas50](https://github.com/tas50))
- Merge the new vbox plugin into the existing virtualbox plugin [#1376](https://github.com/chef/ohai/pull/1376) ([tas50](https://github.com/tas50))

## [v15.0.35](https://github.com/chef/ohai/tree/v15.0.35) (2019-05-10)

#### Merged Pull Requests
- Update master branch for Ohai 15 development [#1277](https://github.com/chef/ohai/pull/1277) ([tas50](https://github.com/tas50))
- Remove the chdir to / when running ohai [#1250](https://github.com/chef/ohai/pull/1250) ([tas50](https://github.com/tas50))
- Remove the deprecated system_profiler plugin [#1278](https://github.com/chef/ohai/pull/1278) ([tas50](https://github.com/tas50))
- Remove the deprecated Ohai::Util::Win32::GroupHelper class [#1279](https://github.com/chef/ohai/pull/1279) ([tas50](https://github.com/tas50))
- Removed unused refresh_plugins method in System class [#1280](https://github.com/chef/ohai/pull/1280) ([tas50](https://github.com/tas50))
- Ignore empty metadata openstack [#1290](https://github.com/chef/ohai/pull/1290) ([sawanoboly](https://github.com/sawanoboly))
- Set User-Agent in HTTP header for GCE plugin [#1291](https://github.com/chef/ohai/pull/1291) ([nathenharvey](https://github.com/nathenharvey))
- Adds more resilient GCE checking [#1292](https://github.com/chef/ohai/pull/1292) ([nathenharvey](https://github.com/nathenharvey))
- Plugin to load hyper_v hostname from guest [#1303](https://github.com/chef/ohai/pull/1303) ([safematix](https://github.com/safematix))
- Remove old spec files [#1301](https://github.com/chef/ohai/pull/1301) ([tas50](https://github.com/tas50))
- Remove circa ~2005 virtualization hypervisor detection [#1305](https://github.com/chef/ohai/pull/1305) ([tas50](https://github.com/tas50))
- Correctly detect openSUSE leap 15+ [#1297](https://github.com/chef/ohai/pull/1297) ([tas50](https://github.com/tas50))
- /etc/os-release based OS detection [#1299](https://github.com/chef/ohai/pull/1299) ([tas50](https://github.com/tas50))
- Windows: Fix for fqdn is being set as the machine name instead of fqdn [#1310](https://github.com/chef/ohai/pull/1310) ([vijaymmali1990](https://github.com/vijaymmali1990))
- Linux Virtualization: Use the new nests `systems` format for lxd / lxc [#1309](https://github.com/chef/ohai/pull/1309) ([tas50](https://github.com/tas50))
- Add mangeia platform with madriva platform_family [#1316](https://github.com/chef/ohai/pull/1316) ([tas50](https://github.com/tas50))
- Add support for SUSE Linux Enterprise Desktop [#1314](https://github.com/chef/ohai/pull/1314) ([tas50](https://github.com/tas50))
- Fix arista platform detection [#1312](https://github.com/chef/ohai/pull/1312) ([tas50](https://github.com/tas50))
- bsd virtualization: Detect amazonec2 hypervisor + kvm without dmidecode [#1319](https://github.com/chef/ohai/pull/1319) ([tas50](https://github.com/tas50))
- platform: Identify sles_sap as the suse platform [#1313](https://github.com/chef/ohai/pull/1313) ([tas50](https://github.com/tas50))
- Add support for antergos linux and fix opensuseleap platform_family [#1320](https://github.com/chef/ohai/pull/1320) ([tas50](https://github.com/tas50))
- Don&#39;t ship the readme with ohai [#1321](https://github.com/chef/ohai/pull/1321) ([tas50](https://github.com/tas50))
- Back out SLES -&gt; SUSE remapping and instead fix the platform_family [#1322](https://github.com/chef/ohai/pull/1322) ([tas50](https://github.com/tas50))
- Require Ruby 2.5 or later [#1300](https://github.com/chef/ohai/pull/1300) ([tas50](https://github.com/tas50))
- Unify virtualization detection on a single helper [#1317](https://github.com/chef/ohai/pull/1317) ([tas50](https://github.com/tas50))
- Add support for XCP-ng platform [#1283](https://github.com/chef/ohai/pull/1283) ([heyjodom](https://github.com/heyjodom))
- Remove V6 plugin Struct to reduce memory consumption [#1333](https://github.com/chef/ohai/pull/1333) ([tas50](https://github.com/tas50))
- Fully remove support for HP-UX [#1336](https://github.com/chef/ohai/pull/1336) ([tas50](https://github.com/tas50))
- Chefstyle fixes for Chefstyle 0.12 [#1337](https://github.com/chef/ohai/pull/1337) ([tas50](https://github.com/tas50))
- Parse new /proc/meminfo fields [#1340](https://github.com/chef/ohai/pull/1340) ([davide125](https://github.com/davide125))
- Loosen the mixlib pins to allow for new major releases [#1341](https://github.com/chef/ohai/pull/1341) ([tas50](https://github.com/tas50))
- Ohai::Util::FileHelper does not need to be loaded in this systemd_paths plugin [#1347](https://github.com/chef/ohai/pull/1347) ([burtlo](https://github.com/burtlo))
- Adds mention of the style task [#1351](https://github.com/chef/ohai/pull/1351) ([burtlo](https://github.com/burtlo))
- Replaces require_relative with require [#1349](https://github.com/chef/ohai/pull/1349) ([burtlo](https://github.com/burtlo))
- Update the repo for the new governance [#1348](https://github.com/chef/ohai/pull/1348) ([tas50](https://github.com/tas50))
- Run ohai in Buildkite [#1355](https://github.com/chef/ohai/pull/1355) ([tas50](https://github.com/tas50))
- Require ohai/version where we use it [#1361](https://github.com/chef/ohai/pull/1361) ([tas50](https://github.com/tas50))

## [v14.6.2](https://github.com/chef/ohai/tree/v14.6.2) (2018-10-11)

#### Merged Pull Requests
- Review and copyediting of RELEASE_NOTES [#1255](https://github.com/chef/ohai/pull/1255) ([mjingle](https://github.com/mjingle))
- Avoid gathering all data with sysctl which seems to hang [#1259](https://github.com/chef/ohai/pull/1259) ([tas50](https://github.com/tas50))
- Add more yard comments [#1256](https://github.com/chef/ohai/pull/1256) ([tas50](https://github.com/tas50))
- Unify the OS plugins [#1261](https://github.com/chef/ohai/pull/1261) ([jaymzh](https://github.com/jaymzh))
- Unify the cpu plugin [#1262](https://github.com/chef/ohai/pull/1262) ([jaymzh](https://github.com/jaymzh))
- Trim out bogus data in system_profile plugin [#1263](https://github.com/chef/ohai/pull/1263) ([tas50](https://github.com/tas50))
- [filesystem] Convert rest of unix to fs2 [#1266](https://github.com/chef/ohai/pull/1266) ([jaymzh](https://github.com/jaymzh))
- Correctly detect SLES 15 systems as &quot;suse&quot; platform [#1272](https://github.com/chef/ohai/pull/1272) ([tas50](https://github.com/tas50))
- Deprecate the system_profile plugin [#1264](https://github.com/chef/ohai/pull/1264) ([tas50](https://github.com/tas50))

## [v14.5.4](https://github.com/chef/ohai/tree/v14.5.4) (2018-09-17)

#### Merged Pull Requests
- Remove redundant platform from the gemspec [#1248](https://github.com/chef/ohai/pull/1248) ([tas50](https://github.com/tas50))
- Add additional yard comments [#1249](https://github.com/chef/ohai/pull/1249) ([tas50](https://github.com/tas50))
- Connect to GCE metadata by IP not name [#1252](https://github.com/chef/ohai/pull/1252) ([tas50](https://github.com/tas50))
- Revert &quot;Connect to GCE metadata by IP not name&quot; [#1253](https://github.com/chef/ohai/pull/1253) ([tas50](https://github.com/tas50))

## [v14.5.0](https://github.com/chef/ohai/tree/v14.5.0) (2018-09-14)

#### Merged Pull Requests
- Add &quot;EncryptionStatus&quot; to each volume on Windows [#1238](https://github.com/chef/ohai/pull/1238) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- override timout by Ohai::Config.ohai[:openstack_metadata_timeout] [#1244](https://github.com/chef/ohai/pull/1244) ([sawanoboly](https://github.com/sawanoboly))
- Fix providing relative paths to the config file [#1241](https://github.com/chef/ohai/pull/1241) ([tas50](https://github.com/tas50))
- Fix root_group plugin invalid byte sequence on non-English version of Windows [#1240](https://github.com/chef/ohai/pull/1240) ([jugatsu](https://github.com/jugatsu))
- Release Ohai 14.5 [#1247](https://github.com/chef/ohai/pull/1247) ([tas50](https://github.com/tas50))

## [v14.4.2](https://github.com/chef/ohai/tree/v14.4.2) (2018-08-22)

#### Merged Pull Requests
- Uniquely name our network plugin helper methods [#1236](https://github.com/chef/ohai/pull/1236) ([tas50](https://github.com/tas50))

## [v14.4.1](https://github.com/chef/ohai/tree/v14.4.1) (2018-08-21)

#### Merged Pull Requests
- Prefer ipv4 for default_gateway over ipv6 on windows [#1231](https://github.com/chef/ohai/pull/1231) ([Nimesh-Msys](https://github.com/Nimesh-Msys))

## [v14.4.0](https://github.com/chef/ohai/tree/v14.4.0) (2018-08-08)

#### Merged Pull Requests
- Add system_enclosure plugin for Windows [#1210](https://github.com/chef/ohai/pull/1210) ([stuartpreston](https://github.com/stuartpreston))
- Load collect_data() even if we&#39;ve already seen it [#1224](https://github.com/chef/ohai/pull/1224) ([btm](https://github.com/btm))
- Remove the changelog generator task [#1225](https://github.com/chef/ohai/pull/1225) ([tas50](https://github.com/tas50))
- Update Expeditor to clean branches / bump minors [#1223](https://github.com/chef/ohai/pull/1223) ([tas50](https://github.com/tas50))
- Add support for passing multiple plugin directories on CLI/client.rb [#1221](https://github.com/chef/ohai/pull/1221) ([tas50](https://github.com/tas50))
- Make the default shell_out timeout of 30 seconds configurable [#1227](https://github.com/chef/ohai/pull/1227) ([WheresAlice](https://github.com/WheresAlice))
- Resolve Expeditor config warnings [#1229](https://github.com/chef/ohai/pull/1229) ([tas50](https://github.com/tas50))
- Add release notes for 14.4 [#1230](https://github.com/chef/ohai/pull/1230) ([tas50](https://github.com/tas50))

## [v14.3.0](https://github.com/chef/ohai/tree/v14.3.0) (2018-07-09)

#### Merged Pull Requests
- Fixes for new chefstyle rules [#1211](https://github.com/chef/ohai/pull/1211) ([lamont-granquist](https://github.com/lamont-granquist))
- Resolve several performance issues identified by Rubocop [#1208](https://github.com/chef/ohai/pull/1208) ([tas50](https://github.com/tas50))
-  Properly detect Amazon Linux 2 final release platform version  [#1214](https://github.com/chef/ohai/pull/1214) ([tas50](https://github.com/tas50))
- Remove the outdated manpage [#1217](https://github.com/chef/ohai/pull/1217) ([tas50](https://github.com/tas50))
- Bump version to 14.3 + add release notes [#1219](https://github.com/chef/ohai/pull/1219) ([tas50](https://github.com/tas50))

## [v14.2.0](https://github.com/chef/ohai/tree/v14.2.0) (2018-06-04)

#### Merged Pull Requests
- Fix yard parsing issues &amp; add more commments [#1187](https://github.com/chef/ohai/pull/1187) ([tas50](https://github.com/tas50))
- Misc minor cleanup [#1189](https://github.com/chef/ohai/pull/1189) ([tas50](https://github.com/tas50))
- Fix an issue caused by using the wrong field in the AIX filesystem plugin. [#1191](https://github.com/chef/ohai/pull/1191) ([jjustice6](https://github.com/jjustice6))
- Detect virtualization on newer AWS instance types. (m5) [#1193](https://github.com/chef/ohai/pull/1193) ([cbajumpaa](https://github.com/cbajumpaa))
- Bump version to 14.2.0 [#1195](https://github.com/chef/ohai/pull/1195) ([tas50](https://github.com/tas50))

## [v14.1.3](https://github.com/chef/ohai/tree/v14.1.3) (2018-05-15)

#### Merged Pull Requests
- Rework FIPS detection to only use the positive of OpenSSL.fips_mode [#1186](https://github.com/chef/ohai/pull/1186) ([coderanger](https://github.com/coderanger))

## [v14.1.2](https://github.com/chef/ohai/tree/v14.1.2) (2018-05-14)

#### Merged Pull Requests
- [filesystem] Unify plugins, bring BSD into the modern age [#1181](https://github.com/chef/ohai/pull/1181) ([jaymzh](https://github.com/jaymzh))
- Fix shard plugin under FIPS mode because my testing was not sufficient [#1184](https://github.com/chef/ohai/pull/1184) ([coderanger](https://github.com/coderanger))

## [v14.1.0](https://github.com/chef/ohai/tree/v14.1.0) (2018-05-04)

#### Merged Pull Requests
- Don&#39;t stacktrace if we can&#39;t shell_out to zpool [#1141](https://github.com/chef/ohai/pull/1141) ([tas50](https://github.com/tas50))
- Exclude example output from rubocop rules &amp; remove changelog generator gem [#1169](https://github.com/chef/ohai/pull/1169) ([tas50](https://github.com/tas50))
- Add Ohai 14 release notes [#1166](https://github.com/chef/ohai/pull/1166) ([tas50](https://github.com/tas50))
- SCSI plugin [#1170](https://github.com/chef/ohai/pull/1170) ([jaymzh](https://github.com/jaymzh))
- Make the FIPS plugins use the new Ruby 2.5 accessor if present [#1178](https://github.com/chef/ohai/pull/1178) ([coderanger](https://github.com/coderanger))
- Make the shard plugin work under FIPS by using SHA2 instead of MD5 [#1175](https://github.com/chef/ohai/pull/1175) ([coderanger](https://github.com/coderanger))
- Make the DMI IDs we whitelist configurable [#970](https://github.com/chef/ohai/pull/970) ([tas50](https://github.com/tas50))
- Update Release Notes for 14.1 [#1179](https://github.com/chef/ohai/pull/1179) ([thommay](https://github.com/thommay))

## [v14.0.28](https://github.com/chef/ohai/tree/v14.0.28) (2018-03-19)

#### Merged Pull Requests
- adds whitespace stripping for the shellout stdout [#1132](https://github.com/chef/ohai/pull/1132) ([rmcleod8](https://github.com/rmcleod8))
- Simplify path logic by requiring chef-config 12.8+ [#1128](https://github.com/chef/ohai/pull/1128) ([tas50](https://github.com/tas50))
- account for snap based installations of LXD [#1131](https://github.com/chef/ohai/pull/1131) ([thewyzard44](https://github.com/thewyzard44))
- Fix vmware specs to actually run the plugin [#1133](https://github.com/chef/ohai/pull/1133) ([tas50](https://github.com/tas50))
- Initial removal of support for Ohai V6 plugins [#1127](https://github.com/chef/ohai/pull/1127) ([tas50](https://github.com/tas50))
- fix failing tests on non linux platforms [#1134](https://github.com/chef/ohai/pull/1134) ([thommay](https://github.com/thommay))
- Docker host detection and information [#1125](https://github.com/chef/ohai/pull/1125) ([tas50](https://github.com/tas50))
- fix critical plugin tests [#1135](https://github.com/chef/ohai/pull/1135) ([thommay](https://github.com/thommay))
- Support optional plugins [#1136](https://github.com/chef/ohai/pull/1136) ([thommay](https://github.com/thommay))
- Simplify &amp; optimize the kernel plugin [#1139](https://github.com/chef/ohai/pull/1139) ([tas50](https://github.com/tas50))
- Add scaleway plugin [#1124](https://github.com/chef/ohai/pull/1124) ([josqu4red](https://github.com/josqu4red))
- Update root_group plugin to use the collect_data helper [#1144](https://github.com/chef/ohai/pull/1144) ([tas50](https://github.com/tas50))
- Add additional information to the kernel plugin on Windows [#1142](https://github.com/chef/ohai/pull/1142) ([tas50](https://github.com/tas50))
- Mark the shard plugin as optional [#1146](https://github.com/chef/ohai/pull/1146) ([thommay](https://github.com/thommay))
- Expand what we blacklist from the kernel/network plugins on Windows [#1147](https://github.com/chef/ohai/pull/1147) ([tas50](https://github.com/tas50))
- Softlayer is forcing tlsv1_2 for all API calls [#1149](https://github.com/chef/ohai/pull/1149) ([smcavallo](https://github.com/smcavallo))
- Remove support for Windows 2003 from uptime/cpu plugins [#1148](https://github.com/chef/ohai/pull/1148) ([tas50](https://github.com/tas50))
- SUSE: Use /etc/os-release if present for all platform attributes [#1140](https://github.com/chef/ohai/pull/1140) ([yeoldegrove](https://github.com/yeoldegrove))
- Fix chefstyle issues in ohai [#1153](https://github.com/chef/ohai/pull/1153) ([tas50](https://github.com/tas50))
- add ohai support for softlayer cloud [#1155](https://github.com/chef/ohai/pull/1155) ([smcavallo](https://github.com/smcavallo))
- Fix bug in azure plugin/update to recent metadata version. [#1154](https://github.com/chef/ohai/pull/1154) ([kriszentner](https://github.com/kriszentner))
- Minor updates to the Ohai/Chef plugins [#1160](https://github.com/chef/ohai/pull/1160) ([tas50](https://github.com/tas50))
- Detect virtualbox and vmware guests on Macs [#1164](https://github.com/chef/ohai/pull/1164) ([tas50](https://github.com/tas50))
- Move ohai to structured logging [#1161](https://github.com/chef/ohai/pull/1161) ([thommay](https://github.com/thommay))

## [v13.7.1](https://github.com/chef/ohai/tree/v13.7.1) (2018-01-10)

[Full Changelog](https://github.com/chef/ohai/compare/v13.7.0...v13.7.1)

- Fix docker detection when running on new Docker for mac releases
- [linux/network] Tunnel information
- Add a plugin to provide PCI bus information using `lspci`

## [v13.7.0](https://github.com/chef/ohai/tree/v13.7.0) (2017-12-04)

[Full Changelog](https://github.com/chef/ohai/compare/v13.6.0...v13.7.0)

- Detect new Amazon hypervisor used by the C5 instances
- [mdadm] Support arrays more than 10 disks
- [mdadm] Handle journal and spare devices properly
- Add support for Linux MemAvailable value
- Added systemd-nspawn virtualization detection
- Remove Ruby 1.8 era rubygems error handling code
- Fix several typos and add a missing debug message

## [v13.6.0](https://github.com/chef/ohai/tree/v13.6.0) (2017-10-24)

[Full Changelog](https://github.com/chef/ohai/compare/v13.5.0...v13.6.0)

- Add support for Critical Plugins [#1064](https://github.com/chef/ohai/pull/1064)
- Fix LXC detection on lxc 1+ by also checking for lxc-start [#1070](https://github.com/chef/ohai/pull/1070)
- Gather packages on Amazon Linux [#1071](https://github.com/chef/ohai/pull/1071)
- Updating AIX uptime_seconds to reflect elapsed seconds from boot rather than epoch [#1075](https://github.com/chef/ohai/pull/1075)
- Detect Rackspace on Windows [#1060](https://github.com/chef/ohai/pull/1060)

## [v13.5.0](https://github.com/chef/ohai/tree/v13.5.0) (2017-09-28)

[Full Changelog](https://github.com/chef/ohai/compare/v13.4.0...v13.5.0)

- Fix the route support for IPV6 routes ending in :: [#1058](https://github.com/chef/ohai/pull/1058)
- Add plugin timing information in debug mode [#1056](https://github.com/chef/ohai/pull/1056)
- Make sure we require wmi/lite in the ec2 plugin [#1059](https://github.com/chef/ohai/pull/1059)

## [v13.4.0](https://github.com/chef/ohai/tree/v13.4.0) (2017-09-11)

[Full Changelog](https://github.com/chef/ohai/compare/v13.3.0...v13.4.0)

- Add Arch Linux support to package plugin [#1042](https://github.com/chef/ohai/pull/1042)
- Detect LXC if LXC and Docker are on the same host [#1055](https://github.com/chef/ohai/pull/1055)
- Add Azure metadata endpoint support [#1033](https://github.com/chef/ohai/pull/1033)
- Move all requires into the plugin definitions [#1045](https://github.com/chef/ohai/pull/1045)
- Improve detection of Windows EC2 nodes by using UUID information [#1052](https://github.com/chef/ohai/pull/1052)
- Add error handling in Linux filesystem plugin [#1047](https://github.com/chef/ohai/pull/1047)
- Properly handle uptimes over a year on AIX [#1049](https://github.com/chef/ohai/pull/1049)
- Handle situations where /proc/cpuinfo lacks core data [#1038](https://github.com/chef/ohai/pull/1038)

## [v13.3.0](https://github.com/chef/ohai/tree/v13.3.0) (2017-8-10)

[Full Changelog](https://github.com/chef/ohai/compare/v13.2.0...v13.3.0)

- Bump timeout for lsblk and blkid to 60s [#1042](https://github.com/chef/ohai/pull/1043)
- Detect F5 Big-IPs as platform bigip [#1035](https://github.com/chef/ohai/pull/1035)
- Properly parse Solaris network interface data [#1030](https://github.com/chef/ohai/pull/1030)

## [v13.2.0](https://github.com/chef/ohai/tree/v13.2.0) (2017-06-29)

[Full Changelog](https://github.com/chef/ohai/compare/v13.1.0...v13.2.0)

- Deprecate the IPScopes Plugin [#1023](https://github.com/chef/ohai/pull/1023)
- Fix the AIX package data [#1020](https://github.com/chef/ohai/pull/1020)
- Add support for ClearLinux [#1021](https://github.com/chef/ohai/pull/1021)
- [mdadm] Handle inactive arrays correctly [#1017](https://github.com/chef/ohai/pull/1017)
- Make Linux filesystem plugin more resilient [#1014](https://github.com/chef/ohai/pull/1014)
- Add clearos platform to RHEL platform_family [#1004](https://github.com/chef/ohai/pull/1004)
- Add systemd_paths plugin for system and user paths [#1013](https://github.com/chef/ohai/pull/1013)
- Find network binaries with the which helper [#1009](https://github.com/chef/ohai/pull/1009)
- Fix mdadm plugin when arrays are in interesting states [#1012](https://github.com/chef/ohai/pull/1012)
- cpu: add support for arm64 cpuinfo fields [#1010](https://github.com/chef/ohai/pull/1010)
- Only shellout to sw_vers in darwin hardware once [#1008](https://github.com/chef/ohai/pull/1008)
- Run sysctl only once on Darwin to determine CPU data [#1007](https://github.com/chef/ohai/pull/1007)
- Update zpools plugin to work on Linux/BSD [#1001](https://github.com/chef/ohai/pull/1001)
- Cleanup and prune the dev gems [#1003](https://github.com/chef/ohai/pull/1003)

## [v13.1.0](https://github.com/chef/ohai/tree/v13.1.0) (2017-05-12)

[Full Changelog](https://github.com/chef/ohai/compare/v13.0.1...v13.1.0)

- Improvements to EC2 metadata handling to reuse connections [#995](https://github.com/chef/ohai/pull/995) ([tas50](https://github.com/tas50))
- EC2: Poll EC2 metadata from the new 2016 metadata API versions [#992](https://github.com/chef/ohai/pull/992) ([tas50](https://github.com/tas50))
- Inject sane paths into shell_out [#991](https://github.com/chef/ohai/pull/991) ([akitada](https://github.com/akitada))
- mdadm: Add members devices array [#989](https://github.com/chef/ohai/pull/989) ([jaymzh](https://github.com/jaymzh))

## [v13.0.1](https://github.com/chef/ohai/tree/v13.0.1) (2017-04-12)

[Full Changelog](https://github.com/chef/ohai/compare/v13.0.0...v13.0.1)

**Fixed bugs:**

- Fix Eucalyptus plugin to use the HttpHelper mixin [#987](https://github.com/chef/ohai/pull/987) ([akitada](https://github.com/akitada))
- Fix OpenStack plugin to use the HttpHelper mixin [#986](https://github.com/chef/ohai/pull/986) ([akitada](https://github.com/akitada))

## [v13.0.0](https://github.com/chef/ohai/tree/v13.0.0) (2017-04-06)

[Full Changelog](https://github.com/chef/ohai/compare/v8.23.0...v13.0.0)

**Implemented enhancements:**

- Load all the plugin paths for ohai plugin dependency resolution [#984](https://github.com/chef/ohai/pull/984) ([thommay](https://github.com/thommay))
- Require Ruby 2.3+ to match Chef itself [#981](https://github.com/chef/ohai/pull/981) ([tas50](https://github.com/tas50))
- Allow ohai to load a plugin path [#980](https://github.com/chef/ohai/pull/980) ([thommay](https://github.com/thommay))
- Fully rename the cloud_v2 plugin to cloud [#978](https://github.com/chef/ohai/pull/978) ([tas50](https://github.com/tas50))
- Replace the existing filesystem plugin on Linux and Darwin with filesystem_v2 [#974](https://github.com/chef/ohai/pull/974) ([tas50](https://github.com/tas50))
- Replace the cloud plugin with the cloud_v2 plugin [#973](https://github.com/chef/ohai/pull/973) ([tas50](https://github.com/tas50))
- Freeze all string values coming out of Ohai. [#972](https://github.com/chef/ohai/pull/972) ([coderanger](https://github.com/coderanger))
- Update amazon to use the platform_family of amazon not RHEL [#971](https://github.com/chef/ohai/pull/971) ([lamont-granquist](https://github.com/lamont-granquist))
- Add DMI type 40,41, and 42 from the latest man page [#969](https://github.com/chef/ohai/pull/969) ([tas50](https://github.com/tas50))
- [ec2] Add additional data from identity document [#964](https://github.com/chef/ohai/pull/964) ([webframp](https://github.com/webframp))
- Move duplicate http logic into a helper [#951](https://github.com/chef/ohai/pull/951) ([tas50](https://github.com/tas50))
- Remove deprecated config logic [#939](https://github.com/chef/ohai/pull/939) ([tas50](https://github.com/tas50))
- Require Ruby 2.2+ [#938](https://github.com/chef/ohai/pull/938) ([tas50](https://github.com/tas50))
- Remove the deprecated run_command and popen4 methods [#933](https://github.com/chef/ohai/pull/933) ([tas50](https://github.com/tas50))
- Remove usage of the Sigar gem [#930](https://github.com/chef/ohai/pull/930) ([tas50](https://github.com/tas50))

**Fixed bugs:**

- Remove sbt version detect as it's not possible in the current sbt [#982](https://github.com/chef/ohai/pull/982) ([tas50](https://github.com/tas50))
- Fix scala detection when version output contains a warning [#959](https://github.com/chef/ohai/pull/959) ([tas50](https://github.com/tas50))
- Fix lua detection on new versions of lua [#958](https://github.com/chef/ohai/pull/958) ([tas50](https://github.com/tas50))
- Fix logger issues [#955](https://github.com/chef/ohai/pull/955) ([lamont-granquist](https://github.com/lamont-granquist))
- Rescue exception in DMI plugin [#952](https://github.com/chef/ohai/pull/952) ([tas50](https://github.com/tas50))
- Use name for Windows CPU model_name [#918](https://github.com/chef/ohai/pull/918) ([tduffield](https://github.com/tduffield))

## [8.24.0](https://github.com/chef/ohai/tree/v8.24.0) (2017-05-08)

[Full Changelog](https://github.com/chef/ohai/compare/v8.23.0...v8.24.0)

- base: Load additional ohai plugins from /etc/chef/ohai/plugins or C:\chef\ohai\plugins\
- ec2: Poll EC2 metadata from the new 2016 metadata API versions [#992](https://github.com/chef/ohai/pull/992) ([tas50](https://github.com/tas50))
- mdadm: Add a new 'members' attribute for member devices in the array [#989](https://github.com/chef/ohai/pull/989) ([jaymzh](https://github.com/jaymzh))
- dmi: Add DMI type 40,41, and 42 from the latest man page [#969](https://github.com/chef/ohai/pull/969) ([tas50](https://github.com/tas50))
- ec2: Gather availability_zone and region data [#964](https://github.com/chef/ohai/pull/964) ([webframp](https://github.com/webframp))
- scala: Fix scala detection when version output contains a warning [#959](https://github.com/chef/ohai/pull/959) ([tas50](https://github.com/tas50))
- lua: Fix lua detection on new versions of lua [#958](https://github.com/chef/ohai/pull/958) ([tas50](https://github.com/tas50))
- dmi: Rescue exception in DMI plugin to improve debug logs [#952](https://github.com/chef/ohai/pull/952) ([tas50](https://github.com/tas50))

## [v8.23.0](https://github.com/chef/ohai/tree/v8.23.0) (2017-01-24)

[Full Changelog](https://github.com/chef/ohai/compare/v8.22.1...v8.23.0)

**Implemented enhancements:**

- C Plugin: Expand GCC data & only shellout to gcc if Xcode is installed on macOS [#944](https://github.com/chef/ohai/pull/944) ([tas50](https://github.com/tas50))
- Improve debug logging in multiple plugins [#935](https://github.com/chef/ohai/pull/935) ([tas50](https://github.com/tas50))
- Detect guests running on Veertu hypervisor [#925](https://github.com/chef/ohai/pull/925) ([tas50](https://github.com/tas50))
- Detect Windows guests running on Hyper-v and Xen [#922](https://github.com/chef/ohai/pull/922) ([rdean716](https://github.com/rdean716))
- Properly detect Cumulus Linux platform / version [#921](https://github.com/chef/ohai/pull/921) ([tas50](https://github.com/tas50))
- Fetch AWS Account ID from metadata [#907](https://github.com/chef/ohai/pull/907) ([Fodoj](https://github.com/Fodoj))

**Fixed bugs:**

- Fix log level selection when running the ohai command [#942](https://github.com/chef/ohai/pull/942) ([thommay](https://github.com/thommay))
- updating cloud plugin to populate azure private_ip as it's currently nil [#937](https://github.com/chef/ohai/pull/937) ([rshade](https://github.com/rshade))

## [v8.22.1](https://github.com/chef/ohai/tree/v8.22.1) (2016-12-07)

[Full Changelog](https://github.com/chef/ohai/compare/8.22.1...v8.22.1)

## [8.22.1](https://github.com/chef/ohai/tree/8.22.1) (2016-12-07)

[Full Changelog](https://github.com/chef/ohai/compare/v8.22.0...8.22.1)

**Implemented enhancements:**

- Pull the complete version string of Erlang [#916](https://github.com/chef/ohai/pull/916) ([tas50](https://github.com/tas50))
- Add sysconf plugin to expose system configuration variables [#893](https://github.com/chef/ohai/pull/893) ([davide125](https://github.com/davide125))

## [v8.22.0](https://github.com/chef/ohai/tree/v8.22.0) (2016-11-30)

[Full Changelog](https://github.com/chef/ohai/compare/v8.21.0...v8.22.0)

**Implemented enhancements:**

- Detect the global zone of a Solaris system as a virt host even without guests [#908](https://github.com/chef/ohai/pull/908) ([numericillustration](https://github.com/numericillustration))
- Add new haskell language plugin [#902](https://github.com/chef/ohai/pull/902) ([cdituri](https://github.com/cdituri))
- Better handle errors in fetching the hostname on darwin (macOS) systems [#884](https://github.com/chef/ohai/pull/884) ([erikng](https://github.com/erikng))
- Prefer lsb_release tool to /etc/lsb-release data [#873](https://github.com/chef/ohai/pull/873) ([kylev](https://github.com/kylev))
- Extend set_attribute plugin helper method to set sub-attributes. [#822](https://github.com/chef/ohai/pull/822) ([mcquin](https://github.com/mcquin))

**Fixed bugs:**

- Rework / fix logic in the joyent plugin and improve specs [#909](https://github.com/chef/ohai/pull/909) ([tas50](https://github.com/tas50))
- Avoid ip_scopes returning tunl/docker interfaces as privateaddress [#890](https://github.com/chef/ohai/pull/890) ([n-marton](https://github.com/n-marton))

## [v8.21.0](https://github.com/chef/ohai/tree/v8.21.0) (2016-10-18)

[Full Changelog](https://github.com/chef/ohai/compare/v8.20.0...v8.21.0)

**Implemented enhancements:**

- Add shard plugin [#877](https://github.com/chef/ohai/pull/877) ([jaymzh](https://github.com/jaymzh))

**Fixed bugs:**

- Ohai uptime plugin hangs in Windows. [#876](https://github.com/chef/ohai/pull/876) ([Aliasgar16](https://github.com/Aliasgar16))

## [v8.20.0](https://github.com/chef/ohai/tree/v8.20.0) (2016-09-07)

[Full Changelog](https://github.com/chef/ohai/compare/v8.19.2...v8.20.0)

**Implemented enhancements:**

- Retrofit network plugin to work on Windows Nano Server [#872](https://github.com/chef/ohai/pull/872) ([mwrock](https://github.com/mwrock))
- Detect lxd [#871](https://github.com/chef/ohai/pull/871) ([jeunito](https://github.com/jeunito))
- Use chefstyle 0.4.0 for linting and resolve all warnings [#870](https://github.com/chef/ohai/pull/870) ([lamont-granquist](https://github.com/lamont-granquist))
- Add kernel[:update] on Solaris Systems [#869](https://github.com/chef/ohai/pull/869) ([MarkGibbons](https://github.com/MarkGibbons))
- Add hostnamectl plugin for Linux machine information [#867](https://github.com/chef/ohai/pull/867) ([davide125](https://github.com/davide125))

## [v8.19.2](https://github.com/chef/ohai/tree/v8.19.2) (2016-08-16)

[Full Changelog](https://github.com/chef/ohai/compare/v8.19.1...v8.19.2)

**Implemented enhancements:**

- Require at least mixlib-log 1.7.1 [#866](https://github.com/chef/ohai/pull/866) ([tas50](https://github.com/tas50))

## [v8.19.1](https://github.com/chef/ohai/tree/v8.19.1) (2016-08-12)

[Full Changelog](https://github.com/chef/ohai/compare/v8.19.0...v8.19.1)

**Fixed bugs:**

- Move log configuration down to Mixlib::Log [#864](https://github.com/chef/ohai/pull/864) ([thommay](https://github.com/thommay))
- Only configure logging if we must [#863](https://github.com/chef/ohai/pull/863) ([thommay](https://github.com/thommay))

## [v8.19.0](https://github.com/chef/ohai/tree/v8.19.0) (2016-08-11)

[Full Changelog](https://github.com/chef/ohai/compare/v8.18.0...v8.19.0)

**Implemented enhancements:**

- Add plugin for available shells [#854](https://github.com/chef/ohai/issues/854)
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

- Move timezone value under time [#836](https://github.com/chef/ohai/pull/836) ([tas50](https://github.com/tas50))
- Update PowerShell Version Compat Detection / Unblock bundler on Appveyor [#832](https://github.com/chef/ohai/pull/832) ([smurawski](https://github.com/smurawski))

## [v8.17.0](https://github.com/chef/ohai/tree/v8.17.0) (2016-06-20)

[Full Changelog](https://github.com/chef/ohai/compare/v8.16.0...v8.17.0)

**Implemented enhancements:**

- Add additional info to networking interfaces/addresses [#830](https://github.com/chef/ohai/pull/830) ([jaymzh](https://github.com/jaymzh))
- Add a simple plugin to get the local timezone. [#829](https://github.com/chef/ohai/pull/829) ([johnbellone](https://github.com/johnbellone))
- Switch to kernel version to identify platform_version on Gentoo [#828](https://github.com/chef/ohai/pull/828) ([tas50](https://github.com/tas50))
- Expose ring parameters in the network plugin [#827](https://github.com/chef/ohai/pull/827) ([davide125](https://github.com/davide125))
- Improve packages attributes [#820](https://github.com/chef/ohai/pull/820) ([glensc](https://github.com/glensc))
- Add version for linux modules when available [#816](https://github.com/chef/ohai/pull/816) ([jmauro](https://github.com/jmauro))
- Add freebsd support in packages plugin [#814](https://github.com/chef/ohai/pull/814) ([vr](https://github.com/vr))

## [v8.16.0](https://github.com/chef/ohai/tree/v8.16.0) (2016-05-12)

[Full Changelog](https://github.com/chef/ohai/compare/v8.15.1...v8.16.0)

**Implemented enhancements:**

- Properly poll Openstack metadata + other Openstack improvements [#818](https://github.com/chef/ohai/pull/818) ([tas50](https://github.com/tas50))
- Update packages plugin to support PLD Linux as an RPM distro [#813](https://github.com/chef/ohai/pull/813) ([glensc](https://github.com/glensc))
- Add detection of bhyve guests running Linux/*BSD [#812](https://github.com/chef/ohai/pull/812) ([tas50](https://github.com/tas50))
- Consistent plugin debug logging [#810](https://github.com/chef/ohai/pull/810) ([tas50](https://github.com/tas50))
- Extra debug logging and error handling in plugin loading [#808](https://github.com/chef/ohai/pull/808) ([tas50](https://github.com/tas50))
- Language plugins: Improve failure logging, update specs, general cleanup [#805](https://github.com/chef/ohai/pull/805) ([tas50](https://github.com/tas50))
- Add method to safely get or check the existence of attributes [#796](https://github.com/chef/ohai/pull/796) ([mcquin](https://github.com/mcquin))

**Fixed bugs:**

- Prevent parallels spec from checking the filesystem [#811](https://github.com/chef/ohai/pull/811) ([tas50](https://github.com/tas50))

## [v8.15.1](https://github.com/chef/ohai/tree/v8.15.1) (2016-04-20)

[Full Changelog](https://github.com/chef/ohai/compare/v8.15.0...v8.15.1)

**Fixed bugs:**

- Avoid defining WINDOWS_ATTRIBUTE_ALIASES multiple times [#806](https://github.com/chef/ohai/pull/806) ([mwrock](https://github.com/mwrock))

## [8.15.0](https://github.com/chef/ohai/tree/8.15.0) (2016-04-18)

[Full Changelog](https://github.com/chef/ohai/compare/v8.14.0...8.15.0)

**Implemented enhancements:**

- Add a fips plugin to detect if fips is enabled [#803](https://github.com/chef/ohai/pull/803) ([mwrock](https://github.com/mwrock))
- Add debug logging to hints and improve cloud specs [#797](https://github.com/chef/ohai/pull/797) ([tas50](https://github.com/tas50))

**Fixed bugs:**

- Fix Elixir version detection on newer Elixir releases [#802](https://github.com/chef/ohai/pull/802) ([tas50](https://github.com/tas50))
- Correct the version detection in erlang plugin [#801](https://github.com/chef/ohai/pull/801) ([tas50](https://github.com/tas50))
- Fix mono builddate capture and add debug logging [#800](https://github.com/chef/ohai/pull/800) ([tas50](https://github.com/tas50))
- Fix the scala plugin to properly return data [#799](https://github.com/chef/ohai/pull/799) ([tas50](https://github.com/tas50))
- Don't execute .so libs for Windows [#798](https://github.com/chef/ohai/pull/798) ([chefsalim](https://github.com/chefsalim))

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

- [pr#720](https://github.com/chef/ohai/pull/720) Make Windows driver plugin opt-in via config
- [pr#717](https://github.com/chef/ohai/pull/717) Don't enable packages plugin by default
- [pr#711](https://github.com/chef/ohai/pull/711) Improve EC2 detection for HVM instances when a hint isn't present

## Release 8.9.0

- [**phreakocious**](https://github.com/phreakocious):

  - Collect layer 1 Ethernet information per NIC on Linux hosts

- [**Mark Gibbons**](https://www.github.com/MarkGibbons):

  - Add kernel[:processor] with output of uname -p output

- [**Shahul Khajamohideen**](https://github.com/sh9189)

  - Add packages plugin

- [**electrolinux**](https://github.com/electrolinux)

  - Add "alpine" platform and platform_family

- [**Julien Berard**](https://github.com/jujugrrr)

  - Add instance_id to rackspace plugin

- [**Matt Whiteley**](https://github.com/whiteley)

  - Allow route table override

- [**JM Howard Brown**](https://github.com/jmhbrown)

  - Add tests and queue_depth to block_device

- [pr#672](https://github.com/chef/ohai/pull/672) CPU plugin for Darwin (OS X) now properly reports the number of real CPUs adds "cores" to match the CPU output on Linux

- [pr#674](https://github.com/chef/ohai/pull/674) CPU plugin for FreeBSD now reports "real" and "core" values to match the CPU output on Linux

- [pr#654](https://github.com/chef/ohai/pull/654) Improvements to filesystem and wpar detection on AIX

- [pr#683](https://github.com/chef/ohai/pull/683) Properly detect the init package on older Linux kernels

- [pr#684](https://github.com/chef/ohai/pull/684) Remove non-functional cucumber tests

- [pr#695](https://github.com/chef/ohai/pull/695) Fix detection of mac address on IPv6 only systems

- [pr#703](https://github.com/chef/ohai/pull/703) Enable ChefStyle per RFC 64

## Release 8.8.1

- [pr#677](https://github.com/chef/ohai/pull/677) Remove dependency on mime-types gem
- [pr#662](https://github.com/chef/ohai/pull/662) Skip the VMware plugin if DMI data doesn't indicate we're on a VMware system

## Release 8.8.0

- [**James Flemer, NDP LLC**](https://github.com/jflemer-ndp):

  - Add detection for RHEV (on Linux guests) to virtualization plugin

- [**Shahul Khajamohideen**](https://github.com/sh9189):

  - Fixes Windows :CPU plugin inconsistencies with other platforms: modifies `cpu[:total]` to return total number of logical processors, adds `cpu[:cores]` to return total number of cores.

- [**clewis**](https://github.com/clewis):

  - Don't constrain the width of `ps` output.

- [**George Gensure**](https://github.com/werkt):

  - Prevents invalid memory access on subsequent failed calls to `proc_state` on sigar by throwing exception on returned invalid PID.

- [**Hleb Valoshka**](https://github.com/375gnu):

  - Add support for DragonFly BSD

- [**Austin Ziegler**](https://github.com/halostatue):

  - Bump mime-type dependency to 3.0

- Make collected zfs filesystem properties configurable on solaris2.

- Add kernel bitness detection for AIX

- Fix CPU detection on FreeBSD 10.2+, add collection CPU family and model data.

- Add inode data for filesystems on FreeBSD

- Detect Virtualbox, VMware, and KVM on Windows guests and speed up Ohai runs

- Add a plugin for Virtualbox to provide host / guest version information

- Escape plugin directory path to prevent failures on Windows

- Detect Microsoft Hyper-V Linux/BSD guests, which were previously detected as VirtualPC guests
- Detect Microsoft VirtualPC Linux/BSD guests on additional releases of VirtualPC
- Add KVM, VirtualBox, and Openstack guest detection to BSD platforms and add the node[:virtualization][:systems] syntax

## Release 8.7.0

- [**Shahul Khajamohideen**](https://github.com/sh9189):

  - Add total cores to linux cpu plugin

- Fix behavior when abort called from plug-in (Ohai should exit with error code)

## Release 8.6.0

- [**Phil Dibowitz**](https://github.com/jaymzh):

  - Provide a new and improved filesystem plugin for Linux & Mac (filesystem2), to support CentOS7, multiple virtual filesystems, etc.
  - Fix Darwin filesystem plugin on newer MacOSX

- [**Jonathan Amiez**](https://github.com/josqu4red):

  - Linux filesystems plugin report wrong fs-type for logical volumes

- [**involucelate**](https://github.com/involucelate)

  - Fix Windows 2008 hostname truncation #554

- [**Pavel Yudin**](https://github.com/Kasen):

  - Detect Parallels host and guest virtualization

- [**Claire McQuin**](https://github.com/mcquin):

  - Deprecate Ohai::Config in favor of Ohai::Config.ohai.
  - Load a configuration file while running as an application.

- [PR #597](https//github.com/chef/ohai/pull/597):

  - Correct platform, platform_family and version detection on Cisco's Nexus platforms.

- [**cmluciano**](https://github.com/cmluciano):

  - add vmware plugin

- [**Jean Baptiste Favre**](https://github.com/jbfavre):

  - Detect updated docker cgroup format

- [**Shahul Khajamohideen**](https://github.com/sh9189):

  - Fix memory plugin output on Solaris
  - Add swap space attributes for Solaris memory plugin
  - Add swap space attributes for AIX
  - Add support for SPARC based processors in Solaris cpu plugin
  - Make AIX cpu plugin's output consistent with Solaris cpu plugin
  - Make AIX, Solaris memory output consistent to Linux

- [**Sean Horn**](https://github.com/sean-horn):

  - ec2 plugin should handle binary userdata too

- [**Alexey Karpik**](https://github.com/akarpik):

  - Add support for SoftLayer cloud

- [**MichaelSp**](https://github.com/MichaelSp):

  - return correct ipaddress for openvz guests

- [**Anthony Caiafa**](https://github.com/acaiafa):

  - Only run ifconfig against active interfaces

- [**Shahul Khajamohideen**](https://github.com/sh9189) and [**Sean Escriva**](https://github.com/webframp):

  - Windows Memory plugin

- [**Chris Chambers**](https://github.com/cachamber):

  - Convert Solaris OHAI CPU detection to kstat from psrinfo

## Release 8.5.0

- [PR #548](https://github.com/chef/ohai/pull/548): Coerce non-UTF8 strings to UTF8 in output to suppress UTF8 encoding exceptions
- [PR #544](https://github.com/chef/ohai/pull/544) add support for Wind River Linux and Cisco's Nexus platforms

## Release 8.4.0

- Correctly skip unwanted DMI information
- Collect DMI information on Solaris/x86

## Release 8.3.0

- [**Jeremy Mauro**](https://github.com/jmauro): Removing trailing space and '\r' for windows #474
- [**Tim Smith**](https://github.com/tas50): Ensure Gentoo based Linuxen get IP information
- [PR #534](https://github.com/chef/ohai/pull/534) Ignore OEM logo on Windows

## Release 8.2.0

- [**Michael Glenney**](https://github.com/Maniacal) Remove redundant if statement
- Remove CloudStack support due to GPL licensed library

## Release 8.1.1

- Fix broken DigitalOcean plugin

## Release 8.1.0

- [**Warren Bain**](https://github.com/thoughtcroft) Fix for removal of :Config in ruby 2.2
- [**Chris Luciano**](https://github.com/cmluciano) Add language elixir
- [**Chris Luciano**](https://github.com/cmluciano) Update WARNING for ohai 7 syntax docs page
- [**Malte Swart**](https://github.com/mswart) ssh_host_key: detect ed25519 host key
- [**hirose31**](https://github.com/hirose31) Detect OpenStack guest server using dmidecode
- [**Chris Luciano**](https://github.com/cmluciano) Add language rust.
- [**Tim Smith**](https://github.com/tas50) Add additional information on the PHP engine versions to PHP plugin
- [**Paul Czarkowski**](https://github.com/paulczar) detect if inside Docker container
- [**Michael Schmidt**](https://github.com/BugRoger) OHAI-339 Unable to detect IPAddress on CoreOS/Gentoo
- [**Stafford Brunk**](https://github.com/wingrunr21) Digital Ocean ohai/cloud support round
- [**Sten Spans**](https://github.com/sspans) Fix network.rb for XenServer Creedence
- [**Shuo Zhang**](https://github.com/zshuo) Update Linux plugin cpu.rb and spec_cpu.rb to support S390
- [**Alexey Karpik**](https://github.com/akarpik) Fix up incorrect CloudStack metadata
- [**Jeff Goldschrafe**](https://github.com/jgoldschrafe) cloud_v2 fails to initialize on GCE hosts without external IP
- [**Ryan Chipman**](https://github.com/rychipman) Archlinux Version
- [**Jose Luis Salas**](https://github.com/josacar) Add a trailing dot to avoid using search option in resolv.conf
- [**Eric G. Wolfe**](https://github.com/atomic-penguin) block_device rotational key
- [**Josh Blancett**](https://github.com/jblancett) add extra metadata passed in from hints in knife-linode
- Update mime-types dependency

## Release 8.0.0

- [**sawanoboly**](https://github.com/sawanoboly) Retrieve OpenStack-specific metadata.
- [**Olle Lundberg**](https://github.com/lndbrg) Add CloudStack support.
- [**Tim Smith**](https://github.com/tas50) Remove newlines in CPU strings on Darwin.
- [**Nathan Huff**](https://github.com/nhuff) Match zpool output for OmniOS 151006.
- [**Pavel Yudin**](https://github.com/Kasen) Add Parallels Cloud Server (PCS) platform support.
- [**Christian Vozar**](https://github.com/christianvozar): Add Go language plugin.
- [**Phil Dibowitz**](https://github.com/jaymzh): regression: qualify device names from lsblk
- [**Chris Read**](https://github.com/cread): Add support for ip version ss131122.
- [**carck**](https://github.com/carck): Reduce GCE metadata timeout to 6 seconds.
- [**barnabear**](https://github.com/barnabear): Add Pidora platform detection.
- [**Ben Carpenter**](https://github.com/bcarpenter): Presume 'latest' API version on 404 from Eucalyptus metadata server.
- [**Nabeel Shahzad**](https://github.com/nshahzad): Look for any number of spaces between the VxID and the value.
- [**Daniel Searles**](https://github.com/squaresurf): Removed *.static.cloud-ips.com and fixed the DNS resolution on Rackspace hosts.
- Update specs to use RSpec 3 syntax
- Update mixlib-shellout pin to ~> 2.x

## Release 7.6.0

- This release was yanked due to mixlib-shellout 1.x/2.x issues

## Release 7.4.0

- Added Powershell plugin.

## Release 7.2.4

- [**Phil Dibowitz**](https://github.com/jaymzh): linux::network should handle ECMP routes

## Release 7.2.2

- [**Phil Dibowitz**:](https://github.com/jaymzh) Use lsblk instead of blkid if available.
- [**Phil Dibowitz**:](https://github.com/jaymzh) linux::filesystem now reads all of /proc/mounts instead of just 4K

## Release: 7.2.0

- [**Lance Bragstad**:](https://github.com/lbragstad) Added platform_family support for ibm_powerkvm (OHAI-558)
- [**Pierre Carrier**:](https://github.com/pcarrier) EC2 metadata errors are unhelpful (OHAI-566)
- [**Elan Ruusamäe**:](https://github.com/glensc) Support deep virtualization systems in `node[:virtualization][:systems]` (OHAI-182)
- [**Sean Walberg**:](https://github.com/swalberg) :Passwd plugin now ignores duplicate users. (OHAI-561)
- [**Joe Richards**:](https://github.com/viyh) Fix warning message about constants already defined (OHAI-572)
- [**Tim Smith**:](https://github.com/tas50) Present all CPU flags on FreeBSD (OHAI-568)
- [**Tim Smith**:](https://github.com/tas50) Ohai doesn't detect all KVM processor types as KVM on FreeBSD (OHAI-575)
- [**Tim Smith**:](https://github.com/tas50) Ohai should expose mdadm raid information on Linux systems (OHAI-578)
- [**Cam Cope**:](https://github.com/ccope) relax regex to match newer Oracle Solaris releases (OHAI-563)
- [**Vasiliy Tolstov**:](https://github.com/vtolstov) add exherbo support (OHAI-570)
- [**jasonpgignac**](https://github.com/jasonpgignac) Add inode information to the Linux Filesystem plugin. (OHAI-539)
- [**Benedikt Böhm**](https://github.com/hollow) Change log-level from warn to debug for missing gateway IPs.
- [**sawanoboly**](https://github.com/sawanoboly) Include Joyent SmartOS specific attributes in Ohai. (OHAI-458)
- [**Mike Fiedler**](https://github.com/miketheman) Collect ec2 metadata even if one of the resources returns a 404\. (OHAI-541)
- [**Pat Collins**](https://github.com/patcoll) Provide basic memory information for Mac OS X. (OHAI-431)
- [**Jerry Chen**](https://github.com/jcsalterego): Rackspace plugin rescues Errno::ENOENT if xenstor-* utils are not found (OHAI-587)
- root_group provider not implemented for Windows (OHAI-491)
- `Ohai::Exceptions::AttributeNotFound` errors in Chef's ohai resource
- Be reluctant to call something an LXC host (OHAI-573)
- Assume 'latest' metadata versions on 404

## Release: 7.0.4

- Added platform_family support for ibm_powerkvm (OHAI-558)
- cannot disable Lsb plugin (OHAI-565)
- Skip v7 plugins when refreshing a v6 plugin. Fixes (OHAI-562) `Ohai::Exceptions::AttributeNotFound` errors in Chef's ohai resource
- Work around libc bug in `hostname --fqdn`
- Report Suse and OpenSuse separately in the :platform attribute.
- CPU information matching Linux is now available on Darwin.
- ip6address detection failure logging is turned down to :debug.
- fe80:: link-local address is not reported as ip6addresses anymore.
- Private network information is now available as [:rackspace][:private_networks] on Rackspace nodes.
- System init mechanism is now reported at [:init_package] on Linux.
- Define cloud plugin interface (OHAI-542)
- java -version wastes memory (OHAI-550)
- Ohai cannot detect running in an lxc container (OHAI-551)
- Normalize cloud attributes for Azure (OHAI-554)
- Capture FreeBSD osreldate for comparison purposes (OHAI-557)

<http://www.chef.io/blog/2014/04/09/release-chef-client-11-12-2/>