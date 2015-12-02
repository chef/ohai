<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# Ohai Release Notes:
## Virtualization
With this release we greatly improved detection of virtualization guests:
- We now detect Linux/BSD guests running on the RedHat Enterprise Virtualization (RHEV) platform, Microsoft Hyper-V, and additional versions of Microsoft VirtualPC.
- BSD systems gained detection of guests running on VirtualBox, KVM, and Openstack.
- Windows systems gained detection of guests running on Virtualbox, VMware, and KVM.
- BSD now includes the nested virtualization support, which was added to other platforms in the 7.2.0 release.
- A new plugin was added for VirtualBox to expose information on the version of the guest additions package, as well as the version of the VirtualBox host.

## BSD
Initial support for Support for DragonFly BSD was added.

BSD also saw several improvements to better align collected data with that of Linux systems:
- The filesystem plugin now collects inode data for each filesystem
- CPU detection has been fixed on FreeBSD 10.2 and later systems. We're also collecting CPU model and family data to match CPU data on Linux systems.
- The code to parse dmidecode data to detect virtualization guests is now shared between BSD and Linux systems for consistent detection of virtualization guests.

## Miscellaneous
- Collected zfs filesystem properties are now configurable on solaris2.
- The path to the Ohai plugins directory is now escaped to prevent failures on Windows systems if the path included spaces.
- The AIX CPU plugin now detects the bitness of the system.
- Ohai now longer fails under certain circumstances when determining network listeners

# Ohai Breaking Changes:
- Linux guests running on Hyper-V were previously detected as running on VirtualPC, but are now correctly detected as Hyper-V guests.
- Core and CPU counts on Windows were based on the first CPU only. Counts will now take into account all physical CPUs.
