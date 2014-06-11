#!/usr/bin/env bash

export PATH=$PATH:/usr/local/bin

ruby -v;
# remove the Gemfile.lock and try again if bundler fails.
# This should take care of Gemfile changes that result in "bad" bundles without forcing us to rebundle every time
bundle install --binstubs --without docgen --path vendor/bundle || ( rm Gemfile.lock && bundle install --path vendor/bundle )
# preserve the environment and $PATH of the `jenkins` user
sudo -E bash -c "export PATH=$PATH && bin/rspec -r rspec_junit_formatter -f RspecJunitFormatter -o test.xml -f documentation spec"
# Ensure Jenkins can clean this file up
sudo chown ${USER-`whoami`} test.xml

RSPEC_RETURNCODE=$?

# exit with the result of running rspec
exit $RSPEC_RETURNCODE
