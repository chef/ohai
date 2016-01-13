#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright (c) 2014-2016 Chef Software, Inc.
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

module Ohai
  module Mixin
    module ConstantHelper

      def remove_constants
        new_object_constants = Object.constants - @object_pristine.constants
        new_object_constants.each do |constant|
          Object.send(:remove_const, constant) unless Object.const_get(constant).is_a?(Module)
        end

        recursive_remove_constants(Ohai::NamedPlugin)
      end

      def recursive_remove_constants(object)
        if object.respond_to?(:constants)
          object.constants.each do |const|
            next unless strict_const_defined?(object, const)
            recursive_remove_constants(object.const_get(const))
            object.send(:remove_const, const)
          end
        end
      end

      def strict_const_defined?(object, const)
        if object.method(:const_defined?).arity == 1
          object.const_defined?(const)
        else
          object.const_defined?(const, false)
        end
      end

    end
  end
end
