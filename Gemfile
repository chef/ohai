# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# pull these gems from main of chef/chef so that we"re testing against what we will release
gem "appbundler"
gem "chef-config", git: "https://github.com/chef/chef", branch: "main", glob: "chef-config/chef-config.gemspec"
gem "chef-utils", git: "https://github.com/chef/chef", branch: "main", glob: "chef-utils/chef-utils.gemspec"
# NOTE: do not submit PRs to add pry as a dep, add to your Gemfile.local
group :development do
  install_if -> { Gem::Version.new(">= 3.4.0").to_s >= (RUBY_VERSION).to_s } do
    gem "racc", "~> 1.8.0"
    gem "base64"
  end
  install_if -> { Gem::Version.new(">= 3.3.0").to_s >= (RUBY_VERSION).to_s } do
    gem "racc", "~> 1.8.0"
  end
  gem "cookstyle", ">= 7.32.8"
  gem "ipaddr_extensions"
  gem "rake", ">= 10.1.0"
  gem "rspec-collection_matchers", "~> 1.0"
  gem "rspec-core", "~> 3.0"
  gem "rspec-expectations", "~> 3.0"
  gem "rspec-mocks", "~> 3.0"
  gem "rubocop-performance", "1.18.0"
  gem "rubocop-rspec"
end

group :debug do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
  gem "rb-readline"
end
