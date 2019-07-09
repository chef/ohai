#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "ffi_yajl" unless defined?(FFI_Yajl)

module Ohai
  # Ohai hints are json files on disk that give ohai a hint to things that are often
  # difficult to discover like certain clouds. Previously they were used for just about
  # every cloud, but we've since discoverd better ways to auto-detect these clouds.
  # They are generally dropped off by the knife plugins for those clouds during bootstrap,
  # but may also be manually dropped off and consumed by 3rd party plugins.
  module Hints
    # clear out any known hints in the @hints variable
    def self.refresh_hints
      @hints = {}
    end

    # parse the JSON contents of a hint file. Return an empty hash if the file has
    # no JSON content
    # @param filename [String] the hint file path
    def self.parse_hint_file(filename)
      json_parser = FFI_Yajl::Parser.new
      hash = json_parser.parse(File.read(filename))
      hash || {} # hint
      # should exist because the file did, even if it didn't
      # contain anything
    rescue FFI_Yajl::ParseError => e
      Ohai::Log.error("Could not parse hint file at #{filename}: #{e.message}")
    end

    # retrieve hint contents given a hint name. Looks up in @hints variable first. Attempts
    # to load from file in config's :hints_path if not already cached. Saves the contents
    # to the hash if the file was successfully parsed
    # @param name [String] the name of the hint (not the path)
    def self.hint?(name)
      @hints ||= {}
      return @hints[name] if @hints[name]

      Ohai.config[:hints_path].each do |path|
        filename = File.join(path, "#{name}.json")
        next unless File.exist?(filename)

        Ohai::Log.trace("Found hint #{name}.json at #{filename}")
        @hints[name] = parse_hint_file(filename)
      end

      Ohai::Log.trace("Did not find hint #{name}.json in the hint path(s): #{Ohai.config[:hints_path].join(", ")} ") unless @hints.key?(name)
      @hints[name]
    end
  end
end
