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
