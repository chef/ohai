<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

# Ohai Doc Changes:

## Ohai::Config[:configurable] is deprecated, use Ohai::Config.ohai
`Ohai::Config` is deprecated in favor of `Ohai::Config.ohai`. Configuring ohai
using `Ohai::Config` is deprecated and will be removed in future releases of
ohai.

The [Ohai Settings](https://docs.chef.io/config_rb_client.html#ohai-settings)
subsection of the `client.rb` documentation should be updated to use
`ohai.option` instead of `Ohai::Config[:option]`.

If there is any mention of the ability to access configuration options via
`Ohai::Config`, it should be updated to `Ohai::Config.ohai`. Additionally, it
should be mentioned that `Ohai.config` is an alias for `Ohai::Config.ohai`.

## Load a configuration file while running ohai as an application
You can specify a configuration file for ohai to load while running as an
application. For example, if your configuration file is located at
`~/.chef/config.rb` you can run ohai with that configuration file with
`ohai -c ~/.chef/config.rb`.

When running ohai as an application and no configuration file is specified
as a command line parameter, ohai will load a configuration file from your
workstation (`config.rb` or `knife.rb`) if one is found.

## The filesystem2 plugin
The filesystem2 plugin is intended to eventually replace the filesystem
plugin on Linux and OS X.
* It provides 3 views:
** `by_pair` is the primary one and what most users are expected to use. It
   gaurantees no loss of data from conflict and has an entry in the hash for
   each pair of $device,$mountpoint (or "$device," for unmounted devices).
** `by_device` a similar layout to the original filesystem plugin which is
   indexed by device, except that 'mount' entry is now 'mounts' and is an array.
   While this solves many of the problems users can encounter by having
   /etc/mtab be a symlink to /proc/mounts it can still have data loss due to
   different mount options, or multiple virtualfs mounts with the same fake
   device name.
** `by_mount` similar to the above but indexed by mountpoint. Won't include
   unmounted filesystems, of course.
