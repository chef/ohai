<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# Ohai Release Notes:

## Amazon EC2

- Windows instances running Amazon created AMIs will now be automatically detected as running in AWS
- Linux AWS detect has been improved and false detection of systems running in other clouds have been resolved.

## Packages Plugin

The packages plugin no longer requires Ohai configuration to enable the plugin. Any existing configuration will be ignored and can be removed.

## Shell Out Timeout

Plugins that shellout via the shell_out helper will now timeout after 30 seconds to prevent hung runs. The helper also includes the ability to change this time if necessary in your own plugins.
