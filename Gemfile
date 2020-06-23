source "https://rubygems.org"

gemspec

group :development do
  gem "chefstyle", "~> 1.0"
  gem "rake", ">= 10.1.0"
  gem "rspec-core", "~> 3.0"
  gem "rspec-expectations", "~> 3.0"
  gem "rspec-mocks", "~> 3.0"
  gem "rspec-collection_matchers", "~> 1.0"
  gem "ipaddr_extensions"
end

group :ci do
  gem "rspec_junit_formatter"
end

group :docs do
  gem "yard"
  gem "redcarpet"
  gem "github-markup"
end

group :debug do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer", "~> 0.4.0" # pin until we drop ruby < 2.6
  gem "rb-readline"
end
