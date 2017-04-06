<!-- - This file is reset every time a new release is done. The contents of this file are for the currently unreleased version. Example Note: ## Example Heading Details about the thing that changed that needs to get included in the Release Notes in markdown. -->

# Ohai Release Notes 13.0:

## New Features

### New Secondary Plugin Path

By default Ohai will now look for additional plugins within `/etc/chef/ohai/plugins` or `C:\chef\ohai\plugins`. This makes it easy to drop off additional plugins during bootstrap or using the ohai cookbook without the need to edit client.rb or reload Ohai.

### Version Matching With Chef

Ohai has been bumped from version 8.23 to version 13.0 to match the chef-client. We'll be keeping versions in sync between ohai and chef-client so you always know what version of ohai shipped with chef-client.

### Lua and Scala Detection

Lua and Scala version detection has been improved to work in more situations

### AWS Metadata Detection

We now detect `availability_zone` and `region` information for EC2

### DMI Detection

We now detect DMI types 40-41: additional_information, onboard_devices_extended_information, and management_controller_host_interfaces.

## Back Compatibility Breaks

### Amazon is now platform_family of amazon

As time has gone on Amazon Linux has become less and less like other RHEL derivatives. We're now detecting amazon as its own platform_family to make writing Amazon Linux compatible cookbooks easier

### Cloud plugin replaced with Cloud V2

The legacy cloud plugin that provided node['cloud'] has been replaced with the Cloud V2 plugin. If you previously used data from the Cloud plugin you will see a new, more robust, data struct at node['cloud'].

### Filesystems plugin replaced with Filesystem V2

The legacy filesystem plugin that provided node['fileystem'] has been replaced with the Filesystem V2 plugin. If you previously used data from the Filesystem plugin you will see a new, more robust, data struct at node['filesystem'].

### Freezing Ohai Strings

All Ohai strings are now frozen to prevent modification within cookbooks and to save memory

### Removal of SBT Detection

The latest versions of sbt no longer include a sbt --version command and other methods of version detection require setting up a project in the working directory. Until a better version detection method can be determine we're removed sbt detection.

### Ruby 2.3+

Ohai now requires Ruby 2.3 instead of 2.1\. This change aligns the Ruby requirements of Ohai with that of chef-client

### Legacy Config Removal (Ohai-1)

The legacy Ohai config format used in the Chef client.rb config has been removed. See <https://docs.chef.io/deprecations_ohai_legacy_config.html> for details.

### Sigar gem based plugins removal (OHAI-2)

Sigar gem based plugins have been removed from Ohai. See <https://docs.chef.io/deprecations_ohai_sigar_plugins.html> for details.

### run_command and popen4 helper method removal (OHAI-3)

The legacy run_command and popen4 helper methods have been removed. See <https://docs.chef.io/deprecations_ohai_run_command_helpers.html> for details.

### Windows CPU plugin attribute changes. (OHAI-5)

The windows cpu model_name attribute has been updated to return the correct value. See <https://docs.chef.io/deprecations_ohai_windows_cpu.html> for details.

### DigitalOcean plugin attribute changes (OHAI-6)

The DigitalOcean plugin has been completely rewritten to pull data from the DigitalOcean metadata endpoint, giving us more detailed droplet information. This changed the format of the data returned by Ohai. See <https://docs.chef.io/deprecations_ohai_digitalocean.html> for details.
