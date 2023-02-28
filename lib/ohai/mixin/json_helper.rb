# frozen_string_literal: true
#
# Author:: Renato Covarrubias (<rnt@rnt.cl>)
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Ohai
  module Mixin
    module JsonHelper
      # parse JSON data from a String to a Hash
      #
      # @param [String] response_body json as string to parse
      # @param [Object] return_on_parse_error value to return if parsing fails
      #
      # @return [Hash]
      def parse_json(response_body, return_on_parse_error = nil)
        data = String(response_body)
        parser = FFI_Yajl::Parser.new
        parser.parse(data)
      rescue FFI_Yajl::ParseError
        return_on_parse_error
      end
    end
  end
end
