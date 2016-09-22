<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

# Ohai Doc Changes:

## Shard Seed Plugin

The new `shard_seed` attribute provides a uniformly distributed integer ID value
to all nodes. This value will be between 0 and 4294967295 (0xFFFFFFFF), based
on a consistent hash of one or more pieces of node data. A consistent hash
means that a node with the same source inputs will always result in the same
shard seed, but collisions are possible.

The sources used to compute the seed value can be configured either in your
Chef config file or your Ohai config file ([ed: does anyone use Ohai config files?]):

```ruby
Ohai::Config[:plugins][:shard_seed][:sources] = [:fqdn]
```

The default sources are `[:machinename, :serial, :uuid]` but this value should
be considered experimental for the moment as it may be expanded to support
additional platforms. Configuring a value that works for your infrastructure is
highly recommended.

### Shard Seed Sources

There are multiple sources of data that can be used as inputs to the hash:

* `:machinename` – Everything before the first `.` in the machine's hostname.
* `:fqdn` – The machine's fully-qualified name. Depending on your platform and
  configuration, it is possible that this value could be unstable during DNS
  failures or other network outages.
* `:hostname` – The machine's raw hostname. As with `:fqdn`, this may be unstable
  during DNS failures or network outages.
* `:serial` – The machine's serial number as reported by DMI, SystemProfiler, or
  WMI.
* `:uuid` – The machine's UUID as reported by DMI, SystemProfiler, or WMI.
* `:machine_id` – The systemd machine ID. Only available on platforms using
  systemd.

You can configure either one source or an array of sources which will be
concatenated together.

### Using the Shard Seed

Two main use cases for the seed value are slow rollouts of new features and
computing service IDs.

To do slow rollouts, you can wrap new features or options in your recipe code
with a conditional `if` statement like:

```ruby
# Enable feature for 20% of nodes.
if (node['shard_seed'] % 100) < 20
  # Code goes here ...
end
```

For creating a service ID for something like ZooKeeper or MySQL replication:

```ruby
# Write the ID to a file for safety, in case something changes.
file '/etc/zookeeper/myid' do
  action :create_if_missing
  # ZooKeeper ID is 1-255.
  content "#{(node['shard_seed'] % 255) + 1}"
end
```

