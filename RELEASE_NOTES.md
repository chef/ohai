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


### Filesystem2

There is a new plugin for filesystems in Linux & Darwin. It solves several
problems:
* Can handle multiple virtual FSes with the same "device" (eg, 'none')
* Can handle a device mounted multiple places
* Is resilient to mtab being a symlink to /proc/mounts
* Provides multiple views for ease of use
* Provides a mechanism that has gauranteed lack of overwritten data
* Forks far fewer times than it's predecessor

Unlike the 'filesystem' plugin, it provides 3 views into the data:

* `by_pair` is the primary one and what most users are expected to use. It
  gaurantees no loss of data from conflict and has an entry in the hash for each
  pair of $device,$mountpoint (or "$device," for unmounted devices).
* `by_device` a similar layout to the original filesystem plugin which is
  indexed by device, except that 'mount' entry is now 'mounts' and is an array.
  While this solves many of the problems users can encounter by having /etc/mtab
  be a symlink to /proc/mounts it can still have data loss due to different
  mount options, or multiple virtualfs mounts with the same fake device name.
* `by_mount` similar to the above but indexed by mountpoint. Won't include
  unmounted filesystems, of course. Instead of a 'device' entry it has a
  'devices' entry that is an array. Similar to the 'by_device' view, this extra
  feature can solve many problems of of the old filesystem plugin, but may still
  have data loss on things like mount options.

It is recommended to always use `by_pair` when iterating or wanting a full view
of storage devices. The other two are provided for convenient lookup. Other
notes:

* The `by_mount` view handles conflicts in a last-wins manner. Other than that,
  fields should be the same except for the lack of a "mount" key inside entries
  (since that's the key to the structure)
* The `by_device` mount changes the structure slightly to replace 'mount' key in
  each structure with 'mounts' - an array of mountpoints instead of overwriting
  values. For other conflicts last one wins. 'devices' is not a key inside
  entries since it's the key to the structure.

### Miscellaneous

* Ohai now collects mdadm RAID information.
* Ohai know uses lsblk, if available, instead of blkid
* linux::filesystem now reads all of /proc/mounts instead of just 4K
* linux::network now handles ECMP routes

# Ohai Breaking Changes:
