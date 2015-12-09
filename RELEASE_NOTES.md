<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# Ohai Release Notes:

This is a patch release with the following fixes:
* [pr#677](https://github.com/chef/ohai/pull/677) Removed dependency on mime-types gem. This could cause failures in some scenarios.
* [pr#662](https://github.com/chef/ohai/pull/662) Skip loading the VMWare plug-in when we don't need it (e.g. on non-VMWare systems)
