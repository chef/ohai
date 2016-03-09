<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# Ohai Release Notes:

## Microsoft Azure

- Hosts running on Microsoft Azure will now be better detected as Azure hosts when they don't have a cloud hint file. The presence of the waagent on Windows and Linux or the presence of DHCP option 245 on Linux will mark a host as running in Azure.

## Amazon EC2

- Linux hosts that include the ec2metadata command line tool will now be detected as running in EC2
- EC2 nodes will now be able to use EC2 metadata versions 2014-11-05 and 2014-02-25 if available for increased instance information

## Virtualization Improvements:

- Openstack hosts are now detected if Nova is installed
- KVM detection has been improved to better detect Linux guests running on KVM, and to properly detect KVM hosts
- Solaris guests running on various hypervisors are now detected, and the node['virutalization']['systems'] attribute is now set as we do on other platforms
- bhyve hosts and guests on FreeBSD are now detected
- FreeBSD guests on VMware, Xen, and Hyper-V are now detected even if dmidecode isn't installed
- Virsh detection no longer requires the hpricot gem to be installed, and no longer returns XML data

## OS X

- The plist gem is now a required gem for Ohai, which allows the system_profile data to be collected without the need to install the gem manually

## run_command Deprecation

- The run_command method in the Command mixin has been deprecated, and will be removed from Ohai 9.0.0. Shelling out should be accomplished using the shell_out method in that same mixin.

## New Sessions Plugin

- A new plugin Sessions plugin has been added for Linux hosts to collect systemd sessions information using loginctl
