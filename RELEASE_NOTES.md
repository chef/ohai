<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# Ohai Release Notes:

## Gentoo platform version

Platform version on Gentoo hosts was previously detected as the Gentoo base system release version, which is actually the bootstrap image version. This hasn't changed in many years and is not an accurate way to determine the version of a Gentoo system. Instead Gentoo platform_version will now be the version of the kernel, matching the behavior we already use on Arch Linux.
