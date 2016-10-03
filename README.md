[![Build Status Master](https://travis-ci.org/chef/info_getter.svg?branch=master)](https://travis-ci.org/chef/info_getter)
[![Build Status Master](https://ci.appveyor.com/api/projects/status/github/chef/info_getter?branch=master&svg=true&passingText=master%20-%20Ok&pendingText=master%20-%20Pending&failingText=master%20-%20Failing)](https://ci.appveyor.com/project/Chef/info_getter/branch/master)
[![Gem Version](https://badge.fury.io/rb/info_getter.svg)](https://badge.fury.io/rb/info_getter)


# DESCRIPTION:

info_getter detects data about your operating system. It can be used
standalone, but its primary purpose is to provide node data to Chef.

info_getter will print out a JSON data blob for all the known data about your
system. When used with Chef, that data is reported back via node
attributes.

Chef distributes info_getter as a RubyGem. This README is for developers who
want to modify the info_getter source code. For users who want to write plugins
for info_getter, see the docs:

* General documentation: https://docs.chef.io/info_getter.html
* Custom plugin documentation: https://docs.chef.io/info_getter_custom.html

# DEVELOPMENT:

Before working on the code, if you plan to contribute your changes, you
should read the contributing guidelines:

* https://github.com/chef/info_getter/blob/master/CONTRIBUTING.md

The basic process for contributing is:

1. Fork this repo on GitHub.
2. Create a feature branch for your work.
3. Make your change, including tests.
4. Submit a pull request.

# ENVIRONMENT:

info_getter's development dependencies should be installed with bundler. Just
run `bundle install` in the root of the repo.

## Spec Testing:

We use RSpec for unit/spec tests. To run the full suite, run:

    bundle exec rake spec

You can run individual test files by running the rspec executable:

    bundle exec rspec spec/unit/FILE.rb

## Rake Tasks

info_getter has some Rake tasks for doing various things.

    rake -T
    rake build          # Build the gem file info_getter-$VERSION.gem
    rake install        # install the gem locally
    rake install:local  # install the gem locally without network access
    rake release        # Create tag $VERSION, build gem, and push to Rubygems
    rake spec           # Run RSpec tests

    ($VERSION is the current version, from the GemSpec in Rakefile)

# LINKS:

Source:

* https://github.com/chef/info_getter/tree/master

Issues:

* https://github.com/chef/info_getter/issues

# LICENSE:

info_getter - system information application

* Author:: Adam Jacob (<adam@chef.io>)
* Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
* License:: Apache License, Version 2.0

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
