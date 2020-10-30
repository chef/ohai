# frozen_string_literal: true
#
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

require_relative "../config"
require "singleton" unless defined?(Singleton)

module Ohai
  module Mixin
    # Common Dependency Injection wiring for ChefUtils-related modules
    module ChefUtilsWiring
      private

      def __config
        Ohai::Config
      end

      def __log
        logger
      end

      def __transport_connection
        transport_connection
      end

      # because of target mode we cache the PATH to avoid massive amounts of `echo $PATH` remote queries
      #
      def __env_path
        PathCache.instance.path_cache ||= super
      end

      class PathCache
        include Singleton
        attr_accessor :path_cache
      end
    end
  end
end
