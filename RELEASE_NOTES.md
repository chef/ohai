# Ohai Release Notes 15.2

## Openstack Plugin Enhancements

The Openstack plugin now uses data from the Virtualization plugin to determine if a host is running on Openstack. This not only speeds up the plugin, but also better detects when running on Openstack. The plugin has also been updated to run on Windows hosts. Thanks @jjustice6

## other_versions in Packages Plugin

Since multiple versions of the same package can exist on RPM based systems a new `other_versions` field has been introduced to list other versions of packages such as the Linux kernel. Thanks @jjustice6

## Other Enhancements

- When debugging Ohai the elapsed time for plugins will include time spent waiting for programs to shell out, not just time the plugin spent executing Ruby code
- The Linux Network plugin has been improved to not mark interfaces down if stp_state is marked as down. Thanks @josephmilla
- Arch running on Arm processors is now detected as the `arm` platform. Thanks @BackSlasher

# Ohai Release Notes 15.1

## Virtualbox Plugin Enhancements

The Virtualbox plugin now gathers a large amount of data on Virtualbox hosts. Additionally the plugin has been updated to better detect when running on a Virtualbox guest or host.

## Other Enhancements

- Ohai performance improved by changing how Ruby requires libraries
- Multiple fixes to the Shard plugin to ensure the hash is created

# Ohai Release Notes 15.0

## Improvements

### Improved Linux Platform / Platform Family Detection

Platform and plaform_family detection on Linux has been rewritten to utilize the latest config files on modern Linux distributions before falling back to slower and fragile legacy detection methods. Ohai will now begin by parsing the contents of /etc/os-release for OS information if available. This improves the reliability of detection on modern distros and allows detection of new distros as they're released.

With this change we now detect `sles_sap` as a member of the `suse` platform_family. Additionally this change corrects our detection of the platform_version on Cisco Nexus switches where we previously incorrectly appended the build number to the version string.

### Improved Virtualization Detection

Hypervisor detection on multiple platforms has been updated to use DMI data and a single set of hypervisors. This greatly improves the detection of hypervisors on Windows, BSD and Solaris platforms. It also means that as new hypervisors detection is added in the future we will automatically support the majority of platforms.

### Fix Windows 2016 FQDN Detection

Ohai 14 incorrectly detected a Windows 2016 node's `fqdn` as the node's `hostname`. Ohai 15 now correctly reports the FQDN value.

### Improved Memory Usage

Ohai now uses less memory due to internal optimizations of how we track plugin information.

### FIPS Detection Improvements

The FIPS plugin now uses the built-in FIPS detection in Ruby for improved detection.

## Breaking Changes

### system_profiler plugin removal

The `system_profiler` plugin which ran on macOS systems has been removed. This plugin took longer to run than all other plugins on macOS combined and no longer produced usable information on modern macOS releases. If you're looking for similar information it can now be found in the `hardware` plugin.

### Ohai::Util::Win32::GroupHelper helper removal

The deprecated `Ohai::Util::Win32::GroupHelper` helper has been removed from Ohai. Any custom Ohai plugins using this helper will need to be updated.

### Ohai::System.refresh_plugins method removal

The `refresh_plugins` method in the `Ohai::System` class has been removed as it has been unused for multiple major Ohai releases. If you are programatically using Ohai in your own Ruby application you will need to update your code to use the `load_plugins` method instead.

### Microsoft VirtualPC / VirtualServer detection removal

The Virtualization plugin will no longer detect systems running on the circa ~2005 VirtualPC or VirtualServer hypervisors. These hypervisors were long ago deprecated by Microsoft and support can no longer be tested.

# Ohai Release Notes 14.8

## Improved Virtualization Detection

### Hyper-V Hypervisor Detection

Detection of Linux guests running on Hyper-V has been improved. In addition, Linux guests on Hyper-V hypervisors will also now detect their hypervisor's hostname. Thank you [@safematix](https://github.com/safematix) for contributing this enhancement.

Example `node['virtualization']` data:
```json
{
  "systems": {
    "hyperv": "guest"
  },
  "system": "hyperv",
  "role": "guest",
  "hypervisor_host": "hyper_v.example.com"
}
```

### LXC / LXD Detection

On Linux systems running lxc or lxd containers, the lxc/lxd virtualization system will now properly populate the `node['virtualization']['systems']` attribute.

### BSD Hypervisor Detection

BSD-based systems can now detect guests running on KVM and Amazon's hypervisor without the need for the dmidecode package.

## New Platform Support

