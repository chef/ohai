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
