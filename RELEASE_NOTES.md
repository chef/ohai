<!-- - This file is reset every time a new release is done. The contents of this file are for the currently unreleased version. Example Note: ## Example Heading Details about the thing that changed that needs to get included in the Release Notes in markdown. -->

# Ohai Release Notes 13.1:

## New Features

### Shellout now injects additional paths

The shell_out helper used by Ohai plugins to run system commands has been updated to inject commonly used paths when shelling out. This allows us to find system utilities even when the user's PATH variable lacks common locations such as /sbin.

### EC2 metadata improvements

The EC2 plugin and helpers have been updated to support the latest versions of Amazon's EC2 metadata endpoint, which includes new IPV6 data. Additionally, when available, we will reuse HTTP connections to reduce load on metadata servers and reduce the memory footprint of Ohai. This is particularly useful in the Openstack plugin which uses the EC2 helpers and connects to servers that support connection reuse.

### mdadm device data

The Mdadm plugin on Linux will now collect "members" data, which is an array of member devices within the array.

## New Deprecations

### Removal of support for Ohai version 6 plugins (OHAI-10)

<https://docs.chef.io/deprecations_ohai_filesystem.html>

In Chef/Ohai 14 (April 2018) we will remove support for loading Ohai v6 plugins, which we deprecated in Ohai 7/Chef 11.12.

### Cloud V2 attribute removal. (OHAI-11)

<https://docs.chef.io/deprecations_ohai_cloud_v2.html>

In Chef/Ohai 15 (April 2019) we will no longer write data to node['cloud_v2']. In Chef/Ohai 13 we deprecated the existing Cloud plugin and instead used CloudV2 to write to both node['cloud'] and node['cloud_v2']. Removing the existing "v2" namespace completes this plugin migration.

### Filesystem2 attribute removal. (OHAI-12)

<https://docs.chef.io/deprecations_ohai_filesystem_v2.html>

In Chef/Ohai 15 (April 2019) we will no longer write data to node['filesystem2']. In Chef/Ohai 13 we deprecated the existing Filesystem plugin and instead used Filesystem2 to write to both node['filesystem'] and node['filesystem2']. Removing the existing "v2" namespace completes this plugin migration.
