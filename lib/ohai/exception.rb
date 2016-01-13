#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
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
  module Exceptions
    class Exec < RuntimeError; end
    class Error < StandardError; end
    class InvalidPlugin < Error; end
    class InvalidPluginName < Error; end
    class IllegalPluginDefinition < Error; end
    class AttributeNotFound < Error; end
    class ProviderNotFound < Error; end
    class DependencyCycle < Error; end
    class DependencyNotFound < Error; end
    class AttributeSyntaxError < Error; end
    class PluginConfigError < Error; end
  end
end
