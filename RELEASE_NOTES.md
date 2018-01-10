<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# Unreleased

### LsPci Plugin

The new LsPci plugin provides a `node[:pci]` hash with information about the PCI bus based on `lspci`. Only runs on Linux.

# Ohai Release Notes:

## Upcoming Chef/Ohai 13 release

This April we'll be releasing Chef 13, and with the Chef 13 release we'll also be bumping the Ohai version to 13 to match. This release of Ohai will be the last 8.X release before we begin merging changes for Ohai 13.


## Cumulus Linux Platform

Cumulus Linux will now be detected as platform `cumulus` instead of `debian` and the `platform_version` will be properly set to the Cumulus Linux release.

## Virtualization Detection

Windows / Linux / BSD guests running on the Veertu hypervisors will now be detected

Windows guests running on Xen and Hyper-V hypervisors will now be detected

## New Sysconf Plugin

A new plugin parses the output of the sysconf command to provide information on the underlying system.

## AWS Account ID

The EC2 plugin now fetches the AWS Account ID in addition to previous instance metadata

## GCC Detection

GCC detection has been improved to collect additional information, and to not prompt for the installation of Xcode on macOS systems