- Ohai now properly detects the openSUSE 15.X platform. Thank you [@megamorf](https://github.com/megamorf) for reporting this issue.
- Suse Linux Enterprise Desktop now identified as platform_family 'suse'
- XCP-NG is now identified as platform 'xcp' and platform_family 'rhel'. Thank you [@heyjodom](http://github.com/heyjodom) for submitting this enhancement.
- Mangeia Linux is now identified as platform 'mangeia' and platform_family 'mandriva'
- Antergos Linux now identified as platform_family 'arch'
- Manjaro Linux now identified as platform_family 'arch'

# Ohai Release Notes 14.6

## Filesystem Plugin on AIX and Solaris

AIX and Solaris now ship with a filesystem2 plugin that updates the filesystem data to match that of Linux, macOS, amd BSD hosts. This new data structure makes accessing filesystem data in recipes easier and especially improves the layout and depth of data on ZFS filesystems. In Chef 15 (April 2019) we will begin wrting this same format of data to the existing `node['filesystem']` namespace. In Chef 16 (April 2020) we will remove the `node['filesystem2']` namspace, completing the transition to the new format. Thank you @jaymzh for continuing the updates to our filesystem plugins with this change.

## macOS Improvements

The system_profile plugin has been improved to skip over uncessary data, which reduces macOS node sizes on the Chef Server. Additionally the CPU plugin has been updated to limit what sysctl values it polls, which prevents hanging on some system configurations.

## SLES 15 Detection

SLES 15 is now correctly detected as the platform "suse" instead of "sles". This matches the behavior of SLES 11 and 12 hosts.

## New Deprecations

### system_profile plugin removal

The system_profile plugin will be removed from Chef/Ohai 15 in April 2019. This plugin does not correctly return data on modern Mac systems. Additionally the same data is provided by the hardware plugin, which has a format that is simpler to consume. Removing this plugin will reduce Ohai return by ~3 seconds and greatly reduce the size of the node object on the Chef server.

# Ohai Release Notes 14.5

## Windows Improvements

Detection for the `root_group` attribute on Windows has been simplified and improved to properly support non-English systems. With this change, we've also deprecated the `Ohai::Util::Win32::GroupHelper` helper, which is no longer necessary. Thanks to [@jugatsu](https://github.com/jugatsu) for putting this together.

We've also added a new `encryption_status` attribute to volumes on Windows. Thanks to [@kmf](https://github.com/kmf) for suggesting this new feature.

## Configuration Improvements

The timeout period for communicating with OpenStack metadata servers can now be configured with the `openstack_metadata_timeout` config option. Thanks to [@sawanoboly](https://github.com/sawanoboly) for this improvement.

Ohai now properly handles relative paths to config files when running on the command line. This means commands like `ohai -c ../client.rb` will now properly use your config values.

# Ohai Release Notes 14.4

## Multiple plugin directories

You can now specify more than one directory to load additional Ohai plugins from by using the `--directory` / `-d` flag more than once.

Example:
```bash
ohai -d /path/to/more/plugins -d /another/path/to/more/plugins
```

Thanks @jaymzh for reporting this.

## Shellout Timeout Configuration

By default, the timeout for any shellout in Ohai is 30 seconds. If this is too short for you, due to slow systems or large numbers of mounts, you may need to increase this timeout. You can now configure your own timeout (lower or higher) via the new `shellout_timeout` config setting.

Thanks @WheresAlice for this change.

## System Enclosure Plugin

On Windows, we have a new System Enclosure plugin that provides you with the `manufacturer` and `serialnumber` of the underlying system.

Thanks [@kmf](https://github.com/kmf) for suggesting this plugin.

# Ohai Release Notes 14.3

## Detection of Amazon Linux 2.0

Ohai now properly detects the platform_version of the final release of Amazon Linux 2.0 in addition to the previous detection of the RC platform_version.

# Ohai Release Notes 14.2

## Virtualization detection on AWS

Ohai now detects the virtualization hypervisor `amazonec2` when running on Amazon's new C5/M5 instances.

# Ohai Release Notes 14.1

## Configurable DMI Whitelist

The whitelist of DMI IDs is now user configurable using the `additional_dmi_ids` configuration setting, which takes an Array.

## Shard plugin

The Shard plugin has been returned to a default plugin rather than an optional one. To ensure we work in FIPS environments, the plugin will use SHA256 rather than MD5 in those environments.

## SCSI plugin

A new plugin to enumerate SCSI devices has been added. This plugin is optional.

# Ohai Release Notes 14.0

## Windows Kernel information

The kernel plugin now reports the following information on Windows:

- `node['kernel']['product_type']` - Workstation vs. Server editions of Windows
- `node['kernel']['system_type']` - What kind of hardware are we installed on (Desktop, Mobile, Workstation, Enterprise Server, etc.)
- `node['kernel']['server_core']` - Are we on Windows Server Core edition?

## Cloud Detection

Ohai now detects the Scaleway cloud and provides additional configuration information for systems running on Azure.

## Virtualization / Container Detection

In addition to detecting if a system is a Docker host, we now provide a large amount of Docker configuration information available at `node['docker']`. This includes the release of Docker, installed plugins, network config, and the number of running containers.

Ohai also now properly detects LXD containers and macOS guests running on VirtualBox / VMware. This data is available in `node['virtualization']['systems']`

## Optional Ohai Plugins

Ohai now includes the ability to mark plugins as optional, which skips those plugins by default. This allows us to ship additional plugins, which some users may find useful, but not all users would want being written to their Chef server. The change introduces two new configuration options; `run_all_plugins` which runs everything including optional plugins, and `optional_plugins` which allows you to run plugins marked as optional.

By default we will now be marking the `lspci`, `sessions` and `passwd` plugins as optional. Passwd has been particularly problematic for nodes attached LDAP or AD where it attempts to write the entire directory to the node. If you previously disabled this plugin via Ohai config, you no longer need to. Hurray!

## Logging Improvements

Chef and Ohai now includes a new log level of `:trace` in addition to the existing `:info`, `:warn`, and `:debug` levels. With the introduction of `trace` level logging we've moved a large amount of logging that more useful for developers from `debug` to `trace`. If you want a complete insight into what is going on internally in Ohai run -l trace not -l debug.

## Breaking Changes

### cloud_v2 and filesystem2 Plugins

In Chef 13 the `cloud_v2` plugin replaced data at `node['cloud']` and `filesystem2` replaced data at `node['filesystem']`. For compatibility with cookbooks that were previously using the "v2" data we continued to write data to both locations (ie: both node['filesystem'] and node['filesystem2']). We now no longer write data to the "v2" locations which greatly reduces the amount of data we need to store on the Chef server.

### Ipscopes Plugin Removed

The ipscopes plugin has been removed as it duplicated data already present in the network plugins and required the user to install an additional gem into the Chef installation.

### libvirt attributes moved

The libvirt Ohai plugin now writes data to `node['libvirt']` instead of writing to various locations in `node['virtualization']`. This plugin required installing an additional gem into the Chef installation and thus was infrequently used.

### Ohai Plugin V6 Support Removed

In 2014 we introduced Ohai v7 with a greatly improved plugin format. With Chef 14 we no longer support loading of the legacy "v6" plugin format.

### Newly-disabled Ohai Plugins

As mentioned above we now support an `optional` flag for Ohai plugins and have marked the `sessions`, `lspci`, and `passwd` plugins as optional, which disables them by default. If you need one of these plugins you can include them using `optional_plugins`.

optional_plugins in the client.rb file:

```ruby
optional_plugins [ "lspci", "passwd" ]
```

# Ohai Release Notes 13.8.0

## Softlayer metadata polling fixed

We now use TLS 1.2 for polling Softlayer metadata since 1.0/1.1 were disabled on 3/1/2018

# Ohai Release Notes 13.7.1

## Network Tunnel Information

The Network plugin on Linux hosts now gathers additional information on tunnels

## LsPci Plugin

The new LsPci plugin provides a `node[:pci]` hash with information about the PCI bus based on `lspci`. Only runs on Linux.

# Ohai Release Notes 13.7

## EC2 C5 Detection

The EC2 plugin has been updated to properly detect the new AWS hypervisor used in the C5 instance types

## mdadm

The mdadm plugin has been updated to properly handle arrays with more than 10 disks and to properly handle journal and spare drives in the disk counts

# Ohai Release Notes 13.6

## Critical Plugins

Users can now specify a list of plugins which are `critical`. Critical plugins will cause Ohai to fail if they do not run successfully (and thus cause a Chef run using Ohai to fail). The syntax for this is:

```
ohai.critical_plugins << :Filesystem
```

## Filesystem now has a `allow_partial_data` configuration option

The Filesystem plugin now has a `allow_partial_data` configuration option. If set, the filesystem will return whatever data it can even if some commands it ran failed.

## Rackspace detection on Windows

Windows nodes running on Rackspace will now properly detect themselves as running on Rackspace without a hint file.

## Package data on Amazon Linux

The Packages plugin now supports gathering packages data on Amazon Linux

## Deprecation updates

In Ohai 13 we replaced the filesystem and cloud plugins with the filesystem2 and cloud_v2 plugins. To maintain compatibility with users of the previous V2 plugins we write data to both locations. We had originally planned to continue writing data to both locations until Chef 15\. Instead due to the large amount of duplicate node data this introduces we are updating OHAI-11 and OHAI-12 deprecations to remove node['cloud_v2'] and node['filesystem2'] with the release of Chef 14 in April 2018.

# Ohai Release Notes 13.5

## Correctly detect IPv6 routes ending in ::

Previously we would ignore routes that ended `::`, and now we properly detect them.

## Plugin run time is now measured

Debug logs will show the length of time each plugin takes to run, making debugging of long ohai runs easier.

# Ohai Release Notes 13.4

## Windows EC2 Detection

Detection of nodes running in EC2 has been greatly improved and should now detect nodes 100% of the time including nodes that have been migrated to EC2 or were built with custom AMIs.

## Azure Metadata Endpoint Detection

Ohai now polls the new Azure metadata endpoint, giving us additional configuration details on nodes running in Azure

Sample data now available under azure:

```javascript
{
  "metadata": {
    "compute": {
      "location": "westus",
      "name": "timtest",
      "offer": "UbuntuServer",
      "osType": "Linux",
      "platformFaultDomain": "0",
      "platformUpdateDomain": "0",
      "publisher": "Canonical",
      "sku": "17.04",
      "version": "17.04.201706191",
      "vmId": "8d523242-71cf-4dff-94c3-1bf660878743",
      "vmSize": "Standard_DS1_v2"
    },
    "network": {
      "interfaces": {
        "000D3A33AF03": {
          "mac": "000D3A33AF03",
          "public_ipv6": [

          ],
          "public_ipv4": [
            "52.160.95.99",
            "23.99.10.211"
          ],
          "local_ipv6": [

          ],
          "local_ipv4": [
            "10.0.1.5",
            "10.0.1.4",
            "10.0.1.7"
          ]
        }
      },
      "public_ipv4": [
        "52.160.95.99",
        "23.99.10.211"
      ],
      "local_ipv4": [
        "10.0.1.5",
        "10.0.1.4",
        "10.0.1.7"
      ],
      "public_ipv6": [

      ],
      "local_ipv6": [

      ]
    }
  }
}
```

## Package Plugin Supports Arch Linux

The Package plugin has been updated to include package information on Arch Linux systems.

# Ohai Release Notes 13.3

## Additional Platform Support

Ohai now properly detects the [F5 Big-IP](https://www.f5.com/) platform and platform_version.

- platform: bigip
- platform_family: rhel

# Ohai Release Notes 13.2:

Ohai 13.2 has been a fantastic release in terms of community involvement with new plugins, platform support, and critical bug fixes coming from community members. A huge thank you to msgarbossa, albertomurillo, jaymzh, and davide125 for their work.

## New Features

### Systemd Paths Plugin

A new plugin has been added to expose system and user paths from systemd-path (see <https://www.freedesktop.org/software/systemd/man/systemd-path.html> for details).

### Linux Network, Filesystem, and Mdadm Plugin Resilience

The Network, Filesystem, and Mdadm plugins have been improved to greatly reduce failures to collect data. The Network plugin now better finds the binaries it requires for shelling out, filesystem plugin utilizes data from multiple sources, and mdadm handles arrays in bad states.

### Zpool Plugin Platform Expansion

The Zpool plugin has been updated to support BSD and Linux in addition to Solaris.

### RPM version parsing on AIX

The packages plugin now correctly parses RPM package name / version information on AIX systems.

### Additional Platform Support

Ohai now properly detects the [Clear](https://clearlinux.org/) and [ClearOS](https://www.clearos.com/) Linux distributions.

#### Clear Linux

- platform: clearlinux
- platform_family: clearlinux

#### ClearOS

- platform: clearos
- platform_family: rhel

## New Deprecations

### Removal of IpScopes plugin. (OHAI-13)

<https://docs.chef.io/deprecations_ohai_ipscopes.html>

In Chef/Ohai 14 (April 2018) we will remove the IpScopes plugin. The data returned by this plugin is nearly identical to information already returned by individual network plugins and this plugin required the installation of an additional gem into the Chef installation. We believe that few users were installing the gem and users would be better served by the data returned from the network plugins.
