#
# Author:: Serdar Sutay (<serdar@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'ffi_yajl'

module Ohai
  module Hints
    def self.refresh_hints
      @hints = Hash.new
    end

    def self.hint?(name)
      @hints ||= Hash.new
      return @hints[name] if @hints[name]

      Ohai.config[:hints_path].each do |path|
        filename = File.join(path, "#{name}.json")
        if File.exist?(filename)
          begin
            json_parser = FFI_Yajl::Parser.new
            hash = json_parser.parse(File.read(filename))
            @hints[name] = hash || Hash.new # hint
            # should exist because the file did, even if it didn't
            # contain anything
          rescue FFI_Yajl::ParseError => e
            Ohai::Log.error("Could not parse hint file at #{filename}: #{e.message}")
          end
        end
      end

      @hints[name]
    end
  end
end
