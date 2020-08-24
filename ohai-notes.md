# TODO

- [PR OPENED]: train: DragonflyBSD detection (`/dragonfly/`)
  https://github.com/inspec/train/blob/cc4b3b9ba38f826d4e91d9de1e3e945be6ef8a7d/lib/train/platforms/detect/specifications/os.rb#L514-L543
  https://github.com/chef/ohai/blob/master/lib/ohai/plugins/os.rb#L32-L38

- [PR OPENED]: Slow remote execution due to create/teardown of SSH transport connection in train
  - https://github.com/inspec/train/blob/6cdb9f874cef373c22524758e6fb3fed3a2f6c25/lib/train/transports/ssh.rb#L233-L240
  - https://github.com/inspec/train/blob/6cdb9f874cef373c22524758e6fb3fed3a2f6c25/lib/train/transports/ssh.rb#L79-L84

- train: Windows file stat missing
  https://github.com/inspec/train/blob/cc4b3b9ba38f826d4e91d9de1e3e945be6ef8a7d/lib/train/extras/stat.rb#L30-L33

- Almost no impact on local runs:
  Ohai 16.1.1: `1,43s user 0,84s system 73% cpu 3,074 total`
  Ohai 16.1.1000: `1,98s user 0,86s system 77% cpu 3,653 total`

- Fix Spec tests and write additional ones, when Chef commits
- `include_dsl :line_buffered` to include mode specific Mixins

## Changes: `collect_os`

Removed this:

```ruby
when /aix(.+)$/       # same in train: os.rb:249
  "aix"
when /darwin(.+)$/    # same in train: os.rb:343
  "darwin"
when /linux/          # same in train: os.rb:47
  "linux"
when /freebsd(.+)$/   # same in train: os.rb:369
  "freebsd"
when /openbsd(.+)$/   # same in train: os.rb:370
  "openbsd"
when /netbsd(.*)$/    # same in train: os.rb:371
  "netbsd"
when /dragonfly(.*)$/ # in Train 3.3.2 :D
  "dragonflybsd"
when /solaris2/       # fail: "solaris"
  "solaris2"
when /mswin|mingw32|windows/# same in train: os.rb:17
  "windows"
```

- dragonflybsd is not detected. RBconfig reports "dragonfly5" though
  - created compatibility case, which can be removed after train PR #614

## Changes `shell_out`

- `shell_out` options are only used on filesystem.rb for timeout, train doesn't have it
- properties used:
  - `exitstatus`
  - `stdout`
  - `stderr`
- Ohai Plugin refactoring to access `.exit_status` and remove facade

## Bugs

```text
[2020-06-17T15:18:31+00:00] TRACE: Plugin Docker threw #<NoMethodError: undefined method `[]' for nil:NilClass>
[2020-06-17T15:18:31+00:00] TRACE: /home/ubuntu/.chefdk/gem/ruby/2.7.0/gems/ohai-16.1.1000/lib/ohai/plugins/docker.rb:35:in `docker_ohai_data'
[2020-06-17T15:18:31+00:00] TRACE: /home/ubuntu/.chefdk/gem/ruby/2.7.0/gems/ohai-16.1.1000/lib/ohai/plugins/docker.rb:54:in `block (2 levels) in <main>'
```

```text
[2020-06-17T15:18:12+00:00] ERROR: shard_seed: Failed to get dmi property serial_number: is dmidecode installed?
[2020-06-17T15:18:12+00:00] TRACE: Plugin ShardSeed threw #<RuntimeError: Failed to generate shard_seed>
[2020-06-17T15:18:12+00:00] TRACE: /home/ubuntu/.chefdk/gem/ruby/2.7.0/gems/ohai-16.1.1000/lib/ohai/plugins/shard.rb:30:in `get_dmi_property'
[2020-06-17T15:18:12+00:00] TRACE: /home/ubuntu/.chefdk/gem/ruby/2.7.0/gems/ohai-16.1.1000/lib/ohai/plugins/shard.rb:133:in `block (3 levels) in <main>'
```
