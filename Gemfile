# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# pull these gems from main of chef/chef so that we"re testing against what we will release
gem "appbundler"
gem "chef-config", git: "https://github.com/chef/chef", branch: "main", glob: "chef-config/chef-config.gemspec"
gem "chef-utils", git: "https://github.com/chef/chef", branch: "main", glob: "chef-utils/chef-utils.gemspec"
gem "ffi", "~> 1.17", force_ruby_platform: true
# NOTE: do not submit PRs to add pry as a dep, add to your Gemfile.local
group :development do
  gem "ipaddr_extensions"
  gem "rake", ">= 10.1.0"
  gem "rspec-collection_matchers", "~> 1.0"
  gem "rspec-core", "~> 3.0"
  gem "rspec-expectations", "~> 3.0"
  gem "rspec-mocks", "~> 3.0"
end

# cookstyle (and its rubocop dependency) is only needed for `rake style` and
# is intentionally kept out of :development so `bundle install --without lint`
# (used by the unit test CI job) doesn't need to resolve it. This avoids a
# transitive unicode-display_width version conflict between rubocop and
# other gems (e.g. via chef-licensing/inspec-core) that can occur on some
# platforms/gem index states.
group :lint do
  gem "cookstyle", ">= 7.32.8"
end

group :debug do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
  gem "rb-readline"
end
