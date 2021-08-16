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

module Ohai
  module Mixin
    module SecondsToHuman
      # given the number of seconds return a day/hours/minutes/seconds human form
      #
      # @param seconds [Integer]
      #
      # @return String
      def seconds_to_human(seconds)
        days = seconds.to_i / 86400
        seconds -= 86400 * days

        hours = seconds.to_i / 3600
        seconds -= 3600 * hours

        minutes = seconds.to_i / 60
        seconds -= 60 * minutes

        if days > 1
          sprintf("%d days %02d hours %02d minutes %02d seconds", days, hours, minutes, seconds)
        elsif days == 1
          sprintf("%d day %02d hours %02d minutes %02d seconds", days, hours, minutes, seconds)
        elsif hours > 0
          sprintf("%d hours %02d minutes %02d seconds", hours, minutes, seconds)
        elsif minutes > 0
          sprintf("%d minutes %02d seconds", minutes, seconds)
        else
          sprintf("%02d seconds", seconds)
        end
      end
    end
  end
end
