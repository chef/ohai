#
# Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
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

require "ohai/exception"

module Ohai
  class PluginConfig < Hash

    def []=(key, value_or_hash)
      enforce_symbol(key)
      enforce_symbol_keys(value_or_hash) if value_or_hash.is_a?(Hash)
      super(key, value_or_hash)
    end

    private

    def enforce_symbol(key)
      unless key.is_a?(Symbol)
        msg = "Expected Symbol, got #{key.inspect}"
        raise Ohai::Exceptions::PluginConfigError, msg
      end
    end

    def enforce_symbol_keys(hash)
      hash.each do |key, value|
        enforce_symbol(key)
        enforce_symbol_keys(value) if value.is_a?(Hash)
      end
    end

  end
end
