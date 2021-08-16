# frozen_string_literal: true
#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "mixlib/log" unless defined?(Mixlib::Log)

module Ohai
  # the Ohai Logger which is just Mixlib::Log defaulting to STDERR and :info level
  # unless otherwise configured via CLI or config
  class Log
    extend Mixlib::Log

    # this class loading initialization is so that we don't lose early logger
    # messages when run from the CLI?
    init(STDERR)
    level = :info # rubocop:disable Lint/UselessAssignment

  end
end
