<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# Ohai Release Notes:

## Openstack

- Openstack metadata will now be properly polled if either a hint file or Openstack DMI data is present. This data will be used to populate IP information in the cloud and cloudv2 plugins

## bhyve

- Nodes running as bhyve guests will now be identified in the virtualization plugin

## PLD Linux

- Package information will now be gathered in PLD Linux
