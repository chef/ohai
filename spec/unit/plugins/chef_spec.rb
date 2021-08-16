#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tollef Fog Heen <tfheen@err.no>
# Copyright:: Copyright (c) Chef Software Inc.
# Copyright:: Copyright (c) 2010 Tollef Fog Heen <tfheen@err.no>
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

begin
  require "spec_helper"
  require "chef/version"
  require "chef-config/config" unless defined?(ChefConfig::Config)

  describe Ohai::System, "plugin chef" do
    before do
      @plugin = get_plugin("chef")
    end

    it "sets [:chef_packages][:chef][:version] to the current chef version", if: defined?(Chef) do
      @plugin.run
      expect(@plugin[:chef_packages][:chef][:version]).to eq(Chef::VERSION)
    end

    it "sets [:chef_packages][:chef][:chef_root] to the current chef root directory", if: defined?(Chef) do
      @plugin.run
      expect(@plugin[:chef_packages][:chef][:chef_root]).to eq(Chef::CHEF_ROOT)
    end

    it "does not create [:chef_packages][:chef][:chef_effortless] by default", if: defined?(Chef) do
      @plugin.run
      expect(@plugin[:chef_packages][:chef][:chef_effortless]).to eq(nil)
    end

    it "sets [:chef_packages][:chef][:chef_effortless] to TRUE if executed from Habitat via CHEF_ROOT using Chef zero", if: defined?(Chef) do
      stub_const("Chef::CHEF_ROOT", "/hab/pkgs/chef/chef-infra-client/X.X.X/XXXX/vendor/gems/chef-X.X.X/lib")
      stub_const("ChefConfig::Config", { "chef_server_url" => "chefzero://localhost:1" })
      @plugin.run
      expect(@plugin[:chef_packages][:chef][:chef_effortless]).to eq(true)
    end

    pending "would set [:chef_packages][:chef][:version] if chef was available", unless: defined?(Chef)
  end
rescue LoadError
  # the chef module is not available, ignoring.

  describe Ohai::System, "plugin chef" do
    pending "would set [:chef_packages][:chef][:version] if chef was available", unless: defined?(Chef)
  end
end
