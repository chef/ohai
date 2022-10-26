# frozen_string_literal: true
source "https://rubygems.org"

gemspec

# pull these gems from chef-17 of chef/chef so that we're testing against what we will release
gem "chef-config", git: "https://github.com/chef/chef", branch: "chef-17", glob: "chef-config/chef-config.gemspec"
gem "chef-utils", git: "https://github.com/chef/chef", branch: "chef-17", glob: "chef-utils/chef-utils.gemspec"

# NOTE: do not submit PRs to add pry as a dep, add to your Gemfile.local
group :development do
  gem "chefstyle", "2.1.3"
  gem "ipaddr_extensions"
  gem "rake", ">= 10.1.0"
  gem "rspec-collection_matchers", "~> 1.0"
  gem "rspec-core", "~> 3.0"
  gem "rspec-expectations", "~> 3.0"
  gem "rspec-mocks", "~> 3.0"
  gem "rubocop-performance", "1.12.0"
  gem "rubocop-rspec"
end

group :debug do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
  gem "rb-readline"
end
