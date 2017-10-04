# Unreleased

### Critical Plugins

Users can now specify a list of plugins which are `critical`. Critical plugins will cause Ohai to fail if they do not run successfully (and thus cause a Chef run using Ohai to fail). The syntax for this is:

```
ohai.critical_plugins << :Filesystem
```

# Ohai Release Notes 13.5

### Correctly detect IPv6 routes ending in ::

Previously we would ignore routes that ended `::`, and now we properly
detect them.

### Plugin run time is now measured

Debug logs will show the length of time each plugin takes to run, making
debugging of long ohai runs easier.

# Ohai Release Notes 13.4

### Windows EC2 Detection

Detection of nodes running in EC2 has been greatly improved and should now detect nodes 100% of the time including nodes that have been migrated to EC2 or were built with custom AMIs.

### Azure Metadata Endpoint Detection

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

### Package Plugin Supports Arch Linux

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
