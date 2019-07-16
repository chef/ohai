# ohai

[![Build status](https://badge.buildkite.com/aa0b961fc3e5bed315c7035c6d60a4aaee57af9610cbde9a15.svg?branch=master)](https://buildkite.com/chef-oss/chef-ohai-master-verify) [![Gem Version](https://badge.fury.io/rb/ohai.svg)](https://badge.fury.io/rb/ohai)

**Umbrella Project**: [Chef Infra](https://github.com/chef/chef-oss-practices/blob/master/projects/chef-infra.md)

**Project State**: [Active](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md#active)

**Issues Response SLA**: 10 business days

**Pull Request Response SLA**: 10 business days

## Description

Ohai detects data about your operating system. It can be used standalone, but its primary purpose is to provide node data to Chef.

Ohai will print out a JSON data blob for all the known data about your system. When used with Chef, that data is reported back via node attributes.

Chef distributes ohai as a RubyGem. This README is for developers who want to modify the Ohai source code. For users who want to write plugins for Ohai, see the docs:

- General documentation: <https://docs.chef.io/ohai.html>
- Writing Ohai Plugins documentation: <https://docs.chef.io/ohai_custom.html>

## Development Environment:

Ohai's development dependencies should be installed with bundler. Just run `bundle install` in the root of the repo.

## Spec Testing:

We use RSpec for unit/spec tests. To run the full suite, run:

```
bundle exec rake spec
```

You can run individual test files by running the rspec executable:

```
bundle exec rspec spec/unit/FILE.rb
```

## Style:

We use [Chefstyle](https://github.com/chef/chefstyle), as a code [linter](https://en.wikipedia.org/wiki/Lint_(software)), to enforce style guidelines. To run:

```
bundle exec rake style
```

You can run and automatically correct the issues:

```
bundle exec rake style:auto_correct
```

## Rake Tasks

Ohai has some Rake tasks for doing various things.

```
bundle exec rake -T
rake build               # Build ohai-$VERSION.gem into the pkg directory
rake clean               # Remove any temporary products
rake clobber             # Remove any generated files
rake docs                # Generate YARD Documentation
rake install             # Build and install ohai-$VERSION.gem into system gems
rake install:local       # Build and install ohai-$VERSION.gem into system gems without network access
rake release[remote]     # Create tag $VERSION and build and push ohai-$VERSION.gem to rubygems.org
rake spec                # Run RSpec code examples
rake style               # Run Chefstyle tests
rake style:auto_correct  # Auto-correct RuboCop offenses

($VERSION is the current version, from the GemSpec in Rakefile)
```

## Links:

Source:

- <https://github.com/chef/ohai/tree/master>

Issues:

- <https://github.com/chef/ohai/issues>

## Contributing

For information on contributing to this project see <https://github.com/chef/chef/blob/master/CONTRIBUTING.md>

1. Fork it
1. Create your feature branch (git checkout -b my-new-feature)
1. Commit your changes (git commit -am 'Add some feature')
1. Run the tests `bundle exec rake spec`
1. Run the style tests `bundle exec rake style`
1. Push to the branch (git push origin my-new-feature)
1. Create new Pull Request

## License

Ohai - system information application

- Author:: Adam Jacob ([adam@chef.io](mailto:adam@chef.io))
- Copyright:: Copyright (c) 2008-2019 Chef Software, Inc.
- License:: Apache License, Version 2.0

```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
