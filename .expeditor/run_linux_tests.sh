#!/bin/bash
#
# This script runs a passed in command, but first setups up the bundler caching on the repo

set -ue

export USER="root"
export LANG=C.UTF-8 LANGUAGE=C.UTF-8

echo "--- bundle install"

# we need the ruby 2.7 version of bundler, the 2.5/2.6 versions cannot pull our Gemfile correctly
gem update --system
gem install bundler
bundle config --local path vendor/bundle
bundle install --jobs=7 --retry=3

echo "+++ bundle exec task"
bundle exec $@
