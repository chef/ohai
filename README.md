# ohai

# DESCRIPTION:

Ohai detects data about your operating system. It can be used
standalone, but its primary purpose is to provide node data to Chef.

Ohai will print out a JSON data blob for all the known data about your
system. When used with Chef, that data is reported back via node
attributes.

Chef distributes ohai as a RubyGem. This README is for developers who
want to modify the Ohai source code. For users who want to write plugins
for Ohai, see the docs:

* General documentation: http://docs.opscode.com/ohai.html
* Custom plugin documentation: http://docs.opscode.com/ohai_custom.html

# DEVELOPMENT:

Before working on the code, if you plan to contribute your changes, you
should read the contributing guidelines:

* https://github.com/opscode/ohai/blob/master/CONTRIBUTING.md

The basic process for contributing is:

1. Fork this repo on GitHub.
2. Create a feature branch for your work.
3. Make your change, including tests.
4. Submit a pull request.

# ENVIRONMENT:

Ohai's development dependencies should be installed with bundler. Just
run `bundle install` in the root of the repo.

## Spec Testing:

We use RSpec for unit/spec tests. To run the full suite, run:

    bundle exec rake spec

You can run individual test files by running the rspec executable:

    bundle exec rspec spec/unit/FILE.rb

## Rake Tasks

Ohai has some Rake tasks for doing various things.

    rake -T
    rake clobber_package  # Remove package products
    rake gem              # Build the gem file ohai-$VERSION.gem
    rake install          # install the gem locally
    rake make_spec        # create a gemspec file
    rake package          # Build all the packages
    rake repackage        # Force a rebuild of the package files
    rake spec             # Run specs
  
    ($VERSION is the current version, from the GemSpec in Rakefile)

# LINKS:

Source:

* http://github.com/opscode/ohai/tree/master

Issues:

* https://github.com/opscode/ohai/issues

# LICENSE:

Ohai - system information application

* Author:: Adam Jacob (<adam@getchef.com>)
* Copyright:: Copyright (c) 2008-2014 Chef Software, Inc.
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
