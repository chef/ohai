<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# Ohai Release Notes:

### Virtualization

Chained virtualization systems, such as containers running on virtual machines, can now be tracked in
node[:virtualization][:systems]. This is in addition to the former system under node[:virtualization][:role] and
node[:virtualization][:system]. For example, a node could have all of these attributes at once:

```
node[:virtualization][:system] = "vmware"
node[:virtualization][:role] = "guest"
node[:virtualization][:systems][:lxc] = "host"
node[:virtualization][:systems][:vmware] = "guest"
```

Due to the requirements for being an LXC host being easily fulfilled, we only
populate the old system (role & system) with LXC if there are no other virtualization systems detected.

### Miscellaneous

* Ohai now collects mdadm RAID information.
* Ohai know uses lsblk, if available, instead of blkid

# Ohai Breaking Changes:
