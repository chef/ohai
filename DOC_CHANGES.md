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

## Configure plugins with ohai.plugin
Add the `ohai.plugin` setting to [Ohai Settings](https://docs.chef.io/config_rb_client.html#ohai-settings):

> Some plugins support configuration. Configure a plugin using the snake-case
name of the plugin consuming the setting. The snake-case name and any
configuration options are required to be Symbols.

> Currently, the only way to detect whether or not a plugin supports
configuration is to read the source. Ohai plugins which ship with Chef live in
the plugin directory on [GitHub](https://github.com/chef/ohai/tree/master/lib/ohai).

> Plugins access configuration options using the `configuration` DSL method.
Each Symbol passed to `configuration` represents a level in that plugin's
configuration Hash. If the `:Foo` plugin accesses `configuration(:bar)` you could add
`ohai.plugin[:foo][:bar] = config_value` to your configuration file. If the `:Foo2`
plugin accesses `configuration(:bar, :baz)`, you could configure it with `ohai.plugin[:foo_2][:bar] = { :baz => config_value }`.

Add a snippet on plugin configuration to [Custom Plugins](https://docs.chef.io/ohai.html#custom-plugins):

> ```ruby
Ohai.plugin(:Name) do
  # ...
  collect_data do
    if configuration(option, *options)
      # ...
    end
    if configuration(option, *options) == value
      # ...
    end
  end
end
```
* `configuration(option, *options)` accesses this plugin's configuration settings.

Add a subsection on plugin configuration to [Ohai DSL Methods](https://docs.chef.io/ohai.html#dsl-ohai-methods):

> Access plugin configuration settings within a `collect_data` block using the
`configuration` method. `configuration` takes one or more Symbols as the option
or path to the option accessed.
>
> Examples:
> * In the `collect_data` block of `:FooPlugin`, `configuration(:option)` accesses
`Ohai.config[:plugin][:foo_plugin][:option]`, which can be set by `ohai.plugin[:foo_plugin][:option] = value` in a user's configuration file.
> * In the `collect_data` block of `:FooPlugin`, `configuration(:option, :suboption)`
accesses `Ohai.config[:plugin][:foo_plugin][:option][:suboption]`, which can be
set by `ohai.plugin[:foo_plugin][:option] = { :suboption => value }` in a user's
configuration file.
