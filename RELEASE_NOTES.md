<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# Ohai Release Notes:

## Haskell Language plugin

Haskell is now detected in a new haskell language plugin:

```javascript
"languages": {
  "haskell": {
    "stack": {
      "version": "1.2.0",
      "description": "Version 1.2.0 x86_64 hpack-0.14.0"
    }
  }
}
```

## LSB Release Detection

The lsb_release command line tool is now preferred to the contents of /etc/lsb-release. This resolves an issue where a distro can be upgraded, but /etc/lsb-release is not upgraded to reflect the change
