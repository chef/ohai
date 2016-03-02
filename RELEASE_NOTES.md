<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# Ohai Release Notes:

## Microsoft Azure
- Hosts running on Microsoft Azure will now be better detected as Azure hosts when they don't have a cloud hint file. The presence of the waagent on Windows and Linux or the presence of DHCP option 245 on Linux will mark a host as running in Azure.

## Amazon EC2
- Linux hosts that include the ec2metadata command line tool will now be detected as running in EC2
- EC2 nodes will now be able to use EC2 metadata versions 2014-11-05 and 2014-02-25 if available for increased instance information

## OS X
- The plist gem is now a required gem for Ohai, which allows the system_profile data to be collected without the need to install the gem manually

## run_command Deprecation
- The run_command method in the Command mixin has been deprecated, and will be removed from Ohai 9.0.0. Shelling out should be accomplished using the shell_out method in that same mixin.
